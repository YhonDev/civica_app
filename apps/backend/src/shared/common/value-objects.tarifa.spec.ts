import {
  pagosPorMes,
  montoMensualDesde,
  tarifasDerivadas,
  calcularMontoParcial,
  CUOTA_MENSUAL_CIVICA_DEFAULT_CENTAVOS,
} from './value-objects';

describe('Tarifa derivación', () => {
  const CUOTA_MENSUAL = CUOTA_MENSUAL_CIVICA_DEFAULT_CENTAVOS;

  describe('pagosPorMes', () => {
    it('SEMANAL = 4 pagos por mes', () => {
      expect(pagosPorMes('SEMANAL')).toBe(4);
    });

    it('QUINCENAL = 2 pagos por mes', () => {
      expect(pagosPorMes('QUINCENAL')).toBe(2);
    });

    it('MENSUAL = 1 pago por mes', () => {
      expect(pagosPorMes('MENSUAL')).toBe(1);
    });
  });

  describe('tarifasDerivadas', () => {
    it('divide la cuota mensual en 4, 2 y 1', () => {
      const derivadas = tarifasDerivadas(CUOTA_MENSUAL);
      expect(derivadas.MENSUAL).toBe(4_000_000);
      expect(derivadas.QUINCENAL).toBe(2_000_000);
      expect(derivadas.SEMANAL).toBe(1_000_000);
    });

    it('redondea correctamente montos no divisibles', () => {
      const derivadas = tarifasDerivadas(4_500_000); // $45.000
      expect(derivadas.MENSUAL).toBe(4_500_000);
      expect(derivadas.QUINCENAL).toBe(2_250_000);
      expect(derivadas.SEMANAL).toBe(1_125_000);
    });
  });

  describe('montoMensualDesde', () => {
    it('convierte semanal a mensual (x4)', () => {
      expect(montoMensualDesde('SEMANAL', 1_000_000)).toBe(4_000_000);
    });

    it('convierte quincenal a mensual (x2)', () => {
      expect(montoMensualDesde('QUINCENAL', 2_000_000)).toBe(4_000_000);
    });
  });

  describe('calcularMontoParcial', () => {
    it('genera abono semanal = mensual / 4', () => {
      expect(calcularMontoParcial(CUOTA_MENSUAL, 'SEMANAL').amount).toBe(1_000_000);
    });

    it('genera abono quincenal = mensual / 2', () => {
      expect(calcularMontoParcial(CUOTA_MENSUAL, 'QUINCENAL').amount).toBe(2_000_000);
    });

    it('genera abono mensual completo', () => {
      expect(calcularMontoParcial(CUOTA_MENSUAL, 'MENSUAL').amount).toBe(4_000_000);
    });
  });
});
