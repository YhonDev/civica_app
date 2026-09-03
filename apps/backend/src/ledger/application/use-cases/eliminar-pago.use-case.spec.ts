import { Test, TestingModule } from '@nestjs/testing';
import { DataSource, EntityManager } from 'typeorm';
import { EliminarPagoUseCase } from './eliminar-pago.use-case';
import { PagoRepository } from '../../infrastructure/persistence/pago.repository';
import { PagoCobroRepository } from '../../infrastructure/persistence/pago-cobro.repository';
import { Pago } from '../../domain/pago.entity';
import { Cobro } from '../../domain/cobro.entity';
import { PagoCobro } from '../../domain/pago-cobro.entity';
import { Money } from '../../../shared/common/value-objects';

describe('EliminarPagoUseCase', () => {
  let useCase: EliminarPagoUseCase;

  const mockPagoRepo = {
    findById: jest.fn(),
  };

  const mockPagoCobroRepo = {
    findByPago: jest.fn(),
    removeByPago: jest.fn(),
  };

  // Mock que imita entityManager.findOne(Cobro) y entityManager.save(Cobro) para
  // resolver los cobros referenciados por los vínculos pago_cobros.
  let cobrosPorId: Map<string, Cobro>;

  const mockEntityManager = {
    findOne: jest.fn().mockImplementation(async (entity: any, opts: any) => {
      if (entity === Cobro) {
        return cobrosPorId.get(opts.where.id) ?? null;
      }
      return null;
    }),
    save: jest
      .fn()
      .mockImplementation(async (_entity: any, value: any) => value),
    delete: jest.fn().mockResolvedValue(undefined),
    remove: jest.fn().mockResolvedValue(undefined),
    getRepository: jest.fn(),
  };

  const mockDataSource = {
    transaction: jest
      .fn()
      .mockImplementation(async (cb: (em: EntityManager) => Promise<any>) =>
        cb(mockEntityManager as unknown as EntityManager),
      ),
  };

  const TENANT_ID = 'tenant-1';
  const RESIDENTE_ID = 'residente-1';

  function crearPago(monto: number, id: string): Pago {
    const pago = Pago.crear(
      `pay-${id}`,
      TENANT_ID,
      Money.ofCOP(monto),
      '2026-01-20',
      'cobrador-1',
      RESIDENTE_ID,
    );
    pago.id = id;
    return pago;
  }

  function crearCobro(
    id: string,
    monto: number,
    montoPagado: number,
    fechaVencimiento = '2026-12-15',
  ): Cobro {
    const cobro = Cobro.crear(
      RESIDENTE_ID,
      TENANT_ID,
      'Cuota Test',
      Money.ofCOP(monto),
      '2026-01-01',
      '2026-02-01',
      fechaVencimiento,
    );
    cobro.id = id;
    cobro.montoPagado = montoPagado;
    cobro.estado =
      montoPagado === 0
        ? 'PENDIENTE'
        : montoPagado === monto
          ? 'PAGADA'
          : 'PARCIAL';
    return cobro;
  }

  function crearVinculo(
    pagoId: string,
    cobroId: string,
    montoAplicado: number,
  ): PagoCobro {
    const vinc = new PagoCobro();
    vinc.id = `vinc-${pagoId}-${cobroId}`;
    vinc.pagoId = pagoId;
    vinc.cobroId = cobroId;
    vinc.montoAplicado = montoAplicado;
    vinc.tenantId = TENANT_ID;
    return vinc;
  }

  beforeEach(async () => {
    jest.clearAllMocks();
    cobrosPorId = new Map();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        EliminarPagoUseCase,
        { provide: DataSource, useValue: mockDataSource },
        { provide: PagoRepository, useValue: mockPagoRepo },
        { provide: PagoCobroRepository, useValue: mockPagoCobroRepo },
      ],
    }).compile();

    useCase = module.get<EliminarPagoUseCase>(EliminarPagoUseCase);
  });

  it('should throw NotFoundException if payment does not exist', async () => {
    mockPagoRepo.findById.mockResolvedValue(null);

    await expect(useCase.execute('pago-1', TENANT_ID)).rejects.toThrow(
      /no encontrado/,
    );
  });

  it('should throw NotFoundException if payment belongs to another tenant', async () => {
    const pago = crearPago(40000, 'pago-1');
    mockPagoRepo.findById.mockResolvedValue(pago);

    await expect(useCase.execute('pago-1', 'tenant-OTHER')).rejects.toThrow(
      /no encontrado/,
    );
  });

  it('should revert exactly the cobros touched by the payment via pago_cobros (B1: multi-cobro FIFO)', async () => {
    // Pago 1 tocó únicamente el cobro A (el más antiguo).
    const pago1 = crearPago(40000, 'pago-1');
    const cobroA = crearCobro('cobro-A', 50000, 40000); // pagado por pago1
    const cobroB = crearCobro('cobro-B', 50000, 20000); // pagado por OTRO pago (pago2) — debe quedar intacto

    cobrosPorId.set(cobroA.id, cobroA);
    cobrosPorId.set(cobroB.id, cobroB);

    mockPagoRepo.findById.mockResolvedValue(pago1);
    // pago1 solo tiene vínculo con cobro A
    mockPagoCobroRepo.findByPago.mockResolvedValue([
      crearVinculo('pago-1', 'cobro-A', 40000),
    ]);

    await useCase.execute('pago-1', TENANT_ID);

    // El cobro A debe quedar totalmente des-pagado
    expect(cobroA.montoPagado).toBe(0);
    expect(cobroA.estado).toBe('PENDIENTE');

    // El cobro B NO debe verse afectado por el reverso del pago1
    expect(cobroB.montoPagado).toBe(20000);
    expect(cobroB.estado).toBe('PARCIAL');

    // Se deben eliminar los vínculos del pago
    expect(mockPagoCobroRepo.removeByPago).toHaveBeenCalledWith(
      mockEntityManager,
      'pago-1',
    );
  });

  it('should revert a single-cobro payment exactly (full PAGADA -> PENDIENTE)', async () => {
    const pago = crearPago(40000, 'pago-1');
    const cobro = crearCobro('cobro-1', 40000, 40000, '2026-12-15'); // PAGADA por este pago

    cobrosPorId.set(cobro.id, cobro);

    mockPagoRepo.findById.mockResolvedValue(pago);
    mockPagoCobroRepo.findByPago.mockResolvedValue([
      crearVinculo('pago-1', 'cobro-1', 40000),
    ]);

    await useCase.execute('pago-1', TENANT_ID);

    expect(cobro.montoPagado).toBe(0);
    expect(cobro.estado).toBe('PENDIENTE');
    expect(mockEntityManager.save).toHaveBeenCalledWith(Cobro, cobro);
  });

  it('should fall back to LIFO reversal when no pago_cobros exist (legacy data)', async () => {
    const pago = crearPago(60000, 'pago-legacy');
    const cobroA = crearCobro('cobro-A', 50000, 40000);
    const cobroB = crearCobro('cobro-B', 50000, 20000);

    cobrosPorId.set(cobroA.id, cobroA);
    cobrosPorId.set(cobroB.id, cobroB);

    mockPagoRepo.findById.mockResolvedValue(pago);
    // Sin vínculos => pago legacy pre-fix
    mockPagoCobroRepo.findByPago.mockResolvedValue([]);

    const legacyCobros = [...cobrosPorId.values()];
    mockEntityManager.getRepository.mockReturnValue({
      find: jest.fn().mockResolvedValue(legacyCobros),
    });

    await useCase.execute('pago-legacy', TENANT_ID);

    // LIFO: se revierte primero el cobro más nuevo (B) y luego el más antiguo (A)
    // Total a revertir: 60000
    // B saldó 20000 -> B queda 0, restan 40000
    // A saldó 40000 -> A queda 0
    expect(cobroB.montoPagado).toBe(0);
    expect(cobroA.montoPagado).toBe(0);
    // En el fallback legacy no hay vínculos que eliminar.
    expect(mockPagoCobroRepo.removeByPago).not.toHaveBeenCalled();
  });
});
