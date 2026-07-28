import { Cobro } from './cobro.entity';
import { Money } from '../../shared/common/value-objects';

describe('Cobro Entity — Domain Logic', () => {
  const RESIDENTE_ID = 'residente-1';
  const TENANT_ID = 'tenant-1';

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

  // ═══════════════════════════════════════════════════════════
  // crear()
  // ═══════════════════════════════════════════════════════════

  describe('crear()', () => {
    it('should create a cobro with PENDIENTE state', () => {
      const cobro = crearCobro(40000);

      expect(cobro.estado).toBe('PENDIENTE');
      expect(cobro.monto).toBe(40000);
      expect(cobro.montoPagado).toBe(0);
      expect(cobro.residenteId).toBe(RESIDENTE_ID);
      expect(cobro.tenantId).toBe(TENANT_ID);
      expect(cobro.concepto).toBe('Cuota Test');
      expect(cobro.notificacionEnviada).toBe(false);
    });

    it('should accept optional tarifaId, periodoId, casaId', () => {
      const cobro = Cobro.crear(
        RESIDENTE_ID, TENANT_ID, 'Cuota Test',
        Money.ofCOP(40000), '2026-01-01', '2026-02-01', '2026-01-15',
        'tarifa-1', 'periodo-1', 'casa-1',
      );

      expect(cobro.tarifaId).toBe('tarifa-1');
      expect(cobro.periodoId).toBe('periodo-1');
      expect(cobro.casaId).toBe('casa-1');
    });

    it('should set optional IDs to null when not provided', () => {
      const cobro = crearCobro(40000);

      expect(cobro.tarifaId).toBeNull();
      expect(cobro.periodoId).toBeNull();
      expect(cobro.casaId).toBeNull();
    });
  });

  // ═══════════════════════════════════════════════════════════
  // getMonto(), getMontoPagado(), saldo()
  // ═══════════════════════════════════════════════════════════

  describe('getMonto / getMontoPagado / saldo', () => {
    it('should return Money objects', () => {
      const cobro = crearCobro(40000);

      expect(cobro.getMonto().amount).toBe(40000);
      expect(cobro.getMontoPagado().amount).toBe(0);
      expect(cobro.saldo().amount).toBe(40000);
    });

    it('saldo should reflect montoPagado', () => {
      const cobro = crearCobro(50000, { montoPagado: 15000 });

      expect(cobro.saldo().amount).toBe(35000);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // aplicarPago()
  // ═══════════════════════════════════════════════════════════

  describe('aplicarPago()', () => {
    it('should set PARCIAL when payment is less than saldo', () => {
      const cobro = crearCobro(40000);
      const excess = cobro.aplicarPago(Money.ofCOP(15000));

      expect(cobro.estado).toBe('PARCIAL');
      expect(cobro.montoPagado).toBe(15000);
      expect(excess.amount).toBe(0);
    });

    it('should set PAGADA when payment equals saldo', () => {
      const cobro = crearCobro(40000);
      const excess = cobro.aplicarPago(Money.ofCOP(40000));

      expect(cobro.estado).toBe('PAGADA');
      expect(cobro.montoPagado).toBe(40000);
      expect(excess.amount).toBe(0);
    });

    it('should return excess when payment exceeds saldo', () => {
      const cobro = crearCobro(40000);
      const excess = cobro.aplicarPago(Money.ofCOP(50000));

      expect(cobro.estado).toBe('PAGADA');
      expect(cobro.montoPagado).toBe(40000);
      expect(excess.amount).toBe(10000);
    });

    it('should throw when trying to pay an already PAGADA cobro', () => {
      const cobro = crearCobro(40000, { estado: 'PAGADA', montoPagado: 40000 });

      expect(() => cobro.aplicarPago(Money.ofCOP(10000))).toThrow(
        /No se puede pagar un cobro ya PAGADO/,
      );
    });

    it('should handle partial payment after previous partial', () => {
      const cobro = crearCobro(40000);
      cobro.aplicarPago(Money.ofCOP(15000)); // PARCIAL, 15000 pagados
      expect(cobro.estado).toBe('PARCIAL');

      const excess = cobro.aplicarPago(Money.ofCOP(25000)); // completes it
      expect(cobro.estado).toBe('PAGADA');
      expect(cobro.montoPagado).toBe(40000);
      expect(excess.amount).toBe(0);
    });

    it('should handle excess on second partial payment', () => {
      const cobro = crearCobro(40000);
      cobro.aplicarPago(Money.ofCOP(10000)); // PARCIAL, 10k pagados
      const excess = cobro.aplicarPago(Money.ofCOP(35000)); // 30k needed + 5k excess

      expect(cobro.estado).toBe('PAGADA');
      expect(cobro.montoPagado).toBe(40000);
      expect(excess.amount).toBe(5000);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // marcarVencida()
  // ═══════════════════════════════════════════════════════════

  describe('marcarVencida()', () => {
    it('should mark PENDIENTE as VENCIDA', () => {
      const cobro = crearCobro(40000);
      cobro.marcarVencida();
      expect(cobro.estado).toBe('VENCIDA');
    });

    it('should mark PARCIAL as VENCIDA', () => {
      const cobro = crearCobro(40000);
      cobro.aplicarPago(Money.ofCOP(10000));
      expect(cobro.estado).toBe('PARCIAL');

      cobro.marcarVencida();
      expect(cobro.estado).toBe('VENCIDA');
    });

    it('should NOT change PAGADA', () => {
      const cobro = crearCobro(40000, { estado: 'PAGADA', montoPagado: 40000 });
      cobro.marcarVencida();
      expect(cobro.estado).toBe('PAGADA');
    });
  });

  // ═══════════════════════════════════════════════════════════
  // Estado helpers
  // ═══════════════════════════════════════════════════════════

  describe('estaPagada / estaVencida / estaPendiente', () => {
    it('estaPagada should return true only when PAGADA', () => {
      expect(crearCobro(40000, { estado: 'PAGADA' }).estaPagada()).toBe(true);
      expect(crearCobro(40000, { estado: 'PENDIENTE' }).estaPagada()).toBe(false);
      expect(crearCobro(40000, { estado: 'VENCIDA' }).estaPagada()).toBe(false);
    });

    it('estaVencida should return true only when VENCIDA', () => {
      expect(crearCobro(40000, { estado: 'VENCIDA' }).estaVencida()).toBe(true);
      expect(crearCobro(40000, { estado: 'PENDIENTE' }).estaVencida()).toBe(false);
    });

    it('estaPendiente should return true only when PENDIENTE', () => {
      expect(crearCobro(40000, { estado: 'PENDIENTE' }).estaPendiente()).toBe(true);
      expect(crearCobro(40000, { estado: 'VENCIDA' }).estaPendiente()).toBe(false);
      expect(crearCobro(40000, { estado: 'PAGADA' }).estaPendiente()).toBe(false);
    });
  });
});
