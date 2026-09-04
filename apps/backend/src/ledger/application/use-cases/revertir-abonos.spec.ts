import { EntityManager } from 'typeorm';
import { revertirAbonos } from './revertir-abonos';
import { PagoCobroRepository } from '../../infrastructure/persistence/pago-cobro.repository';
import { Pago } from '../../domain/pago.entity';
import { Cobro } from '../../domain/cobro.entity';
import { PagoCobro } from '../../domain/pago-cobro.entity';
import { Money } from '../../../shared/common/value-objects';

describe('revertirAbonos', () => {
  const TENANT_ID = 'tenant-1';
  const RESIDENTE_ID = 'residente-1';

  let cobrosPorId: Map<string, Cobro>;
  let findOneSpy: jest.Mock;
  let findSpy: jest.Mock;
  let mockEntityManager: any;
  let mockPagoCobroRepo: jest.Mocked<PagoCobroRepository>;

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

  beforeEach(() => {
    jest.clearAllMocks();
    cobrosPorId = new Map();

    findOneSpy = jest.fn().mockImplementation(async (entity: any, opts: any) => {
      if (entity === Cobro) {
        return cobrosPorId.get(opts.where.id) ?? null;
      }
      return null;
    });

    findSpy = jest.fn().mockResolvedValue([]);

    mockEntityManager = {
      findOne: findOneSpy,
      save: jest
        .fn()
        .mockImplementation(async (_entity: any, value: any) => value),
      getRepository: jest.fn().mockReturnValue({
        find: findSpy,
      }),
    };

    mockPagoCobroRepo = {
      findByPago: jest.fn(),
      removeByPago: jest.fn(),
    } as any;
  });

  // ─── Exact reversal (pago_cobros exist) ───────────────

  describe('exact reversal path', () => {
    it('should lock cobros with pessimistic_write during exact reversal', async () => {
      const pago = crearPago(40000, 'pago-1');
      const cobro = crearCobro('cobro-1', 50000, 40000);
      cobrosPorId.set(cobro.id, cobro);

      mockPagoCobroRepo.findByPago.mockResolvedValue([
        crearVinculo('pago-1', 'cobro-1', 40000),
      ]);

      await revertirAbonos(
        mockEntityManager as unknown as EntityManager,
        pago,
        mockPagoCobroRepo,
      );

      expect(findOneSpy).toHaveBeenCalledWith(Cobro, {
        where: { id: 'cobro-1' },
        lock: { mode: 'pessimistic_write' },
      });
    });

    it('should revert exactly and remove vinculos', async () => {
      const pago = crearPago(40000, 'pago-1');
      const cobro = crearCobro('cobro-1', 50000, 40000);
      cobrosPorId.set(cobro.id, cobro);

      mockPagoCobroRepo.findByPago.mockResolvedValue([
        crearVinculo('pago-1', 'cobro-1', 40000),
      ]);

      const result = await revertirAbonos(
        mockEntityManager as unknown as EntityManager,
        pago,
        mockPagoCobroRepo,
      );

      expect(result).toHaveLength(1);
      expect(cobro.montoPagado).toBe(0);
      expect(cobro.estado).toBe('PENDIENTE');
      expect(mockPagoCobroRepo.removeByPago).toHaveBeenCalledWith(
        mockEntityManager,
        'pago-1',
      );
    });
  });

  // ─── Legacy LIFO fallback ────────────────────────────

  describe('LIFO legacy fallback', () => {
    it('should lock cobros with pessimistic_write during LIFO reversal', async () => {
      const pago = crearPago(30000, 'pago-legacy');
      const cobroA = crearCobro('cobro-A', 50000, 40000);
      const cobroB = crearCobro('cobro-B', 50000, 20000);

      // LIFO order: DESC by periodoInicio → cobroB first, then cobroA
      findSpy.mockResolvedValue([cobroB, cobroA]);

      mockPagoCobroRepo.findByPago.mockResolvedValue([]);

      await revertirAbonos(
        mockEntityManager as unknown as EntityManager,
        pago,
        mockPagoCobroRepo,
      );

      expect(findSpy).toHaveBeenCalledWith({
        where: { residenteId: RESIDENTE_ID, tenantId: TENANT_ID },
        order: { periodoInicio: 'DESC' },
        lock: { mode: 'pessimistic_write' },
      });
    });

    it('should reverse LIFO correctly when no vinculos exist', async () => {
      const pago = crearPago(50000, 'pago-legacy');
      const cobroA = crearCobro('cobro-A', 50000, 40000);
      const cobroB = crearCobro('cobro-B', 50000, 20000);

      findSpy.mockResolvedValue([cobroB, cobroA]);

      mockPagoCobroRepo.findByPago.mockResolvedValue([]);

      const result = await revertirAbonos(
        mockEntityManager as unknown as EntityManager,
        pago,
        mockPagoCobroRepo,
      );

      // LIFO: B first (20000), then A (30000 of 40000)
      expect(cobroB.montoPagado).toBe(0);
      expect(cobroA.montoPagado).toBe(10000);
      expect(result).toHaveLength(2);
      expect(mockPagoCobroRepo.removeByPago).not.toHaveBeenCalled();
    });
  });
});
