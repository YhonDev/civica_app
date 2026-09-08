import { Test, TestingModule } from '@nestjs/testing';
import { DataSource } from 'typeorm';
import { GenerarCobrosUseCase } from './generar-cobros.use-case';
import { CobroRepository } from '../../infrastructure/persistence/cobro.repository';
import { PlanDeCobroRepository } from '../../infrastructure/persistence/plan-de-cobro.repository';
import { PeriodoCobroRepository } from '../../infrastructure/persistence/periodo-cobro.repository';
import { TarifaRepository } from '../../infrastructure/persistence/tarifa.repository';
import { PlanDeCobro } from '../../domain/plan-de-cobro.entity';
import { PeriodoCobro } from '../../domain/periodo-cobro.entity';
import { Tarifa } from '../../domain/tarifa.entity';
import { Cobro } from '../../domain/cobro.entity';

describe('GenerarCobrosUseCase', () => {
  let useCase: GenerarCobrosUseCase;

  const mockCobroRepo = {
    saveMany: jest.fn(),
  };

  const mockPlanRepo = {
    findAllActivos: jest.fn(),
  };

  const mockPeriodoRepo = {
    findByPlanAndMonth: jest.fn(),
    save: jest.fn(),
  };

  const mockTarifaRepo = {
    findVigente: jest.fn(),
  };

  // Manager transaccional: delega en los mismos mocks del use-case.
  const mockManager = {
    query: jest.fn().mockResolvedValue([]), // advisory lock (no-op)
    findOne: jest.fn().mockImplementation(async (_entity: any, options: any) => {
      const where = options?.where ?? {};
      return mockPeriodoRepo.findByPlanAndMonth(
        where.planId,
        where.mes,
        where.anio,
      );
    }),
    save: jest.fn().mockImplementation(async (target: any, entity?: any) => {
      const value = entity ?? target;
      if (Array.isArray(value)) return mockCobroRepo.saveMany(value);
      if (value instanceof PeriodoCobro) return mockPeriodoRepo.save(value);
      return value;
    }),
  };

  const mockDataSource = {
    transaction: jest.fn(async (cb: (em: typeof mockManager) => Promise<any>) =>
      cb(mockManager),
    ),
  };

  const TENANT_ID = 'tenant-1';
  const PROYECTO_ID = 'proyecto-1';
  const RESIDENTE_ID = 'residente-1';
  const CASA_ID = 'casa-1';
  const PLAN_ID = 'plan-1';

  function crearPlan(overrides: Partial<PlanDeCobro> = {}): PlanDeCobro {
    const plan = PlanDeCobro.crear(
      CASA_ID,
      RESIDENTE_ID,
      TENANT_ID,
      PROYECTO_ID,
      'MENSUAL',
      '2026-01-01',
    );
    Object.assign(plan, { id: PLAN_ID, ...overrides });
    return plan;
  }

  const hoyStr = `${new Date().getFullYear()}-${String(new Date().getMonth() + 1).padStart(2, '0')}-01`;

  /** Helper to create a Tarifa */
  function crearTarifa(overrides: Partial<Tarifa> = {}): Tarifa {
    const tarifa = new Tarifa();
    Object.assign(tarifa, {
      id: 'tarifa-1',
      tenantId: TENANT_ID,
      proyectoId: PROYECTO_ID,
      modalidad: 'MENSUAL',
      monto: 4000000,
      fechaVigencia: '2026-01-01',
      activa: true,
      ...overrides,
    });
    return tarifa;
  }

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GenerarCobrosUseCase,
        { provide: DataSource, useValue: mockDataSource },
        { provide: CobroRepository, useValue: mockCobroRepo },
        { provide: PlanDeCobroRepository, useValue: mockPlanRepo },
        { provide: PeriodoCobroRepository, useValue: mockPeriodoRepo },
        { provide: TarifaRepository, useValue: mockTarifaRepo },
      ],
    }).compile();

    useCase = module.get<GenerarCobrosUseCase>(GenerarCobrosUseCase);
  });

  describe('execute()', () => {
    it('should generate cobros for active plans', async () => {
      const plan = crearPlan({ fechaActivacion: hoyStr });
      mockPlanRepo.findAllActivos.mockResolvedValue([plan]);
      mockPeriodoRepo.findByPlanAndMonth.mockResolvedValue(null);
      mockTarifaRepo.findVigente.mockResolvedValue(crearTarifa());
      mockPeriodoRepo.save.mockImplementation(async (p: PeriodoCobro) => {
        p.id = 'periodo-1';
        return p;
      });
      mockCobroRepo.saveMany.mockResolvedValue([]);

      const result = await useCase.execute();

      expect(result.generados).toBeGreaterThan(0);
      expect(mockPeriodoRepo.save).toHaveBeenCalledTimes(1);
      expect(mockCobroRepo.saveMany).toHaveBeenCalledTimes(1);
    });

    it('should skip plan when PeriodoCobro already exists (idempotency)', async () => {
      const plan = crearPlan({ fechaActivacion: hoyStr });
      mockPlanRepo.findAllActivos.mockResolvedValue([plan]);
      mockPeriodoRepo.findByPlanAndMonth.mockResolvedValue(new PeriodoCobro());

      const result = await useCase.execute();

      expect(result.generados).toBe(0);
      expect(mockPeriodoRepo.save).not.toHaveBeenCalled();
      expect(mockCobroRepo.saveMany).not.toHaveBeenCalled();
    });

    it('should skip plan when no tarifa and no valorMensual', async () => {
      const plan = crearPlan({ fechaActivacion: hoyStr });
      mockPlanRepo.findAllActivos.mockResolvedValue([plan]);
      mockPeriodoRepo.findByPlanAndMonth.mockResolvedValue(null);
      mockTarifaRepo.findVigente.mockResolvedValue(null);

      const result = await useCase.execute();

      expect(result.generados).toBe(0);
      expect(mockPeriodoRepo.save).not.toHaveBeenCalled();
      expect(mockCobroRepo.saveMany).not.toHaveBeenCalled();
    });

    it('should use plan.valorMensual when set (priority over tarifa)', async () => {
      const plan = crearPlan({
        valorMensual: 5000000,
        fechaActivacion: hoyStr,
      });
      mockPlanRepo.findAllActivos.mockResolvedValue([plan]);
      mockPeriodoRepo.findByPlanAndMonth.mockResolvedValue(null);
      // tarifa exists but should NOT be used
      mockTarifaRepo.findVigente.mockResolvedValue(
        crearTarifa({ monto: 9999999 }),
      );
      mockPeriodoRepo.save.mockImplementation(async (p: PeriodoCobro) => {
        p.id = 'periodo-2';
        return p;
      });
      mockCobroRepo.saveMany.mockImplementation(
        async (cobros: Cobro[]) => cobros,
      );

      const result = await useCase.execute();

      expect(result.generados).toBe(1); // MENSUAL = 1 cobro
      expect(mockCobroRepo.saveMany).toHaveBeenCalled();
      const savedCobros = mockCobroRepo.saveMany.mock.calls[0][0];
      expect(savedCobros[0].monto).toBe(5000000); // Uses plan.valorMensual
    });

    it('should generate no cobros when no active plans exist', async () => {
      mockPlanRepo.findAllActivos.mockResolvedValue([]);

      const result = await useCase.execute();

      expect(result.generados).toBe(0);
      expect(mockPeriodoRepo.save).not.toHaveBeenCalled();
      expect(mockCobroRepo.saveMany).not.toHaveBeenCalled();
    });

    it('should continue to next plan if one plan throws error', async () => {
      const plan1 = crearPlan({ id: 'plan-1', fechaActivacion: hoyStr });
      const plan2 = crearPlan({ id: 'plan-2', fechaActivacion: hoyStr });
      mockPlanRepo.findAllActivos.mockResolvedValue([plan1, plan2]);
      mockPeriodoRepo.findByPlanAndMonth.mockResolvedValue(null);
      mockTarifaRepo.findVigente
        .mockRejectedValueOnce(new Error('DB error')) // plan1 fails
        .mockResolvedValueOnce(crearTarifa()); // plan2 succeeds
      mockPeriodoRepo.save.mockImplementation(async (p: PeriodoCobro) => {
        p.id = 'periodo-3';
        return p;
      });
      mockCobroRepo.saveMany.mockResolvedValue([]);

      const result = await useCase.execute();

      // plan1 should fail, plan2 should succeed
      expect(result.generados).toBeGreaterThan(0);
      expect(mockTarifaRepo.findVigente).toHaveBeenCalledTimes(2);
    });
  });

  describe('generarCobrosParaPlan()', () => {
    it('should generate 4 cobros for SEMANAL', async () => {
      const plan = crearPlan({ modalidad: 'SEMANAL' });
      mockPeriodoRepo.findByPlanAndMonth.mockResolvedValue(null);
      mockTarifaRepo.findVigente.mockResolvedValue(
        crearTarifa({ modalidad: 'SEMANAL', monto: 1000000 }),
      );
      mockPeriodoRepo.save.mockImplementation(async (p: PeriodoCobro) => {
        p.id = 'periodo-semanal';
        return p;
      });

      const result = await useCase['generarCobrosParaPlan'](
        plan,
        6,
        2026,
        new Date(2026, 5, 1),
      );

      expect(result).toBe(4); // 4 sábados en junio 2026
      expect(mockCobroRepo.saveMany).toHaveBeenCalled();
    });

    it('should generate 2 cobros for QUINCENAL', async () => {
      const plan = crearPlan({ modalidad: 'QUINCENAL' });
      mockPeriodoRepo.findByPlanAndMonth.mockResolvedValue(null);
      mockTarifaRepo.findVigente.mockResolvedValue(
        crearTarifa({ modalidad: 'QUINCENAL', monto: 2000000 }),
      );
      mockPeriodoRepo.save.mockImplementation(async (p: PeriodoCobro) => {
        p.id = 'periodo-quincenal';
        return p;
      });

      const result = await useCase['generarCobrosParaPlan'](
        plan,
        6,
        2026,
        new Date(2026, 5, 1),
      );

      expect(result).toBe(2);
    });

    it('should generate 1 cobro for MENSUAL', async () => {
      const plan = crearPlan({ modalidad: 'MENSUAL' });
      mockPeriodoRepo.findByPlanAndMonth.mockResolvedValue(null);
      mockTarifaRepo.findVigente.mockResolvedValue(crearTarifa());
      mockPeriodoRepo.save.mockImplementation(async (p: PeriodoCobro) => {
        p.id = 'periodo-mensual';
        return p;
      });

      const result = await useCase['generarCobrosParaPlan'](
        plan,
        6,
        2026,
        new Date(2026, 5, 1),
      );

      expect(result).toBe(1);
    });
  });
});
