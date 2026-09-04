import { Test, TestingModule } from '@nestjs/testing';
import { DataSource } from 'typeorm';
import { ReconciliarModalidadUseCase } from './reconciliar-modalidad.use-case';
import { PlanDeCobroRepository } from '../../infrastructure/persistence/plan-de-cobro.repository';
import { PeriodoCobroRepository } from '../../infrastructure/persistence/periodo-cobro.repository';
import { TarifaRepository } from '../../infrastructure/persistence/tarifa.repository';
import { EventsGateway } from '../../../notifications/events.gateway';

describe('ReconciliarModalidadUseCase', () => {
  let useCase: ReconciliarModalidadUseCase;
  let mockPlanRepo: any;
  let mockPeriodoRepo: any;
  let mockTarifaRepo: any;
  let mockEventsGateway: any;

  // Transaction mock: captures the callback and invokes it with a mock EM
  let mockQueryBuilder: any;
  let mockEntityManager: any;
  let mockDataSource: any;

  beforeEach(async () => {
    mockPlanRepo = {
      findByResidente: jest.fn(),
      save: jest.fn(),
    };

    mockPeriodoRepo = {
      findByPlanAndMonth: jest.fn(),
    };

    mockTarifaRepo = {
      findVigente: jest.fn(),
    };

    mockEventsGateway = {
      emitModalidadCambiada: jest.fn(),
    };

    mockQueryBuilder = {
      where: jest.fn().mockReturnThis(),
      andWhere: jest.fn().mockReturnThis(),
      setLock: jest.fn().mockReturnThis(),
      getMany: jest.fn().mockResolvedValue([]),
    };

    mockEntityManager = {
      save: jest.fn().mockImplementation(async (value: any) => value),
      delete: jest.fn().mockResolvedValue(undefined),
      createQueryBuilder: jest.fn().mockReturnValue(mockQueryBuilder),
    };

    mockDataSource = {
      transaction: jest
        .fn()
        .mockImplementation(
          async (cb: (em: any) => Promise<any>) => cb(mockEntityManager),
        ),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ReconciliarModalidadUseCase,
        { provide: PlanDeCobroRepository, useValue: mockPlanRepo },
        { provide: PeriodoCobroRepository, useValue: mockPeriodoRepo },
        { provide: TarifaRepository, useValue: mockTarifaRepo },
        { provide: DataSource, useValue: mockDataSource },
        { provide: EventsGateway, useValue: mockEventsGateway },
      ],
    }).compile();

    useCase = module.get<ReconciliarModalidadUseCase>(
      ReconciliarModalidadUseCase,
    );
  });

  it('should be defined', () => {
    expect(useCase).toBeDefined();
  });

  it('should gracefully warn and return if no plan exists', async () => {
    mockPlanRepo.findByResidente.mockResolvedValue(null);

    await useCase.execute('residente-123', 'QUINCENAL', 'tenant-001');

    expect(mockDataSource.transaction).not.toHaveBeenCalled();
    expect(mockEventsGateway.emitModalidadCambiada).not.toHaveBeenCalled();
  });

  it('should not start transaction if no period exists', async () => {
    const mockPlan = {
      id: 'plan-123',
      tenantId: 'tenant-001',
      modalidad: 'SEMANAL',
      fechaActivacion: '2026-01-01',
      valorMensual: 4000000,
    };
    mockPlanRepo.findByResidente.mockResolvedValue(mockPlan);
    mockPeriodoRepo.findByPlanAndMonth.mockResolvedValue(null);

    await useCase.execute('residente-123', 'QUINCENAL', 'tenant-001');

    expect(mockDataSource.transaction).not.toHaveBeenCalled();
    expect(mockEventsGateway.emitModalidadCambiada).not.toHaveBeenCalled();
  });

  it('should lock cobros with pessimistic_write inside a transaction', async () => {
    const mockPlan = {
      id: 'plan-123',
      tenantId: 'tenant-001',
      proyectoId: 'proyecto-001',
      modalidad: 'SEMANAL',
      fechaActivacion: '2026-01-01',
      valorMensual: 4000000,
    };

    const mockPeriodo = { id: 'periodo-123' };
    const mockCobros = [
      {
        id: 'cobro-1',
        periodoId: 'periodo-123',
        estado: 'PENDIENTE',
        monto: 1000000,
        montoPagado: 0,
        periodoInicio: '2026-08-01',
      },
    ];

    mockPlanRepo.findByResidente.mockResolvedValue(mockPlan);
    mockPeriodoRepo.findByPlanAndMonth.mockResolvedValue(mockPeriodo);
    mockQueryBuilder.getMany.mockResolvedValue(mockCobros);

    await useCase.execute('residente-123', 'QUINCENAL', 'tenant-001');

    // Transaction was used
    expect(mockDataSource.transaction).toHaveBeenCalledTimes(1);

    // Cobros were locked with pessimistic_write
    expect(mockEntityManager.createQueryBuilder).toHaveBeenCalled();
    expect(mockQueryBuilder.setLock).toHaveBeenCalledWith(
      'pessimistic_write',
    );

    // Plan was saved inside the transaction
    expect(mockEntityManager.save).toHaveBeenCalledWith(
      expect.objectContaining({ modalidad: 'QUINCENAL' }),
    );

    // Old cobros were deleted inside the transaction
    expect(mockEntityManager.delete).toHaveBeenCalled();

    // New cobros were saved inside the transaction
    expect(mockEntityManager.save).toHaveBeenCalledTimes(2); // plan + nuevosCobros

    // Event was emitted after the transaction
    expect(mockEventsGateway.emitModalidadCambiada).toHaveBeenCalledWith({
      tenantId: 'tenant-001',
      residenteId: 'residente-123',
      nuevaModalidad: 'QUINCENAL',
    });
  });

  it('should not emit event when no cobros exist for the period', async () => {
    const mockPlan = {
      id: 'plan-123',
      tenantId: 'tenant-001',
      modalidad: 'SEMANAL',
      fechaActivacion: '2026-01-01',
      valorMensual: 4000000,
    };
    const mockPeriodo = { id: 'periodo-123' };

    mockPlanRepo.findByResidente.mockResolvedValue(mockPlan);
    mockPeriodoRepo.findByPlanAndMonth.mockResolvedValue(mockPeriodo);
    mockQueryBuilder.getMany.mockResolvedValue([]);

    await useCase.execute('residente-123', 'QUINCENAL', 'tenant-001');

    expect(mockDataSource.transaction).toHaveBeenCalledTimes(1);
    expect(mockEventsGateway.emitModalidadCambiada).not.toHaveBeenCalled();
  });
});
