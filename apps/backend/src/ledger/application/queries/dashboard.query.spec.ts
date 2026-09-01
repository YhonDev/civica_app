import { Test, TestingModule } from '@nestjs/testing';
import { DashboardQuery } from './dashboard.query';
import { PagoRepository } from '../../infrastructure/persistence/pago.repository';
import { CobroRepository } from '../../infrastructure/persistence/cobro.repository';
import { ActividadRepository } from '../../../notifications/domain/actividad.repository';
import { SolicitudRepository } from '../../infrastructure/persistence/solicitud.repository';
import { ResidenteRepository } from '../../../community/infrastructure/residente.repository';

describe('DashboardQuery', () => {
  let query: DashboardQuery;

  const mockPagoRepo = {
    sumMontoByMonth: jest.fn(),
    countDistinctResidentesByMonth: jest.fn(),
    groupByDayByMonth: jest.fn(),
    groupByWeekInMonth: jest.fn(),
    sumMontoByYear: jest.fn(),
  };

  const mockCobroRepo = {
    sumMontoByMonth: jest.fn(),
    countPendientesByMonth: jest.fn(),
    sumSaldoVencidasByTenant: jest.fn(),
    groupByTarifaModalidad: jest.fn(),
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

  const mockResidenteRepo = {
    countNuevosByWeek: jest.fn(),
    countByTenant: jest.fn(),
  };

  const TENANT = 'tenant-1';
  const MES = 6;
  const ANIO = 2026;

  /** Setup common mocks for happy-path data. Call AFTER clearAllMocks. */
  function setupHappyPathMocks() {
    // ── Main Promise.all (16 calls) ──
    mockPagoRepo.sumMontoByMonth.mockResolvedValue(50000);
    mockCobroRepo.sumMontoByMonth.mockResolvedValue(100000);
    mockPagoRepo.countDistinctResidentesByMonth.mockResolvedValue(45);
    mockCobroRepo.countPendientesByMonth
      .mockResolvedValueOnce(12)
      .mockResolvedValue(8);
    mockCobroRepo.sumSaldoVencidasByTenant.mockResolvedValue(8000);
    mockPagoRepo.groupByDayByMonth.mockResolvedValue([
      { dia: 1, valor: 5000 },
      { dia: 5, valor: 12000 },
      { dia: 15, valor: 8000 },
    ]);
    mockCobroRepo.groupByTarifaModalidad.mockResolvedValue([
      { modalidad: 'MENSUAL', totalCuotas: 50, pagadas: 35 },
      { modalidad: 'QUINCENAL', totalCuotas: 20, pagadas: 15 },
    ]);
    mockCobroRepo.countByEstadoInMonth.mockResolvedValue({
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
    mockResidenteRepo.countNuevosByWeek.mockResolvedValue(3);
    mockCobroRepo.countPropietariosInMora.mockResolvedValue(5);
    mockPagoRepo.sumMontoByYear.mockResolvedValue(300000);
    mockCobroRepo.sumMontoByYear.mockResolvedValue(600000);
    mockPagoRepo.groupByWeekInMonth.mockResolvedValue([
      { semana: 1, pagados: 10, monto: 15000 },
      { semana: 3, pagados: 8, monto: 12000 },
    ]);
    mockCobroRepo.countPendientesByWeek.mockResolvedValue([
      { semana: 2, pendientes: 5, enMora: 2 },
      { semana: 3, pendientes: 3, enMora: 1 },
    ]);
    mockResidenteRepo.countByTenant.mockResolvedValue(100);
    mockCobroRepo.sumSaldoVencidasByMonth.mockResolvedValue(3000);
  }

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DashboardQuery,
        { provide: PagoRepository, useValue: mockPagoRepo },
        { provide: CobroRepository, useValue: mockCobroRepo },
        { provide: ActividadRepository, useValue: mockActividadRepo },
        { provide: SolicitudRepository, useValue: mockSolicitudRepo },
        { provide: ResidenteRepository, useValue: mockResidenteRepo },
      ],
    }).compile();

    query = module.get<DashboardQuery>(DashboardQuery);
  });

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
        nuevosResidentesSemana: expect.any(Number),
        residentesMora: expect.any(Number),
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
      for (const item of result.evolucion) {
        expect(item).toHaveProperty('valor');
        expect(item).not.toHaveProperty('monto');
      }
    });

    it('should merge cobrosPorSemana from pagos + cobros by semana', async () => {
      const result = await query.execute(MES, ANIO, TENANT);

      expect(result.cobrosPorSemana).toEqual([
        { semana: 1, pagados: 10, pendientes: 0, mora: 0 },
        { semana: 2, pagados: 0, pendientes: 5, mora: 2 },
        { semana: 3, pagados: 8, pendientes: 3, mora: 1 },
      ]);
    });

    it('should calculate modalidades with porcentaje and montoRecaudo', async () => {
      const result = await query.execute(MES, ANIO, TENANT);

      expect(result.modalidades[0]).toEqual({
        modalidad: 'MENSUAL',
        totalCuotas: 50,
        pagadas: 35,
        porcentaje: 70,
        montoRecaudo: 35000,
      });

      expect(result.modalidades[1]).toEqual({
        modalidad: 'QUINCENAL',
        totalCuotas: 20,
        pagadas: 15,
        porcentaje: 75,
        montoRecaudo: 37500,
      });
    });

    it('should calculate porcentajeMeta correctly', async () => {
      const result = await query.execute(MES, ANIO, TENANT);

      expect(result.resumen.porcentajeMeta).toBe(50);
      expect(result.resumen.recaudoTotal).toBe(50000);
      expect(result.resumen.metaMensual).toBe(100000);
    });

    it('should calculate estadoCobros percentages', async () => {
      const result = await query.execute(MES, ANIO, TENANT);

      expect(result.estadoCobros.pagados).toBe(58.33);
      expect(result.estadoCobros.pendientes).toBe(41.67);
      expect(result.estadoCobros.revision).toBe(0);
    });

    it('should build historialMeses with 12 entries going backwards', async () => {
      const result = await query.execute(MES, ANIO, TENANT);

      expect(result.historialMeses).toHaveLength(12);
      expect(result.historialMeses[0]).toEqual({
        mes: 6,
        anio: 2026,
        recaudo: 50000,
        pendientes: 8,
        mora: 3000,
      });
      expect(result.historialMeses[6]).toEqual({
        mes: 12,
        anio: 2025,
        recaudo: 50000,
        pendientes: 8,
        mora: 3000,
      });
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
        metadata: {},
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
      expect(result.nuevosResidentesSemana).toBe(3);
      expect(result.residentesMora).toBe(5);
      expect(result.acumuladoAnual).toBe(300000);
      expect(result.metaAnual).toBe(600000);
    });
  });

  describe('Meta cero', () => {
    it('should return porcentajeMeta = 0 when metaMensual is 0', async () => {
      setupHappyPathMocks();
      mockCobroRepo.sumMontoByMonth.mockResolvedValue(0);

      const result = await query.execute(MES, ANIO, TENANT);

      expect(result.resumen.metaMensual).toBe(0);
      expect(result.resumen.porcentajeMeta).toBe(0);
    });

    it('should return porcentajeMeta = 0 when both recaudo and meta are 0', async () => {
      setupHappyPathMocks();
      mockPagoRepo.sumMontoByMonth.mockResolvedValue(0);
      mockCobroRepo.sumMontoByMonth.mockResolvedValue(0);

      const result = await query.execute(MES, ANIO, TENANT);

      expect(result.resumen.recaudoTotal).toBe(0);
      expect(result.resumen.metaMensual).toBe(0);
      expect(result.resumen.porcentajeMeta).toBe(0);
    });
  });

  describe('Semana merge con huecos', () => {
    it('should merge weeks [1,3] from pagos and [2,3] from cobros into [1,2,3]', async () => {
      setupHappyPathMocks();
      mockPagoRepo.groupByWeekInMonth.mockResolvedValue([
        { semana: 1, pagados: 5, monto: 7000 },
        { semana: 3, pagados: 3, monto: 4000 },
      ]);
      mockCobroRepo.countPendientesByWeek.mockResolvedValue([
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

    it('should handle pagos with no overlapping weeks with cobros', async () => {
      setupHappyPathMocks();
      mockPagoRepo.groupByWeekInMonth.mockResolvedValue([
        { semana: 1, pagados: 10, monto: 15000 },
      ]);
      mockCobroRepo.countPendientesByWeek.mockResolvedValue([
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
      mockPagoRepo.groupByWeekInMonth.mockResolvedValue([
        { semana: 5, pagados: 2, monto: 3000 },
        { semana: 1, pagados: 4, monto: 6000 },
      ]);
      mockCobroRepo.countPendientesByWeek.mockResolvedValue([
        { semana: 3, pendientes: 1, enMora: 0 },
      ]);

      const result = await query.execute(MES, ANIO, TENANT);

      expect(result.cobrosPorSemana.map((s) => s.semana)).toEqual([1, 3, 5]);
    });
  });

  describe('Sin data — todos los repos devuelven 0 / []', () => {
    beforeEach(() => {
      mockPagoRepo.sumMontoByMonth.mockResolvedValue(0);
      mockCobroRepo.sumMontoByMonth.mockResolvedValue(0);
      mockPagoRepo.countDistinctResidentesByMonth.mockResolvedValue(0);
      mockCobroRepo.countPendientesByMonth.mockResolvedValue(0);
      mockCobroRepo.sumSaldoVencidasByTenant.mockResolvedValue(0);
      mockPagoRepo.groupByDayByMonth.mockResolvedValue([]);
      mockCobroRepo.groupByTarifaModalidad.mockResolvedValue([]);
      mockCobroRepo.countByEstadoInMonth.mockResolvedValue({ pagadas: 0, pendientes: 0 });
      mockActividadRepo.findByTenant.mockResolvedValue([]);
      mockSolicitudRepo.findPendingByTenant.mockResolvedValue([]);
      mockResidenteRepo.countNuevosByWeek.mockResolvedValue(0);
      mockCobroRepo.countPropietariosInMora.mockResolvedValue(0);
      mockPagoRepo.sumMontoByYear.mockResolvedValue(0);
      mockCobroRepo.sumMontoByYear.mockResolvedValue(0);
      mockPagoRepo.groupByWeekInMonth.mockResolvedValue([]);
      mockCobroRepo.countPendientesByWeek.mockResolvedValue([]);
      mockCobroRepo.sumSaldoVencidasByMonth.mockResolvedValue(0);
    });

    it('should not throw when all repos return empty/zero', async () => {
      await expect(query.execute(MES, ANIO, TENANT)).resolves.toBeDefined();
    });

    it('should return zeroed resumen', async () => {
      const result = await query.execute(MES, ANIO, TENANT);
      expect(result.resumen).toEqual({
        recaudoTotal: 0, metaMensual: 0, porcentajeMeta: 0,
        pagaron: 0, pendientes: 0, moraTotal: 0,
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
      expect(result.estadoCobros).toEqual({ pagados: 0, pendientes: 0, revision: 0 });
    });

    it('should return 0 for solicitudesPendientes', async () => {
      const result = await query.execute(MES, ANIO, TENANT);
      expect(result.solicitudesPendientes).toBe(0);
    });
  });

  describe('Evolución key — regression bug: valor vs monto', () => {
    it('should use "valor" key from groupByDayByMonth output', async () => {
      setupHappyPathMocks();
      mockPagoRepo.groupByDayByMonth.mockResolvedValue([
        { dia: 3, valor: 2500 },
        { dia: 10, valor: 7800 },
      ]);

      const result = await query.execute(MES, ANIO, TENANT);

      for (const item of result.evolucion) {
        expect(Object.keys(item)).toEqual(expect.arrayContaining(['dia', 'valor']));
        expect(Object.keys(item)).not.toContain('monto');
      }
    });

    it('should preserve numeric values through the mapping', async () => {
      setupHappyPathMocks();
      mockPagoRepo.groupByDayByMonth.mockResolvedValue([{ dia: 1, valor: 9999.5 }]);
      const result = await query.execute(MES, ANIO, TENANT);
      expect(result.evolucion[0]).toEqual({ dia: '1', valor: 9999.5 });
    });
  });

  describe('Modalidades edge cases', () => {
    it('should handle totalCuotas = 0 without division by zero', async () => {
      setupHappyPathMocks();
    mockCobroRepo.groupByTarifaModalidad.mockResolvedValue([
      { modalidad: 'ANUAL', totalCuotas: 0, pagadas: 0 },
    ]);

      const result = await query.execute(MES, ANIO, TENANT);

      expect(result.modalidades[0]).toEqual({
        modalidad: 'ANUAL',
        totalCuotas: 0,
        pagadas: 0,
        porcentaje: 0,
        montoRecaudo: 0,
      });
    });

    it('should handle 100% pagadas', async () => {
      setupHappyPathMocks();
      mockCobroRepo.groupByTarifaModalidad.mockResolvedValue([
        { modalidad: 'MENSUAL', totalCuotas: 20, pagadas: 20 },
      ]);

      const result = await query.execute(MES, ANIO, TENANT);

      expect(result.modalidades[0].porcentaje).toBe(100);
      expect(result.modalidades[0].montoRecaudo).toBe(50000);
    });
  });
});
