import { Test, TestingModule } from '@nestjs/testing';
import { DataSource } from 'typeorm';
import { RegistrarPagoUseCase, type RegistrarPagoInput } from './registrar-pago.use-case';
import { PagoRepository } from '../../infrastructure/persistence/pago.repository';
import { CobroRepository } from '../../infrastructure/persistence/cobro.repository';
import { PlanDeCobroRepository } from '../../infrastructure/persistence/plan-de-cobro.repository';
import { SolicitudRepository } from '../../infrastructure/persistence/solicitud.repository';
import { PagoCobroRepository } from '../../infrastructure/persistence/pago-cobro.repository';
import { Pago } from '../../domain/pago.entity';
import { Cobro } from '../../domain/cobro.entity';
import { PlanDeCobro } from '../../domain/plan-de-cobro.entity';
import { Money } from '../../../shared/common/value-objects';

import { GenerarTicketUseCase } from './generar-ticket.use-case';
import { TicketRepository } from '../../infrastructure/persistence/ticket.repository';
import { TicketCobro } from '../../domain/ticket-cobro.entity';

describe('RegistrarPagoUseCase', () => {
  let useCase: RegistrarPagoUseCase;

  const mockPagoRepo = {
    findByIdempotentKey: jest.fn(),
    save: jest.fn(),
  };

  const mockTicketRepo = {
    findByPago: jest.fn(),
    save: jest.fn(),
  };

  const mockGenerarTicketUC = {
    execute: jest.fn().mockImplementation(async (input) => {
      const ticket = new TicketCobro();
      ticket.id = 'ticket-1';
      ticket.numero = 'TKT-2026-000001';
      ticket.pagoId = input.pago.id;
      return ticket;
    }),
  };

  let pagoAutoId = 0;
  const mockEntityManager = {
    save: jest.fn().mockImplementation(async (entity: any) => {
      if (entity.constructor?.name === 'Pago' && !entity.id) {
        entity.id = `pago-${++pagoAutoId}`;
      }
      return entity;
    }),
    findOne: jest.fn(),
  };

  const mockDataSource = {
    transaction: jest.fn().mockImplementation(
      async (cb: (em: typeof mockEntityManager) => Promise<any>) => cb(mockEntityManager),
    ),
  };

  const mockCobroRepo = {
    findMasAntiguoConSaldoLocked: jest.fn(),
    findMasAntiguoConSaldo: jest.fn(),
    findByResidente: jest.fn(),
    save: jest.fn(),
    saveMany: jest.fn(),
  };

  const mockPlanRepo = {
    findByResidente: jest.fn(),
  };

  const mockSolicitudRepo = {
    findById: jest.fn(),
    save: jest.fn(),
  };

  const mockPagoCobroRepo = {
    save: jest.fn().mockImplementation(async (_em: any, vinc: any) => vinc),
    findByPago: jest.fn(),
  };

  const TENANT_ID = 'tenant-1';
  const RESIDENTE_ID = 'residente-1';
  const COBRADOR_ID = 'cobrador-1';

  /** Creates a valid input */
  function crearInput(overrides: Partial<RegistrarPagoInput> = {}): RegistrarPagoInput {
    return {
      clientPaymentId: 'pay-001',
      tenantId: TENANT_ID,
      monto: 40000,
      fechaPago: '2026-01-20',
      cobradorId: COBRADOR_ID,
      residenteId: RESIDENTE_ID,
      ...overrides,
    };
  }

  /** Creates a PENDIENTE cobro with given monto */
  function crearCobro(monto: number, overrides: Partial<Cobro> = {}): Cobro {
    const cobro = Cobro.crear(
      RESIDENTE_ID,
      TENANT_ID,
      'Cuota Test',
      Money.ofCOP(monto),
      '2026-01-01',
      '2026-02-01',
      '2026-01-15',
    );
    Object.assign(cobro, overrides);
    return cobro;
  }

  /** Creates a mock PlanDeCobro */
  function crearPlan(overrides: Partial<PlanDeCobro> = {}): PlanDeCobro {
    const plan = PlanDeCobro.crear('casa-1', RESIDENTE_ID, TENANT_ID, 'proy-1', 'MENSUAL', '2026-01-01');
    Object.assign(plan, { activa: true, ...overrides });
    return plan;
  }

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RegistrarPagoUseCase,
        { provide: DataSource, useValue: mockDataSource },
        { provide: PagoRepository, useValue: mockPagoRepo },
        { provide: CobroRepository, useValue: mockCobroRepo },
        { provide: PlanDeCobroRepository, useValue: mockPlanRepo },
        { provide: SolicitudRepository, useValue: mockSolicitudRepo },
        { provide: GenerarTicketUseCase, useValue: mockGenerarTicketUC },
        { provide: TicketRepository, useValue: mockTicketRepo },
        { provide: PagoCobroRepository, useValue: mockPagoCobroRepo },
      ],
    }).compile();

    useCase = module.get<RegistrarPagoUseCase>(RegistrarPagoUseCase);
  });

  // ═══════════════════════════════════════════════════════════
  // 1. Idempotency
  // ═══════════════════════════════════════════════════════════

  describe('Idempotency', () => {
    it('should return existing pago when same clientPaymentId exists', async () => {
      const existingPago = Pago.crear(
        'pay-001', TENANT_ID, Money.ofCOP(40000),
        '2026-01-20', COBRADOR_ID, RESIDENTE_ID,
      );
      mockPagoRepo.findByIdempotentKey.mockResolvedValue(existingPago);
      mockCobroRepo.findByResidente.mockResolvedValue([]);

      const result = await useCase.execute(crearInput());

      expect(result.pago.id).toBe(existingPago.id);
      expect(mockCobroRepo.save).not.toHaveBeenCalled();
      expect(mockPagoRepo.save).not.toHaveBeenCalled();
    });
  });

  // ═══════════════════════════════════════════════════════════
  // 2. Validation
  // ═══════════════════════════════════════════════════════════

  describe('Validation', () => {
    it('should throw if residente has no active PlanDeCobro', async () => {
      mockPagoRepo.findByIdempotentKey.mockResolvedValue(null);
      mockPlanRepo.findByResidente.mockResolvedValue(null);

      await expect(useCase.execute(crearInput())).rejects.toThrow(
        /no tiene un PlanDeCobro activo/,
      );
    });

    it('should throw if PlanDeCobro is inactive', async () => {
      mockPagoRepo.findByIdempotentKey.mockResolvedValue(null);
      mockPlanRepo.findByResidente.mockResolvedValue(
        crearPlan({ activa: false }),
      );

      await expect(useCase.execute(crearInput())).rejects.toThrow(
        /PlanDeCobro.*está desactivado/,
      );
    });

    it('should throw if no pending cobros exist', async () => {
      mockPagoRepo.findByIdempotentKey.mockResolvedValue(null);
      mockPlanRepo.findByResidente.mockResolvedValue(crearPlan());
      mockCobroRepo.findMasAntiguoConSaldo.mockResolvedValue(null);

      await expect(useCase.execute(crearInput())).rejects.toThrow(
        /No hay cobros pendientes/,
      );
    });
  });

  // ═══════════════════════════════════════════════════════════
  // 3. FIFO Distribution
  // ═══════════════════════════════════════════════════════════

  describe('FIFO Distribution', () => {
    beforeEach(() => {
      mockPagoRepo.findByIdempotentKey.mockResolvedValue(null);
      mockPlanRepo.findByResidente.mockResolvedValue(crearPlan());
        mockPagoRepo.save.mockImplementation(async (p: Pago) => p);
    });

    it('should apply partial payment to oldest cobro', async () => {
      const cobro1 = crearCobro(40000);
      mockCobroRepo.findMasAntiguoConSaldoLocked.mockResolvedValue(cobro1);

      const result = await useCase.execute(crearInput({ monto: 10000 }));

      expect(result.cobrosAfectados).toHaveLength(1);
      expect(result.cobrosAfectados[0].estado).toBe('PARCIAL');
      expect(result.cobrosAfectados[0].montoPagado).toBe(10000);
      expect(result.pago.monto).toBe(10000);
    });

    it('should apply full payment to oldest cobro (PAGADA)', async () => {
      const cobro1 = crearCobro(40000);
      mockCobroRepo.findMasAntiguoConSaldoLocked.mockResolvedValue(cobro1);

      const result = await useCase.execute(crearInput({ monto: 40000 }));

      expect(result.cobrosAfectados).toHaveLength(1);
      expect(result.cobrosAfectados[0].estado).toBe('PAGADA');
      expect(result.cobrosAfectados[0].montoPagado).toBe(40000);
    });

    it('should cross into next cobro when payment exceeds first', async () => {
      const cobro1 = crearCobro(40000, { id: 'cobro-1' });
      const cobro2 = crearCobro(40000, { id: 'cobro-2' });
      mockCobroRepo.findMasAntiguoConSaldoLocked
        .mockResolvedValueOnce(cobro1) // first call: oldest
        .mockResolvedValueOnce(cobro2); // second call: next oldest (after partial)

      const result = await useCase.execute(crearInput({ monto: 60000 }));

      expect(result.cobrosAfectados).toHaveLength(2);
      // First cobro should be PAGADA
      const c1 = result.cobrosAfectados.find(c => c.id === cobro1.id)!;
      expect(c1.estado).toBe('PAGADA');
      expect(c1.montoPagado).toBe(40000);
      // Second cobro should be PARCIAL
      const c2 = result.cobrosAfectados.find(c => c.id === cobro2.id)!;
      expect(c2.estado).toBe('PARCIAL');
      expect(c2.montoPagado).toBe(20000);
    });

    it('should log excess when payment exceeds all pending cobros', async () => {
      jest.spyOn(console, 'log').mockImplementation();
      const cobro1 = crearCobro(40000);
      mockCobroRepo.findMasAntiguoConSaldoLocked
        .mockResolvedValueOnce(cobro1)
        .mockResolvedValueOnce(null); // no more cobros

      const result = await useCase.execute(crearInput({ monto: 50000 }));

      expect(result.cobrosAfectados).toHaveLength(1);
      expect(result.cobrosAfectados[0].estado).toBe('PAGADA');
    });
  });

  // ═══════════════════════════════════════════════════════════
  // 4. Solicitud auto-closing
  // ═══════════════════════════════════════════════════════════

  describe('Solicitud auto-closing', () => {
    beforeEach(() => {
      mockPagoRepo.findByIdempotentKey.mockResolvedValue(null);
      mockPlanRepo.findByResidente.mockResolvedValue(crearPlan());
      // Set an ID on the saved pago (auto-generated by DB in real life)
      let pagoCounter = 0;
      mockPagoRepo.save.mockImplementation(async (p: Pago) => {
        if (!p.id) p.id = `pago-${++pagoCounter}`;
        return p;
      });
    });

    it('should close solicitud when solicitudId is provided', async () => {
      const cobro = crearCobro(40000);
      const mockSolicitud = {
        id: 'sol-1',
        estado: 'EN_REVISION',
        pagoId: null,
        respuesta: null,
        fechaRespuesta: null,
      };
      mockCobroRepo.findMasAntiguoConSaldoLocked.mockResolvedValue(cobro);
      mockSolicitudRepo.findById.mockResolvedValue(mockSolicitud);
      mockSolicitudRepo.save.mockResolvedValue(mockSolicitud);

      await useCase.execute(crearInput({ solicitudId: 'sol-1' }));

      expect(mockSolicitudRepo.findById).toHaveBeenCalledWith('sol-1');
      expect(mockEntityManager.save).toHaveBeenCalled();
      expect(mockSolicitud.estado).toBe('RESUELTA');
      expect(mockSolicitud.pagoId).toBeTruthy();
      expect(mockSolicitud.respuesta).toContain('Pago registrado');
    });

    it('should not fail if solicitudId is invalid', async () => {
      const cobro = crearCobro(40000);
      mockCobroRepo.findMasAntiguoConSaldoLocked.mockResolvedValue(cobro);
      mockSolicitudRepo.findById.mockResolvedValue(null);

      const result = await useCase.execute(crearInput({ solicitudId: 'no-existe' }));

      expect(result).toBeDefined();
      expect(mockSolicitudRepo.save).not.toHaveBeenCalled();
    });
  });

  // ═══════════════════════════════════════════════════════════
  // 5. Event emission
  // ═══════════════════════════════════════════════════════════

  describe('Event emission', () => {
    it('should return a PagoRegistradoEvent with correct data', async () => {
      mockPagoRepo.findByIdempotentKey.mockResolvedValue(null);
      mockPlanRepo.findByResidente.mockResolvedValue(crearPlan());
      const cobro = crearCobro(40000);
      mockCobroRepo.findMasAntiguoConSaldoLocked.mockResolvedValue(cobro);
      mockPagoRepo.save.mockImplementation(async (p: Pago) => p);

      const result = await useCase.execute(crearInput({ monto: 40000 }));

      expect(result.event).toBeDefined();
      expect(result.event.pagoId).toBe(result.pago.id);
      expect(result.event.clientPaymentId).toBe('pay-001');
      expect(result.event.residenteId).toBe(RESIDENTE_ID);
      expect(result.event.monto).toBe(40000);
      expect(result.event.cuotasAfectadas).toHaveLength(1);
    });
  });
});
