import { Periodo } from './value-objects';

describe('Periodo', () => {
  describe('calcularCuotaMensual', () => {
    it('siempre genera período del día 1 al 1 del mes siguiente', () => {
      const periodo = Periodo.calcularCuotaMensual(new Date(2026, 7, 1));
      expect(periodo.inicioStr).toBe('2026-08-01');
      expect(periodo.finStr).toBe('2026-09-01');
      expect(periodo.vencimiento.getDay()).toBe(6);
    });
  });

  describe('fechasCobroParciales', () => {
    it('SEMANAL: un sábado por semana en el mes', () => {
      const fechas = Periodo.fechasCobroParciales('SEMANAL', 2026, 7);
      expect(fechas.length).toBeGreaterThanOrEqual(4);
      fechas.forEach((f) => {
        const [y, m, d] = f.split('-').map(Number);
        expect(new Date(y, m - 1, d).getDay()).toBe(6);
      });
    });

    it('QUINCENAL: 2 fechas de cobro', () => {
      const fechas = Periodo.fechasCobroParciales('QUINCENAL', 2026, 7);
      expect(fechas).toHaveLength(2);
    });

    it('MENSUAL: 1 fecha de cobro', () => {
      const fechas = Periodo.fechasCobroParciales('MENSUAL', 2026, 7);
      expect(fechas).toHaveLength(1);
    });
  });

  describe('calcularSiguiente MENSUAL', () => {
    it('vencimiento cae en sábado cercano al último día del mes', () => {
      const periodo = Periodo.calcularSiguiente(
        'MENSUAL',
        new Date(2026, 7, 1),
      );
      expect(periodo.inicioStr).toBe('2026-08-01');
      expect(periodo.finStr).toBe('2026-09-01');
      expect(periodo.vencimiento.getDay()).toBe(6);
      expect(periodo.vencimientoStr).toBe('2026-08-29');
    });
  });

  describe('calcularSiguiente QUINCENAL', () => {
    it('1ra quincena vence en sábado cercano al día 15', () => {
      const periodo = Periodo.calcularSiguiente(
        'QUINCENAL',
        new Date(2026, 7, 1),
      );
      expect(periodo.inicioStr).toBe('2026-08-01');
      expect(periodo.finStr).toBe('2026-08-16');
      expect(periodo.vencimiento.getDay()).toBe(6);
      expect(periodo.vencimientoStr).toBe('2026-08-15');
    });

    it('2da quincena vence en sábado cercano al último día', () => {
      const periodo = Periodo.calcularSiguiente(
        'QUINCENAL',
        new Date(2026, 7, 16),
      );
      expect(periodo.inicioStr).toBe('2026-08-16');
      expect(periodo.finStr).toBe('2026-09-01');
      expect(periodo.vencimiento.getDay()).toBe(6);
      expect(periodo.vencimientoStr).toBe('2026-08-29');
    });
  });

  describe('calcularSiguiente SEMANAL', () => {
    it('genera semana de lunes a sábado', () => {
      const periodo = Periodo.calcularSiguiente(
        'SEMANAL',
        new Date(2026, 7, 1),
      );
      expect(periodo.inicio.getDay()).toBe(1);
      expect(periodo.vencimiento.getDay()).toBe(6);
      expect(periodo.inicioStr).toBe('2026-08-03');
      expect(periodo.vencimientoStr).toBe('2026-08-08');
    });
  });

  describe('esVisible', () => {
    const julio = new Date(2026, 6, 10);

    it('muestra cuota del mes actual', () => {
      expect(Periodo.esVisible('2026-07-01', 'MENSUAL', julio)).toBe(true);
    });

    it('muestra próximo pago (mes siguiente)', () => {
      expect(Periodo.esVisible('2026-08-01', 'MENSUAL', julio)).toBe(true);
    });

    it('oculta cuotas de meses futuros', () => {
      expect(Periodo.esVisible('2026-09-01', 'MENSUAL', julio)).toBe(false);
    });
  });

  describe('limiteGeneracion', () => {
    it('MENSUAL: permite hasta el próximo mes', () => {
      const limite = Periodo.limiteGeneracion('MENSUAL', new Date(2026, 6, 10));
      expect(limite.getFullYear()).toBe(2026);
      expect(limite.getMonth()).toBe(7);
      expect(limite.getDate()).toBe(1);
    });
  });
});
