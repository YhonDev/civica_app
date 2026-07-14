import { DashboardController } from '../../infrastructure/controllers/dashboard.controller';
import { PagoRepository } from '../../infrastructure/persistence/pago.repository';
import { SolicitudRepository } from '../../infrastructure/persistence/solicitud.repository';

describe('DashboardController — Residente Timeline', () => {
  let controller: DashboardController;

  const mockPagoRepo = {
    findByPropietario: jest.fn(),
    countByCobro: jest.fn(),
  };

  const mockSolicitudRepo = {
    findByUsuario: jest.fn(),
  };

  beforeEach(() => {
    jest.clearAllMocks();

    controller = new DashboardController(
      {} as any, // DashboardQuery
      {} as any, // CobroRepository
      mockPagoRepo as unknown as PagoRepository,
      {} as any, // PlanDeCobroRepository
      mockSolicitudRepo as unknown as SolicitudRepository,
      {} as any, // TarifaRepository
      {} as any, // ResidenteRepository
      {} as any, // DataSource
    );
  });

  function makePago(
    overrides: Partial<{ id: string; fechaPago: string; monto: number }> = {},
  ) {
    return {
      id: overrides.id ?? 'pago-1',
      fechaPago: overrides.fechaPago ?? '2026-06-15',
      monto: overrides.monto ?? 150000,
    };
  }

  function makeSolicitud(
    overrides: Partial<{
      id: string;
      fecha: Date;
      descripcion: string;
      estado: string;
    }> = {},
  ) {
    return {
      id: overrides.id ?? 'sol-1',
      fecha: overrides.fecha ?? new Date('2026-06-10T14:00:00Z'),
      descripcion: overrides.descripcion ?? 'Solicita cobro en casa',
      estado: overrides.estado ?? 'EN_REVISION',
    };
  }

  function mockUser(residenteId = 'prop-1', userId = 'user-1') {
    return { id: userId, residenteId } as any;
  }

  describe('Merge pagos + solicitudes — sorted by date DESC', () => {
    it('should merge and sort mixed pagos and solicitudes by date descending', async () => {
      mockPagoRepo.findByPropietario.mockResolvedValue([
        makePago({ id: 'p1', fechaPago: '2026-06-01', monto: 100000 }),
        makePago({ id: 'p2', fechaPago: '2026-06-15', monto: 200000 }),
      ]);
      mockSolicitudRepo.findByUsuario.mockResolvedValue([
        makeSolicitud({ id: 's1', fecha: new Date('2026-06-10T10:00:00Z') }),
      ]);

      const result = await controller.getResidenteTimeline(mockUser(), 0, 20);

      expect(result.items).toHaveLength(3);
      expect(result.items[0].id).toBe('p2');
      expect(result.items[0].type).toBe('PAGO');
      expect(result.items[1].id).toBe('s1');
      expect(result.items[1].type).toBe('SOLICITUD');
      expect(result.items[2].id).toBe('p1');
      expect(result.items[2].type).toBe('PAGO');
    });
  });

  describe('Pagination — offset/limit slice and hasMore flag', () => {
    it('should return first 2 items with hasMore=true when 5 total items exist', async () => {
      const pagos = Array.from({ length: 3 }, (_, i) =>
        makePago({ id: `p${i}`, fechaPago: `2026-06-${String(i + 1).padStart(2, '0')}`, monto: (i + 1) * 100000 }),
      );
      const solicitudes = Array.from({ length: 2 }, (_, i) =>
        makeSolicitud({ id: `s${i}`, fecha: new Date(`2026-06-${String(i + 10).padStart(2, '0')}T10:00:00Z`) }),
      );
      mockPagoRepo.findByPropietario.mockResolvedValue(pagos);
      mockSolicitudRepo.findByUsuario.mockResolvedValue(solicitudes);

      const result = await controller.getResidenteTimeline(mockUser(), 0, 2);

      expect(result.items).toHaveLength(2);
      expect(result.hasMore).toBe(true);
      expect(result.items[0].id).toBe('s1');
      expect(result.items[1].id).toBe('s0');
    });

    it('should return last page with hasMore=false', async () => {
      const pagos = Array.from({ length: 3 }, (_, i) =>
        makePago({ id: `p${i}`, fechaPago: `2026-06-${String(i + 1).padStart(2, '0')}`, monto: (i + 1) * 100000 }),
      );
      mockPagoRepo.findByPropietario.mockResolvedValue(pagos);
      mockSolicitudRepo.findByUsuario.mockResolvedValue([]);

      const result = await controller.getResidenteTimeline(mockUser(), 2, 2);

      expect(result.items).toHaveLength(1);
      expect(result.hasMore).toBe(false);
      expect(result.items[0].id).toBe('p0');
    });
  });

  describe('Empty repos — both return empty', () => {
    it('should return items:[], hasMore:false when both repos return empty', async () => {
      mockPagoRepo.findByPropietario.mockResolvedValue([]);
      mockSolicitudRepo.findByUsuario.mockResolvedValue([]);

      const result = await controller.getResidenteTimeline(mockUser(), 0, 20);

      expect(result.items).toEqual([]);
      expect(result.hasMore).toBe(false);
    });
  });

  describe('Pago mapping — correct DTO shape', () => {
    it('should map pago to TimelineItemDto with monto in COP and description', async () => {
      mockPagoRepo.findByPropietario.mockResolvedValue([
        makePago({ id: 'pago-abc', fechaPago: '2026-07-01', monto: 350000 }),
      ]);
      mockSolicitudRepo.findByUsuario.mockResolvedValue([]);

      const result = await controller.getResidenteTimeline(mockUser(), 0, 20);

      expect(result.items[0]).toEqual({
        id: 'pago-abc',
        type: 'PAGO',
        date: '2026-07-01',
        monto: 3500,
        description: 'Pago de cuota',
        estado: 'PAGADO',
      });
    });
  });

  describe('Solicitud mapping — monto is null', () => {
    it('should map solicitud to TimelineItemDto with monto null', async () => {
      mockPagoRepo.findByPropietario.mockResolvedValue([]);
      mockSolicitudRepo.findByUsuario.mockResolvedValue([
        makeSolicitud({ id: 'sol-xyz', descripcion: 'Solicita cobro urgente', estado: 'PENDIENTE' }),
      ]);

      const result = await controller.getResidenteTimeline(mockUser(), 0, 20);

      expect(result.items[0]).toEqual({
        id: 'sol-xyz',
        type: 'SOLICITUD',
        date: expect.any(String),
        monto: null,
        description: 'Solicita cobro urgente',
        estado: 'PENDIENTE',
      });
    });
  });
});
