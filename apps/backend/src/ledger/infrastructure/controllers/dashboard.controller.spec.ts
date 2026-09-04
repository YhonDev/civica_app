import { Test, TestingModule } from '@nestjs/testing';
import { DashboardController } from './dashboard.controller';
import { DashboardQuery } from '../../application/queries/dashboard.query';
import { CobroRepository } from '../persistence/cobro.repository';
import { PagoRepository } from '../persistence/pago.repository';
import { PlanDeCobroRepository } from '../persistence/plan-de-cobro.repository';
import { SolicitudRepository } from '../persistence/solicitud.repository';
import { TarifaRepository } from '../persistence/tarifa.repository';
import { ResidenteRepository } from '../../../community/infrastructure/residente.repository';
import { DataSource } from 'typeorm';
import { Cobro } from '../../domain/cobro.entity';
import { Money } from '../../../shared/common/value-objects';
import { Usuario, RolUsuario } from '../../../iam/domain/usuario.entity';

describe('DashboardController — Cobrador Logic', () => {
  let controller: DashboardController;

  const mockDashboardQuery = {};
  const mockCobroRepo = {
    findPendientesByTenant: jest.fn(),
    findByResidente: jest.fn(),
  };
  const mockPagoRepo = {
    findByCobradorToday: jest.fn(),
    findByPropietario: jest.fn(),
  };
  const mockPlanDeCobroRepo = {
    findByResidente: jest.fn(),
  };
  const mockSolicitudRepo = {
    findByUsuario: jest.fn(),
  };
  const mockTarifaRepo = {
    findVigentesPorConjunto: jest.fn(),
  };
  const mockResidenteRepo = {
    findByIdWithRelations: jest.fn(),
  };
  const mockDataSource = {
    query: jest.fn(),
  };

  const TENANT_ID = 'tenant-1';

  function crearUser(overrides: Partial<Usuario> = {}): Usuario {
    const user = new Usuario();
    Object.assign(user, {
      id: 'user-1',
      nombre: 'Cobrador Test',
      email: 'cobrador@test.com',
      rol: RolUsuario.COBRADOR,
      tenantId: TENANT_ID,
      activo: true,
      ...overrides,
    });
    return user;
  }

  /** Creates a Cobro with nested relations mimicking TypeORM shape */
  function crearCobroConResidente(
    residenteId: string,
    estado: string,
    monto: number,
    montoPagado: number,
    casa: {
      id: string;
      direccionInterna: string;
      manzana: { nombre: string; etapa: { nombre: string } };
    },
    overrides: Partial<Cobro> = {},
  ): Cobro {
    const cobro = Cobro.crear(
      residenteId,
      TENANT_ID,
      'Cuota Test',
      Money.ofCOP(monto),
      '2026-01-01',
      '2026-02-01',
      '2026-01-15',
    );
    Object.assign(cobro, {
      montoPagado,
      estado,
      residente: {
        id: residenteId,
        nombre: `Residente ${residenteId.slice(0, 4)}`,
        telefono: '555-0101',
        tenencias: [
          {
            fechaFin: null,
            casa: {
              id: casa.id,
              direccionInterna: casa.direccionInterna,
              manzana: {
                nombre: casa.manzana.nombre,
                etapa: {
                  nombre: casa.manzana.etapa.nombre,
                },
              },
            },
          },
        ],
      },
      ...overrides,
    });
    return cobro;
  }

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      controllers: [DashboardController],
      providers: [
        { provide: DashboardQuery, useValue: mockDashboardQuery },
        { provide: CobroRepository, useValue: mockCobroRepo },
        { provide: PagoRepository, useValue: mockPagoRepo },
        { provide: PlanDeCobroRepository, useValue: mockPlanDeCobroRepo },
        { provide: SolicitudRepository, useValue: mockSolicitudRepo },
        { provide: TarifaRepository, useValue: mockTarifaRepo },
        { provide: ResidenteRepository, useValue: mockResidenteRepo },
        { provide: DataSource, useValue: mockDataSource },
      ],
    }).compile();

    controller = module.get<DashboardController>(DashboardController);
  });

  describe('getDashboardCobrador()', () => {
    it('should group cobros by vivienda (casa)', async () => {
      const user = crearUser();
      mockDataSource.query.mockResolvedValue([{ etapa_id: 'etapa-1' }]);
      mockPagoRepo.findByCobradorToday.mockResolvedValue({
        pagos: [],
        total: 0,
        count: 0,
      });

      const cobro1 = crearCobroConResidente('res-1', 'PENDIENTE', 40000, 0, {
        id: 'casa-1',
        direccionInterna: 'Casa 101',
        manzana: { nombre: 'Manzana A', etapa: { nombre: 'Etapa Alfa' } },
      });

      mockCobroRepo.findPendientesByTenant.mockResolvedValue([cobro1]);

      const result = await controller.getDashboardCobrador(user, TENANT_ID);

      expect(result.stats.totalViviendas).toBe(1);
      expect(result.viviendas).toHaveLength(1);
      expect(result.viviendas[0].casaDireccion).toBe('Casa 101');
      expect(result.viviendas[0].manzanaNombre).toBe('Manzana A');
      expect(result.viviendas[0].etapaNombre).toBe('Etapa Alfa');
      expect(result.viviendas[0].saldo).toBe(400); // 40000 cents / 100 = 400
    });

    it('should aggregate multiple cobros from same casa into one vivienda', async () => {
      const user = crearUser();
      mockDataSource.query.mockResolvedValue([{ etapa_id: 'etapa-1' }]);
      mockPagoRepo.findByCobradorToday.mockResolvedValue({
        pagos: [],
        total: 0,
        count: 0,
      });

      const cobro1 = crearCobroConResidente('res-1', 'PENDIENTE', 40000, 0, {
        id: 'casa-1',
        direccionInterna: 'Casa 101',
        manzana: { nombre: 'Manzana A', etapa: { nombre: 'Etapa Alfa' } },
      });
      const cobro2 = crearCobroConResidente('res-1', 'VENCIDA', 50000, 0, {
        id: 'casa-1',
        direccionInterna: 'Casa 101',
        manzana: { nombre: 'Manzana A', etapa: { nombre: 'Etapa Alfa' } },
      });

      mockCobroRepo.findPendientesByTenant.mockResolvedValue([cobro1, cobro2]);

      const result = await controller.getDashboardCobrador(user, TENANT_ID);

      expect(result.viviendas).toHaveLength(1);
      // saldo = (40000-0 + 50000-0) / 100 = 900
      expect(result.viviendas[0].saldo).toBe(900);
      // peor estado debe ser VENCIDA (prioridad sobre PENDIENTE)
      expect(result.viviendas[0].peorEstado).toBe('VENCIDA');
    });

    it('should sort viviendas with VENCIDA first, then PARCIAL, then PENDIENTE', async () => {
      const user = crearUser();
      mockDataSource.query.mockResolvedValue([{ etapa_id: 'etapa-1' }]);
      mockPagoRepo.findByCobradorToday.mockResolvedValue({
        pagos: [],
        total: 0,
        count: 0,
      });

      const cobroVencida = crearCobroConResidente(
        'res-vencida',
        'VENCIDA',
        40000,
        0,
        {
          id: 'casa-vencida',
          direccionInterna: 'Casa Vencida',
          manzana: { nombre: 'Mz B', etapa: { nombre: 'Etapa Beta' } },
        },
      );
      const cobroPendiente = crearCobroConResidente(
        'res-pendiente',
        'PENDIENTE',
        30000,
        0,
        {
          id: 'casa-pendiente',
          direccionInterna: 'Casa Pendiente',
          manzana: { nombre: 'Mz A', etapa: { nombre: 'Etapa Alfa' } },
        },
      );

      mockCobroRepo.findPendientesByTenant.mockResolvedValue([
        cobroPendiente,
        cobroVencida,
      ]);

      const result = await controller.getDashboardCobrador(user, TENANT_ID);

      expect(result.viviendas).toHaveLength(2);
      // VENCIDA debe ir primero
      expect(result.viviendas[0].casaDireccion).toBe('Casa Vencida');
      expect(result.viviendas[1].casaDireccion).toBe('Casa Pendiente');
      expect(result.proximaVivienda!.casaDireccion).toBe('Casa Vencida');
    });

    it('should return empty arrays when cobrador has no assigned etapas', async () => {
      const user = crearUser();
      mockDataSource.query.mockResolvedValue([]); // no asignaciones

      const result = await controller.getDashboardCobrador(user, TENANT_ID);

      expect(result.stats.totalViviendas).toBe(0);
      expect(result.viviendas).toHaveLength(0);
      expect(result.proximaVivienda).toBeNull();
    });

    it('should return empty arrays when no pendientes cobros exist', async () => {
      const user = crearUser();
      mockDataSource.query.mockResolvedValue([{ etapa_id: 'etapa-1' }]);
      mockCobroRepo.findPendientesByTenant.mockResolvedValue([]);
      mockPagoRepo.findByCobradorToday.mockResolvedValue({
        pagos: [],
        total: 0,
        count: 0,
      });

      const result = await controller.getDashboardCobrador(user, TENANT_ID);

      expect(result.stats.totalViviendas).toBe(0);
      expect(result.viviendas).toHaveLength(0);
      expect(result.proximaVivienda).toBeNull();
    });

    it('should skip cobros where residente has no active tenencia', async () => {
      const user = crearUser();
      mockDataSource.query.mockResolvedValue([{ etapa_id: 'etapa-1' }]);
      mockPagoRepo.findByCobradorToday.mockResolvedValue({
        pagos: [],
        total: 0,
        count: 0,
      });

      const cobro = Cobro.crear(
        'res-sin-tenencia',
        TENANT_ID,
        'Cuota Test',
        Money.ofCOP(40000),
        '2026-01-01',
        '2026-02-01',
        '2026-01-15',
      );
      Object.assign(cobro, {
        estado: 'PENDIENTE',
        residente: {
          id: 'res-sin-tenencia',
          nombre: 'Sin Tenencia',
          tenencias: [], // no active tenencias
        },
      });

      mockCobroRepo.findPendientesByTenant.mockResolvedValue([cobro]);

      const result = await controller.getDashboardCobrador(user, TENANT_ID);

      // Should be skipped because residente has no active tenencia
      expect(result.stats.totalViviendas).toBe(0);
    });

    it('should calculate stats correctly (pendientes, vencidas, montoEsperado)', async () => {
      const user = crearUser();
      mockDataSource.query.mockResolvedValue([{ etapa_id: 'etapa-1' }]);
      mockPagoRepo.findByCobradorToday.mockResolvedValue({
        pagos: [],
        total: 0,
        count: 0,
      });

      const cobroVencida = crearCobroConResidente(
        'res-v',
        'VENCIDA',
        50000,
        0,
        {
          id: 'casa-v',
          direccionInterna: 'Casa V',
          manzana: { nombre: 'Mz V', etapa: { nombre: 'Eta V' } },
        },
      );
      const cobroPendiente = crearCobroConResidente(
        'res-p',
        'PENDIENTE',
        30000,
        0,
        {
          id: 'casa-p',
          direccionInterna: 'Casa P',
          manzana: { nombre: 'Mz P', etapa: { nombre: 'Eta P' } },
        },
      );

      mockCobroRepo.findPendientesByTenant.mockResolvedValue([
        cobroVencida,
        cobroPendiente,
      ]);

      const result = await controller.getDashboardCobrador(user, TENANT_ID);

      expect(result.stats.totalViviendas).toBe(2);
      expect(result.stats.pendientes).toBe(1); // one PENDIENTE vivienda
      expect(result.stats.vencidas).toBe(1); // one VENCIDA vivienda
      expect(result.stats.montoEsperado).toBe(800); // (500+300)
    });

    it('should include cobradosHoy in stats when cobrador has payments today', async () => {
      const user = crearUser();
      mockDataSource.query.mockResolvedValue([{ etapa_id: 'etapa-1' }]);
      mockCobroRepo.findPendientesByTenant.mockResolvedValue([]);
      mockPagoRepo.findByCobradorToday.mockResolvedValue({
        pagos: [{ id: 'pago-1', monto: 40000, fechaPago: '2026-07-17' }],
        total: 40000,
        count: 1,
      });

      const result = await controller.getDashboardCobrador(user, TENANT_ID);

      expect(result.stats.cobradosHoy).toBe(1);
      expect(result.stats.montoCobradoHoy).toBe(400); // 40000 / 100
      expect(result.ultimosCobros).toHaveLength(1);
    });

    it('should not fail when cobro has no resident (should be skipped)', async () => {
      const user = crearUser();
      mockDataSource.query.mockResolvedValue([{ etapa_id: 'etapa-1' }]);
      mockPagoRepo.findByCobradorToday.mockResolvedValue({
        pagos: [],
        total: 0,
        count: 0,
      });

      const cobro = Cobro.crear(
        'res-orphan',
        TENANT_ID,
        'Cuota Test',
        Money.ofCOP(40000),
        '2026-01-01',
        '2026-02-01',
        '2026-01-15',
      );
      // No residente assigned
      Object.assign(cobro, { estado: 'PENDIENTE', residente: null });

      mockCobroRepo.findPendientesByTenant.mockResolvedValue([cobro]);

      const result = await controller.getDashboardCobrador(user, TENANT_ID);

      // Should not throw, cobro with no residente should be skipped
      expect(result.stats.totalViviendas).toBe(0);
    });
  });

  describe('getViviendasExplorer()', () => {
    it('should return empty etapas when cobrador has no asignaciones', async () => {
      const user = crearUser();
      mockDataSource.query.mockResolvedValue([]);

      const result = await controller.getViviendasExplorer(user, TENANT_ID);

      expect(result.etapas).toHaveLength(0);
    });
  });

  describe('getDashboardResidente()', () => {
    it('should read dashboard data without generating cobros or marking vencidas', async () => {
      const generarCobrosUC = { execute: jest.fn() };
      const marcarVencidasUC = { execute: jest.fn() };
      const controllerWithLegacyDependencies = new (DashboardController as any)(
        mockDashboardQuery,
        mockCobroRepo,
        mockPagoRepo,
        mockPlanDeCobroRepo,
        mockSolicitudRepo,
        mockTarifaRepo,
        mockResidenteRepo,
        mockDataSource,
        generarCobrosUC,
        marcarVencidasUC,
      ) as DashboardController;
      const user = crearUser({ residenteId: 'residente-1' });

      mockCobroRepo.findByResidente.mockResolvedValue([]);
      mockPagoRepo.findByPropietario.mockResolvedValue([]);
      mockPlanDeCobroRepo.findByResidente.mockResolvedValue(null);
      mockResidenteRepo.findByIdWithRelations.mockResolvedValue({
        id: 'residente-1',
        nombre: 'Residente Test',
        modalidadPago: 'MENSUAL',
        tenencias: [],
      });
      mockSolicitudRepo.findByUsuario.mockResolvedValue([]);

      const result = await controllerWithLegacyDependencies.getDashboardResidente(
        user,
        TENANT_ID,
      );

      expect(result.status).toBe('AL_DIA');
      expect(result.movimientos).toEqual([]);
      expect(generarCobrosUC.execute).not.toHaveBeenCalled();
      expect(marcarVencidasUC.execute).not.toHaveBeenCalled();
    });
  });
});
