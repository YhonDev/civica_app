import { Test, TestingModule } from '@nestjs/testing';
import { DashboardQuery } from './dashboard.query';
import { PagoRepository } from '../../infrastructure/persistence/pago.repository';
import { CuotaRepository } from '../../infrastructure/persistence/cuota.repository';
import { ActividadRepository } from '../../../notifications/domain/actividad.repository';
import { SolicitudRepository } from '../../infrastructure/persistence/solicitud.repository';
import { PropietarioRepository } from '../../../community/infrastructure/propietario.repository';

describe('DashboardQuery', () => {
  let query: DashboardQuery;

  const mockPagoRepo = {
    sumMontoByMonth: jest.fn(),
    countDistinctPropietariosByMonth: jest.fn(),
    groupByDayByMonth: jest.fn(),
    groupByWeekInMonth: jest.fn(),
    sumMontoByYear: jest.fn(),
  };

  const mockCuotaRepo = {
    sumMontoByMonth: jest.fn(),
    countPendientesByMonth: jest.fn(),
    sumSaldoVencidasByTenant: jest.fn(),
    groupByTarifaFrecuencia: jest.fn(),
    countByEstadoInMonth: jest.fn(),
    countPropietariosInMora: jest.fn(),
    sumMontoByYear: jest.fn(),
    countPendientesByWeek: jest.fn(),
    sumSaldoVencidasByMonth: jest.fn(),
  };

  const mockActividadRepo = {
    findByTenant: jest.fn(),
  };

  const mockSolicitudRepo = {
    findPendingByTenant: jest.fn(),
  };

  const mockPropietarioRepo = {
    countNuevosByWeek: jest.fn(),
    countByTenant: jest.fn(),
  };

  const TENANT = 'tenant-1';
  const MES = 6;
  const ANIO = 2026;

  /** Setup common mocks for happy-path data. Call AFTER clearAllMocks. */
  function setupHappyPathMocks() {
    // ── Main Promise.all (16 calls) ──
    mockPagoRepo.sumMontoByMonth.mockResolvedValue(50000); // recaudoTotal
    mockCuotaRepo.sumMontoByMonth.mockResolvedValue(100000); // metaMensual
    mockPagoRepo.countDistinctPropietariosByMonth.mockResolvedValue(45);
    mockCuotaRepo.countPendientesByMonth
      .mockResolvedValueOnce(12) // main: pendientes
      .mockResolvedValue(8); // historial: 12 calls
    mockCuotaRepo.sumSaldoVencidasByTenant.mockResolvedValue(8000);
    mockPagoRepo.groupByDayByMonth.mockResolvedValue([
      { dia: 1, valor: 5000 },
      { dia: 5, valor: 12000 },
      { dia: 15, valor: 8000 },
    ]);
    mockCuotaRepo.groupByTarifaFrecuencia.mockResolvedValue([
      { frecuencia: 'MENSUAL', totalCuotas: 50, pagadas: 35 },
      { frecuencia: 'QUINCENAL', totalCuotas: 20, pagadas: 15 },
    ]);
    mockCuotaRepo.countByEstadoInMonth.mockResolvedValue({
      pagadas: 35,
      pendientes: 25,
    });
    mockActividadRepo.findByTenant.mockResolvedValue([
      {
        id: 'act-1',
        tipo: 'PAGO_REGISTRADO',
        descripcion: 'Pago de cuota mensual',
        usuarioNombre: 'Juan Perez',
        createdAt: new Date('2026-06-15T10:30:00Z'),
      },
    ]);
    mockSolicitudRepo.findPendingByTenant.mockResolvedValue([
      { id: 's1' },
      { id: 's2' },
    ]);
    mockPropietarioRepo.countNuevosByWeek.mockResolvedValue(3);
    mockCuotaRepo.countPropietariosInMora.mockResolvedValue(5);
    mockPagoRepo.sumMontoByYear.mockResolvedValue(300000);
    mockCuotaRepo.sumMontoByYear.mockResolvedValue(600000);
    mockPagoRepo.groupByWeekInMonth.mockResolvedValue([
      { semana: 1, pagados: 10, monto: 15000 },
      { semana: 3, pagados: 8, monto: 12000 },
    ]);
    mockCuotaRepo.countPendientesByWeek.mockResolvedValue([
      { semana: 2, pendientes: 5, enMora: 2 },
      { semana: 3, pendientes: 3, enMora: 1 },
    ]);
    mockPropietarioRepo.countByTenant.mockResolvedValue(100);
    // ── Historial (12 calls each) ──
    mockCuotaRepo.sumSaldoVencidasByMonth.mockResolvedValue(3000);
    // pagoRepo.sumMontoByMonth already returns 50000 for all calls (main + historial)
  }

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DashboardQuery,
        { provide: PagoRepository, useValue: mockPagoRepo },
        { provide: CuotaRepository, useValue: mockCuotaRepo },
        { provide: ActividadRepository, useValue: mockActividadRepo },
        { provide: SolicitudRepository, useValue: mockSolicitudRepo },
        { provide: PropietarioRepository, useValue: mockPropietarioRepo },
      ],
    }).compile();

    query = module.get<DashboardQuery>(DashboardQuery);
  });

  // ────────────────────────────────────────────
  // 1. Happy path
  // ────────────────────────────────────────────
  describe('Happy path — todos los repos devuelven data', () => {
    beforeEach(() => setupHappyPathMocks());

    it('should return all DashboardResponse fields', async () => {
      const result = await query.execute(MES, ANIO, TENANT);

      expect(result).toMatchObject({
        mes: MES,
        anio: ANIO,
        resumen: expect.objectContaining({
          recaudoTotal: expect.any(Number),
          metaMensual: expect.any(Number),
          porcentajeMeta: expect.any(Number),
          pagaron: expect.any(Number),
          pendientes: expect.any(Number),
          moraTotal: expect.any(Number),
        }),
        evolucion: expect.any(Array),
        modalidades: expect.any(Array),
        estadoCobros: expect.objectContaining({
          pagados: expect.any(Number),
          pendientes: expect.any(Number),
          revision: 0,
        }),
        actividad: expect.any(Array),
        solicitudesPendientes: expect.any(Number),
        nuevosPropietariosSemana: expect.any(Number),
        propietariosMora: expect.any(Number),
        acumuladoAnual: expect.any(Number),
        metaAnual: expect.any(Number),
        historialMeses: expect.any(Array),
        cobrosPorSemana: expect.any(Array),
      });
    });

    it('should map evolucion with dia and valor keys (not monto)', async () => {
      const result = await query.execute(MES, ANIO, TENANT);

      expect(result.evolucion).toEqual([
        { dia: '1', valor: 5000 },
        { dia: '5', valor: 12000 },
        { dia: '15', valor: 8000 },
      ]);
      // Regression: key must be "valor", never "monto"
      for (const item of result.evolucion) {
        expect(item).toHaveProperty('valor');
        expect(item).not.toHaveProperty('monto');
      }
    });

    it('should merge cobrosPorSemana from pagos + cuotas by semana', async () => {
      const result = await query.execute(MES, ANIO, TENANT);

      // pagos: week 1 (pagados:10), week 3 (pagados:8)
      // cuotas: week 2 (pendientes:5, enMora:2), week 3 (pendientes:3, enMora:1)
      expect(result.cobrosPorSemana).toEqual([
        { semana: 1, pagados: 10, pendientes: 0, mora: 0 },
        { semana: 2, pagados: 0, pendientes: 5, mora: 2 },
        { semana: 3, pagados: 8, pendientes: 3, mora: 1 },
      ]);
    });

    it('should calculate modalidades with porcentaje and montoRecaudo', async () => {
      const result = await query.execute(MES, ANIO, TENANT);

      // MENSUAL: 35/50 = 70%  →  montoRecaudo = round((70/100) * 50000) = 35000
      expect(result.modalidades[0]).toEqual({
        frecuencia: 'MENSUAL',
        totalCuotas: 50,
        pagadas: 35,
        porcentaje: 70,
        montoRecaudo: 35000,
      });

      // QUINCENAL: 15/20 = 75%  →  montoRecaudo = round((75/100) * 50000) = 37500
      expect(result.modalidades[1]).toEqual({
        frecuencia: 'QUINCENAL',
        totalCuotas: 20,
        pagadas: 15,
        porcentaje: 75,
        montoRecaudo: 37500,
      });
    });

    it('should calculate porcentajeMeta correctly', async () => {
      const result = await query.execute(MES, ANIO, TENANT);

      // recaudoTotal=50000, metaMensual=100000 → 50%
      expect(result.resumen.porcentajeMeta).toBe(50);
      expect(result.resumen.recaudoTotal).toBe(50000);
      expect(result.resumen.metaMensual).toBe(100000);
    });

    it('should calculate estadoCobros percentages', async () => {
      const result = await query.execute(MES, ANIO, TENANT);

      // pagadas=35, pendientes=25, total=60
      // pagados% = round((35/60)*10000)/100 = 58.33
      // pendientes% = round((25/60)*10000)/100 = 41.67
      expect(result.estadoCobros.pagados).toBe(58.33);
      expect(result.estadoCobros.pendientes).toBe(41.67);
      expect(result.estadoCobros.revision).toBe(0);
    });

    it('should build historialMeses with 12 entries going backwards', async () => {
      const result = await query.execute(MES, ANIO, TENANT);

      expect(result.historialMeses).toHaveLength(12);

      // First entry = current month (countPendientesByMonth returns 8 for historial calls;
      // the mockResolvedValueOnce(12) was consumed by the main resumen.pendientes call)
      expect(result.historialMeses[0]).toEqual({
        mes: 6,
        anio: 2026,
        recaudo: 50000,
        pendientes: 8,
        mora: 3000,
      });

      // Month rolls from 1 → 12 and year decrements
      expect(result.historialMeses[6]).toEqual({
        mes: 12,
        anio: 2025,
        recaudo: 50000,
        pendientes: 8,
        mora: 3000,
      });

      // Last entry = 11 months before current
      expect(result.historialMeses[11]).toEqual({
        mes: 7,
        anio: 2025,
        recaudo: 50000,
        pendientes: 8,
        mora: 3000,
      });
    });

    it('should map actividad items with usuario and timestamp', async () => {
      const result = await query.execute(MES, ANIO, TENANT);

      expect(result.actividad).toHaveLength(1);
      expect(result.actividad[0]).toEqual({
        id: 'act-1',
        tipo: 'PAGO_REGISTRADO',
        descripcion: 'Pago de cuota mensual',
        usuario: 'Juan Perez',
        timestamp: '2026-06-15T10:30:00.000Z',
        hace: expect.any(String),
      });
    });

    it('should count solicitudesPendientes', async () => {
      const result = await query.execute(MES, ANIO, TENANT);
      expect(result.solicitudesPendientes).toBe(2);
    });

    it('should pass through scalar resumen fields', async () => {
      const result = await query.execute(MES, ANIO, TENANT);

      expect(result.resumen.pagaron).toBe(45);
      expect(result.resumen.pendientes).toBe(12);
      expect(result.resumen.moraTotal).toBe(8000);
      expect(result.nuevosPropietariosSemana).toBe(3);
      expect(result.propietariosMora).toBe(5);
      expect(result.acumuladoAnual).toBe(300000);
      expect(result.metaAnual).toBe(600000);
    });
  });

  // ────────────────────────────────────────────
  // 2. Meta cero — no division by zero
  // ────────────────────────────────────────────
  describe('Meta cero', () => {
    it('should return porcentajeMeta = 0 when metaMensual is 0', async () => {
      setupHappyPathMocks();
      mockCuotaRepo.sumMontoByMonth.mockResolvedValue(0); // override metaMensual

      const result = await query.execute(MES, ANIO, TENANT);

      expect(result.resumen.metaMensual).toBe(0);
      expect(result.resumen.porcentajeMeta).toBe(0);
    });

    it('should return porcentajeMeta = 0 when both recaudo and meta are 0', async () => {
      setupHappyPathMocks();
      mockPagoRepo.sumMontoByMonth.mockResolvedValue(0);
      mockCuotaRepo.sumMontoByMonth.mockResolvedValue(0);

      const result = await query.execute(MES, ANIO, TENANT);

      expect(result.resumen.recaudoTotal).toBe(0);
      expect(result.resumen.metaMensual).toBe(0);
      expect(result.resumen.porcentajeMeta).toBe(0);
    });
  });

  // ────────────────────────────────────────────
  // 3. Semana merge con huecos
  // ────────────────────────────────────────────
  describe('Semana merge con huecos', () => {
    it('should merge weeks [1,3] from pagos and [2,3] from cuotas into [1,2,3]', async () => {
      setupHappyPathMocks();
      mockPagoRepo.groupByWeekInMonth.mockResolvedValue([
        { semana: 1, pagados: 5, monto: 7000 },
        { semana: 3, pagados: 3, monto: 4000 },
      ]);
      mockCuotaRepo.countPendientesByWeek.mockResolvedValue([
        { semana: 2, pendientes: 2, enMora: 1 },
        { semana: 3, pendientes: 1, enMora: 0 },
      ]);

      const result = await query.execute(MES, ANIO, TENANT);

      expect(result.cobrosPorSemana).toHaveLength(3);
      expect(result.cobrosPorSemana).toEqual([
        { semana: 1, pagados: 5, pendientes: 0, mora: 0 },
        { semana: 2, pagados: 0, pendientes: 2, mora: 1 },
        { semana: 3, pagados: 3, pendientes: 1, mora: 0 },
      ]);
    });

    it('should handle pagos with no overlapping weeks with cuotas', async () => {
      setupHappyPathMocks();
      mockPagoRepo.groupByWeekInMonth.mockResolvedValue([
        { semana: 1, pagados: 10, monto: 15000 },
      ]);
      mockCuotaRepo.countPendientesByWeek.mockResolvedValue([
        { semana: 4, pendientes: 7, enMora: 3 },
      ]);

      const result = await query.execute(MES, ANIO, TENANT);

      expect(result.cobrosPorSemana).toEqual([
        { semana: 1, pagados: 10, pendientes: 0, mora: 0 },
        { semana: 4, pagados: 0, pendientes: 7, mora: 3 },
      ]);
    });

    it('should sort weeks in ascending order', async () => {
      setupHappyPathMocks();
      // Return out of order — merge logic sorts them
      mockPagoRepo.groupByWeekInMonth.mockResolvedValue([
        { semana: 5, pagados: 2, monto: 3000 },
        { semana: 1, pagados: 4, monto: 6000 },
      ]);
      mockCuotaRepo.countPendientesByWeek.mockResolvedValue([
        { semana: 3, pendientes: 1, enMora: 0 },
      ]);

      const result = await query.execute(MES, ANIO, TENANT);

      expect(result.cobrosPorSemana.map((s) => s.semana)).toEqual([1, 3, 5]);
    });
  });

  // ────────────────────────────────────────────
  // 4. Sin data — defaults sin errores
  // ────────────────────────────────────────────
  describe('Sin data — todos los repos devuelven 0 / []', () => {
    beforeEach(() => {
      mockPagoRepo.sumMontoByMonth.mockResolvedValue(0);
      mockCuotaRepo.sumMontoByMonth.mockResolvedValue(0);
      mockPagoRepo.countDistinctPropietariosByMonth.mockResolvedValue(0);
      mockCuotaRepo.countPendientesByMonth.mockResolvedValue(0);
      mockCuotaRepo.sumSaldoVencidasByTenant.mockResolvedValue(0);
      mockPagoRepo.groupByDayByMonth.mockResolvedValue([]);
      mockCuotaRepo.groupByTarifaFrecuencia.mockResolvedValue([]);
      mockCuotaRepo.countByEstadoInMonth.mockResolvedValue({
        pagadas: 0,
        pendientes: 0,
      });
      mockActividadRepo.findByTenant.mockResolvedValue([]);
      mockSolicitudRepo.findPendingByTenant.mockResolvedValue([]);
      mockPropietarioRepo.countNuevosByWeek.mockResolvedValue(0);
      mockCuotaRepo.countPropietariosInMora.mockResolvedValue(0);
      mockPagoRepo.sumMontoByYear.mockResolvedValue(0);
      mockCuotaRepo.sumMontoByYear.mockResolvedValue(0);
      mockPagoRepo.groupByWeekInMonth.mockResolvedValue([]);
      mockCuotaRepo.countPendientesByWeek.mockResolvedValue([]);
      mockCuotaRepo.sumSaldoVencidasByMonth.mockResolvedValue(0);
    });

    it('should not throw when all repos return empty/zero', async () => {
      await expect(
        query.execute(MES, ANIO, TENANT),
      ).resolves.toBeDefined();
    });

    it('should return zeroed resumen', async () => {
      const result = await query.execute(MES, ANIO, TENANT);

      expect(result.resumen).toEqual({
        recaudoTotal: 0,
        metaMensual: 0,
        porcentajeMeta: 0,
        pagaron: 0,
        pendientes: 0,
        moraTotal: 0,
      });
    });

    it('should return empty arrays for collection fields', async () => {
      const result = await query.execute(MES, ANIO, TENANT);

      expect(result.evolucion).toEqual([]);
      expect(result.modalidades).toEqual([]);
      expect(result.actividad).toEqual([]);
      expect(result.historialMeses).toHaveLength(12);
      expect(result.cobrosPorSemana).toEqual([]);
    });

    it('should return zero for estadoCobros (no division by zero)', async () => {
      const result = await query.execute(MES, ANIO, TENANT);

      expect(result.estadoCobros).toEqual({
        pagados: 0,
        pendientes: 0,
        revision: 0,
      });
    });

    it('should return 0 for solicitudesPendientes', async () => {
      const result = await query.execute(MES, ANIO, TENANT);
      expect(result.solicitudesPendientes).toBe(0);
    });
  });

  // ────────────────────────────────────────────
  // 5. Evolución key — valor, no monto
  // ────────────────────────────────────────────
  describe('Evolución key — regression bug: valor vs monto', () => {
    it('should use "valor" key from groupByDayByMonth output', async () => {
      setupHappyPathMocks();
      // Simulate what groupByDayByMonth actually returns
      mockPagoRepo.groupByDayByMonth.mockResolvedValue([
        { dia: 3, valor: 2500 },
        { dia: 10, valor: 7800 },
      ]);

      const result = await query.execute(MES, ANIO, TENANT);

      // Each item MUST have "dia" and "valor", NEVER "monto"
      for (const item of result.evolucion) {
        expect(Object.keys(item)).toEqual(
          expect.arrayContaining(['dia', 'valor']),
        );
        expect(Object.keys(item)).not.toContain('monto');
      }
    });

    it('should preserve numeric values through the mapping', async () => {
      setupHappyPathMocks();
      mockPagoRepo.groupByDayByMonth.mockResolvedValue([
        { dia: 1, valor: 9999.5 },
      ]);

      const result = await query.execute(MES, ANIO, TENANT);

      expect(result.evolucion[0]).toEqual({ dia: '1', valor: 9999.5 });
    });
  });

  // ────────────────────────────────────────────
  // 6. Modalidad edge cases
  // ────────────────────────────────────────────
  describe('Modalidades edge cases', () => {
    it('should handle totalCuotas = 0 without division by zero', async () => {
      setupHappyPathMocks();
      mockCuotaRepo.groupByTarifaFrecuencia.mockResolvedValue([
        { frecuencia: 'ANUAL', totalCuotas: 0, pagadas: 0 },
      ]);

      const result = await query.execute(MES, ANIO, TENANT);

      expect(result.modalidades[0]).toEqual({
        frecuencia: 'ANUAL',
        totalCuotas: 0,
        pagadas: 0,
        porcentaje: 0,
        montoRecaudo: 0,
      });
    });

    it('should handle 100% pagadas', async () => {
      setupHappyPathMocks();
      mockCuotaRepo.groupByTarifaFrecuencia.mockResolvedValue([
        { frecuencia: 'MENSUAL', totalCuotas: 20, pagadas: 20 },
      ]);

      const result = await query.execute(MES, ANIO, TENANT);

      // 20/20 = 100%, montoRecaudo = round((100/100) * 50000) = 50000
      expect(result.modalidades[0].porcentaje).toBe(100);
      expect(result.modalidades[0].montoRecaudo).toBe(50000);
    });
  });
});
