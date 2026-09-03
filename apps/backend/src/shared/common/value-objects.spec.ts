import { Periodo } from './value-objects';

describe('Periodo Value Object', () => {
  describe('fechasCobroParciales (SEMANAL)', () => {
    it('debe devolver exactamente 4 sábados para un mes con 5 sábados (Sábado el día 3)', () => {
      // Enero 2026 tiene 5 sábados: 3, 10, 17, 24, 31
      const fechas = Periodo.fechasCobroParciales('SEMANAL', 2026, 0); // Mes 0 = Enero
      expect(fechas.length).toBe(4);
      // El día 3 es > 2, por lo que descarta el último (31)
      expect(fechas).toEqual([
        '2026-01-03',
        '2026-01-10',
        '2026-01-17',
        '2026-01-24',
      ]);
    });

    it('debe devolver exactamente 4 sábados para un mes con 5 sábados que inicia en sábado', () => {
      // Agosto 2026: 1 es Sábado. Sábados: 1, 8, 15, 22, 29
      const fechas = Periodo.fechasCobroParciales('SEMANAL', 2026, 7); // Mes 7 = Agosto
      expect(fechas.length).toBe(4);
      // El día 1 <= 2, por lo que descarta el primero (1)
      expect(fechas).toEqual([
        '2026-08-08',
        '2026-08-15',
        '2026-08-22',
        '2026-08-29',
      ]);
    });

    it('debe devolver exactamente 4 sábados para un mes con 4 sábados exactos', () => {
      // Febrero 2026: 1 es Domingo. Sábados: 7, 14, 21, 28
      const fechas = Periodo.fechasCobroParciales('SEMANAL', 2026, 1); // Mes 1 = Febrero
      expect(fechas.length).toBe(4);
      expect(fechas).toEqual([
        '2026-02-07',
        '2026-02-14',
        '2026-02-21',
        '2026-02-28',
      ]);
    });
  });

  describe('calcularCuotaProrrateada', () => {
    it('debe cobrar todo si se registra antes del primer pago (SEMANAL)', () => {
      const fechaRegistro = new Date(2026, 1, 1); // 1 de Febrero 2026
      const cuota = Periodo.calcularCuotaProrrateada(
        fechaRegistro,
        'SEMANAL',
        40000,
      );
      expect(cuota).toBe(40000); // 4 pagos restantes (7, 14, 21, 28)
    });

    it('debe cobrar proporcional si se registra en el tercer pago (SEMANAL)', () => {
      const fechaRegistro = new Date(2026, 1, 17); // 17 de Febrero 2026
      const cuota = Periodo.calcularCuotaProrrateada(
        fechaRegistro,
        'SEMANAL',
        40000,
      );
      // Quedan el 21 y el 28 (2 pagos restantes). Total 4. (40000 / 4) * 2 = 20000
      expect(cuota).toBe(20000);
    });

    it('debe cobrar proporcional si se registra a mitad de mes (QUINCENAL)', () => {
      const fechaRegistro = new Date(2026, 1, 17); // 17 de Febrero 2026
      const cuota = Periodo.calcularCuotaProrrateada(
        fechaRegistro,
        'QUINCENAL',
        40000,
      );
      // Febrero quincenas: aprox 14 y 28. Si se registra el 17, queda la del 28 (1 pago).
      expect(cuota).toBe(20000);
    });
  });
});
