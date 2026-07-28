import { PlanDeCobro } from './plan-de-cobro.entity';

describe('PlanDeCobro Entity — Domain Logic', () => {
  const CASA_ID = 'casa-1';
  const RESIDENTE_ID = 'residente-1';
  const TENANT_ID = 'tenant-1';
  const PROYECTO_ID = 'proyecto-1';

  // ═══════════════════════════════════════════════════════════
  // crear()
  // ═══════════════════════════════════════════════════════════

  describe('crear()', () => {
    it('should create a plan with all required fields', () => {
      const plan = PlanDeCobro.crear(
        CASA_ID,
        RESIDENTE_ID,
        TENANT_ID,
        PROYECTO_ID,
        'MENSUAL',
        '2026-01-01',
      );

      expect(plan.casaId).toBe(CASA_ID);
      expect(plan.residenteId).toBe(RESIDENTE_ID);
      expect(plan.tenantId).toBe(TENANT_ID);
      expect(plan.proyectoId).toBe(PROYECTO_ID);
      expect(plan.modalidad).toBe('MENSUAL');
      expect(plan.fechaActivacion).toBe('2026-01-01');
      expect(plan.activa).toBe(true);
      expect(plan.valorMensual).toBeNull();
      expect(plan.periodos).toEqual([]);
    });

    it('should accept optional valorMensual', () => {
      const plan = PlanDeCobro.crear(
        CASA_ID,
        RESIDENTE_ID,
        TENANT_ID,
        PROYECTO_ID,
        'MENSUAL',
        '2026-01-01',
        5000000, // valorMensual en centavos
      );

      expect(plan.valorMensual).toBe(5000000);
    });

    it('should accept null casaId', () => {
      const plan = PlanDeCobro.crear(
        null,
        RESIDENTE_ID,
        TENANT_ID,
        PROYECTO_ID,
        'MENSUAL',
        '2026-01-01',
      );

      expect(plan.casaId).toBeNull();
    });
  });

  // ═══════════════════════════════════════════════════════════
  // cambiarModalidad()
  // ═══════════════════════════════════════════════════════════

  describe('cambiarModalidad()', () => {
    it('should change modalidad to SEMANAL', () => {
      const plan = crearPlanBase();
      plan.cambiarModalidad('SEMANAL');
      expect(plan.modalidad).toBe('SEMANAL');
    });

    it('should change modalidad to QUINCENAL', () => {
      const plan = crearPlanBase();
      plan.cambiarModalidad('QUINCENAL');
      expect(plan.modalidad).toBe('QUINCENAL');
    });

    it('should change modalidad to MENSUAL', () => {
      const plan = crearPlanBase({ modalidad: 'SEMANAL' });
      plan.cambiarModalidad('MENSUAL');
      expect(plan.modalidad).toBe('MENSUAL');
    });
  });

  // ═══════════════════════════════════════════════════════════
  // desactivar()
  // ═══════════════════════════════════════════════════════════

  describe('desactivar()', () => {
    it('should set activa to false', () => {
      const plan = crearPlanBase();
      expect(plan.activa).toBe(true);

      plan.desactivar();
      expect(plan.activa).toBe(false);
    });

    it('should stay false if called twice', () => {
      const plan = crearPlanBase();
      plan.desactivar();
      plan.desactivar();
      expect(plan.activa).toBe(false);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // Edge cases — modalidad combinations
  // ═══════════════════════════════════════════════════════════

  describe('modalidad edge cases', () => {
    it('should accept all 3 modalidad values on creation', () => {
      const mensual = crearPlanBase({ modalidad: 'MENSUAL' as const });
      expect(mensual.modalidad).toBe('MENSUAL');

      const quincenal = crearPlanBase({ modalidad: 'QUINCENAL' as const });
      expect(quincenal.modalidad).toBe('QUINCENAL');

      const semanal = crearPlanBase({ modalidad: 'SEMANAL' as const });
      expect(semanal.modalidad).toBe('SEMANAL');
    });
  });

  /** Helper to create a plan with default values */
  function crearPlanBase(overrides: Partial<PlanDeCobro> = {}): PlanDeCobro {
    const plan = PlanDeCobro.crear(
      CASA_ID,
      RESIDENTE_ID,
      TENANT_ID,
      PROYECTO_ID,
      'MENSUAL',
      '2026-01-01',
    );
    Object.assign(plan, overrides);
    return plan;
  }
});
