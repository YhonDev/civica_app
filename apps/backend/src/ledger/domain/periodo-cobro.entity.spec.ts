import { PeriodoCobro } from './periodo-cobro.entity';

describe('PeriodoCobro Entity — Domain Logic', () => {
  const PLAN_ID = 'plan-1';
  const TENANT_ID = 'tenant-1';

  // ═══════════════════════════════════════════════════════════
  // crear()
  // ═══════════════════════════════════════════════════════════

  describe('crear()', () => {
    it('should create a periodo with default ACTIVE state', () => {
      const periodo = PeriodoCobro.crear(
        PLAN_ID,
        7,        // mes
        2026,     // anio
        '2026-07-01',
        '2026-07-31',
        TENANT_ID,
      );

      expect(periodo.planId).toBe(PLAN_ID);
      expect(periodo.mes).toBe(7);
      expect(periodo.anio).toBe(2026);
      expect(periodo.fechaInicio).toBe('2026-07-01');
      expect(periodo.fechaFin).toBe('2026-07-31');
      expect(periodo.tenantId).toBe(TENANT_ID);
      expect(periodo.estado).toBe('ACTIVO');
      expect(periodo.cobros).toEqual([]);
    });

    it('should accept mes=1 (January)', () => {
      const periodo = PeriodoCobro.crear(
        PLAN_ID, 1, 2026,
        '2026-01-01', '2026-01-31', TENANT_ID,
      );
      expect(periodo.mes).toBe(1);
    });

    it('should accept mes=12 (December)', () => {
      const periodo = PeriodoCobro.crear(
        PLAN_ID, 12, 2026,
        '2026-12-01', '2026-12-31', TENANT_ID,
      );
      expect(periodo.mes).toBe(12);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // cerrar()
  // ═══════════════════════════════════════════════════════════

  describe('cerrar()', () => {
    it('should set estado to CERRADO', () => {
      const periodo = crearPeriodoBase();
      expect(periodo.estado).toBe('ACTIVO');

      periodo.cerrar();
      expect(periodo.estado).toBe('CERRADO');
    });

    it('should stay CERRADO if called twice', () => {
      const periodo = crearPeriodoBase();
      periodo.cerrar();
      periodo.cerrar();
      expect(periodo.estado).toBe('CERRADO');
    });
  });

  // ═══════════════════════════════════════════════════════════
  // estaActivo()
  // ═══════════════════════════════════════════════════════════

  describe('estaActivo()', () => {
    it('should return true when estado is ACTIVO', () => {
      const periodo = crearPeriodoBase();
      expect(periodo.estaActivo()).toBe(true);
    });

    it('should return false after cerrar()', () => {
      const periodo = crearPeriodoBase();
      periodo.cerrar();
      expect(periodo.estaActivo()).toBe(false);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // Edge cases — month/year combinations
  // ═══════════════════════════════════════════════════════════

  describe('month/year edge cases', () => {
    it('should handle year boundary (Dec 2026 → Jan 2027)', () => {
      const dic2026 = PeriodoCobro.crear(
        PLAN_ID, 12, 2026,
        '2026-12-01', '2026-12-31', TENANT_ID,
      );
      expect(dic2026.anio).toBe(2026);
      expect(dic2026.mes).toBe(12);

      const ene2027 = PeriodoCobro.crear(
        PLAN_ID, 1, 2027,
        '2027-01-01', '2027-01-31', TENANT_ID,
      );
      expect(ene2027.anio).toBe(2027);
      expect(ene2027.mes).toBe(1);
    });

    it('should handle February in non-leap year', () => {
      const feb = PeriodoCobro.crear(
        PLAN_ID, 2, 2026,
        '2026-02-01', '2026-02-28', TENANT_ID,
      );
      expect(feb.mes).toBe(2);
      expect(feb.fechaFin).toBe('2026-02-28');
    });
  });

  /** Helper to create a periodo with default values */
  function crearPeriodoBase(overrides: Partial<PeriodoCobro> = {}): PeriodoCobro {
    const periodo = PeriodoCobro.crear(
      PLAN_ID, 7, 2026,
      '2026-07-01', '2026-07-31', TENANT_ID,
    );
    Object.assign(periodo, overrides);
    return periodo;
  }
});
