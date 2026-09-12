import { Test, TestingModule } from '@nestjs/testing';
import { Reflector } from '@nestjs/core';
import { SolicitudesController } from './solicitudes.controller';
import { SolicitudRepository } from '../persistence/solicitud.repository';
import { CobroRepository } from '../persistence/cobro.repository';
import { PagoRepository } from '../persistence/pago.repository';
import { TicketRepository } from '../persistence/ticket.repository';
import { CorregirPagoUseCase } from '../../application/use-cases/corregir-pago.use-case';
import { EliminarPagoUseCase } from '../../application/use-cases/eliminar-pago.use-case';
import { ActividadRepository } from '../../../notifications/domain/actividad.repository';
import { Usuario, RolUsuario } from '../../../iam/domain/usuario.entity';
import { SolicitudEstado } from '../../domain/solicitud.entity';
import { EstadoValidacionPago } from '../../domain/pago.entity';

describe('SolicitudesController', () => {
  let controller: SolicitudesController;
  let mockSolicitudRepo: any;
  let mockCobroRepo: any;
  let mockPagoRepo: any;
  let mockTicketRepo: any;
  let mockCorregirPagoUC: any;
  let mockEliminarPagoUC: any;

  const mockUser = Object.assign(
    Usuario.crear(
      'residente@test.com',
      'hash',
      'Residente Test',
      RolUsuario.RESIDENTE,
      'tenant-123',
    ),
    { id: 'usr-1' },
  );

  const mockAdmin = Object.assign(
    Usuario.crear(
      'admin@test.com',
      'hash',
      'Admin Test',
      RolUsuario.ADMIN,
      'tenant-123',
    ),
    { id: 'admin-1' },
  );

  beforeEach(async () => {
    mockSolicitudRepo = {
      save: jest.fn().mockImplementation(async (s) => s),
      findByUsuario: jest.fn(),
      findByTenant: jest.fn(),
      findPendingByTenant: jest.fn(),
      findById: jest.fn(),
      findActiveRevisionByPagoOrCobro: jest.fn().mockResolvedValue(null),
      findActiveCobroByResidente: jest.fn().mockResolvedValue(null),
      delete: jest.fn(),
    };

    mockCobroRepo = {
      findById: jest.fn(),
    };

    mockPagoRepo = {
      findById: jest.fn(),
      findByCobro: jest.fn().mockResolvedValue([]),
      saveMany: jest.fn().mockImplementation(async (p) => p),
    };

    mockTicketRepo = {
      findByPago: jest.fn().mockResolvedValue(null),
    };

    mockCorregirPagoUC = {
      execute: jest.fn(),
    };

    mockEliminarPagoUC = {
      execute: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [SolicitudesController],
      providers: [
        { provide: SolicitudRepository, useValue: mockSolicitudRepo },
        { provide: CobroRepository, useValue: mockCobroRepo },
        { provide: PagoRepository, useValue: mockPagoRepo },
        { provide: TicketRepository, useValue: mockTicketRepo },
        { provide: CorregirPagoUseCase, useValue: mockCorregirPagoUC },
        { provide: EliminarPagoUseCase, useValue: mockEliminarPagoUC },
        { provide: ActividadRepository, useValue: { save: jest.fn() } },
        { provide: Reflector, useValue: { get: jest.fn() } },
      ],
    }).compile();

    controller = module.get<SolicitudesController>(SolicitudesController);
  });

  describe('listar', () => {
    it('should call findByUsuario with user id, tenant and optional limit/offset', async () => {
      const mockResult = [{ id: 'sol-1' }];
      mockSolicitudRepo.findByUsuario.mockResolvedValue(mockResult);

      const result = await controller.listar(mockUser, 'tenant-123', 20, 10);

      expect(mockSolicitudRepo.findByUsuario).toHaveBeenCalledWith(
        'usr-1',
        'tenant-123',
        20,
        10,
      );
      expect(result).toEqual(mockResult);
    });

    it('should work without pagination parameters', async () => {
      mockSolicitudRepo.findByUsuario.mockResolvedValue([]);

      const result = await controller.listar(mockUser, 'tenant-123');

      expect(mockSolicitudRepo.findByUsuario).toHaveBeenCalledWith(
        'usr-1',
        'tenant-123',
        undefined,
        undefined,
      );
      expect(result).toEqual([]);
    });
  });

  describe('crear (cross-tenant)', () => {
    it('should reject creating a solicitud whose cobro belongs to another tenant', async () => {
      // The repo lookup is tenant-scoped: a cobro from tenant-B must not be
      // resolvable with tenant-A's token, so creation is blocked.
      mockCobroRepo.findById.mockResolvedValue(null);

      await expect(
        controller.crear(
          { cobroId: 'cobro-de-tenant-B', tipo: 'COBRO_PRESENCIAL', descripcion: 'Test' },
          mockUser,
          'tenant-123',
        ),
      ).rejects.toThrow(/no existe un cobro válido/i);

      // The lookup itself must have been tenant-scoped
      expect(mockCobroRepo.findById).toHaveBeenCalledWith(
        'cobro-de-tenant-B',
        'tenant-123',
      );
      expect(mockSolicitudRepo.save).not.toHaveBeenCalled();
    });

    it('should stamp the solicitud with the token tenant, not a client-provided one', async () => {
      mockCobroRepo.findById.mockResolvedValue({ id: 'cobro-1' });

      await controller.crear(
        { cobroId: 'cobro-1', tipo: 'COBRO_PRESENCIAL', descripcion: 'Test' },
        mockUser,
        'tenant-123',
      );

      const saved = mockSolicitudRepo.save.mock.calls[0][0];
      expect(saved.tenantId).toBe('tenant-123');
      expect(saved.usuarioId).toBe('usr-1');
    });

    it('should throw ConflictException if active revision already exists', async () => {
      mockCobroRepo.findById.mockResolvedValue({ id: 'cobro-1' });
      mockSolicitudRepo.findActiveRevisionByPagoOrCobro.mockResolvedValue({ id: 'existing-sr' });

      await expect(
        controller.crear(
          { cobroId: 'cobro-1', pagoId: 'pago-1', tipo: 'Revisión de pago', descripcion: 'Doble' },
          mockUser,
          'tenant-123',
        ),
      ).rejects.toThrow(/ya existe una solicitud de revisión/i);
    });

    it('should throw ConflictException if active cobro already exists for resident', async () => {
      mockCobroRepo.findById.mockResolvedValue({ id: 'cobro-1' });
      mockSolicitudRepo.findActiveCobroByResidente.mockResolvedValue({ id: 'existing-sc' });

      await expect(
        controller.crear(
          { cobroId: 'cobro-1', tipo: 'Solicitud de cobro', descripcion: 'Doble' },
          mockUser,
          'tenant-123',
        ),
      ).rejects.toThrow(/ya tienes una solicitud de cobro activa/i);
    });

    it('should assign SR prefix for accented Revisión de pago', async () => {
      mockCobroRepo.findById.mockResolvedValue({ id: 'cobro-1' });
      mockSolicitudRepo.findActiveRevisionByPagoOrCobro.mockResolvedValue(null);

      await controller.crear(
        { cobroId: 'cobro-1', tipo: 'Revisión de pago', descripcion: 'Test tilde' },
        mockUser,
        'tenant-123',
      );

      const saved = mockSolicitudRepo.save.mock.calls[0][0];
      expect(saved.nroRecibo).toMatch(/^SR-\d{6}$/);
    });
  });

  describe('listarAdmin', () => {
    it('should call findByTenant with tenant id and optional pagination and tipo', async () => {
      mockSolicitudRepo.findByTenant.mockResolvedValue([]);

      await controller.listarAdmin('tenant-123', 50, 0, 'revision');

      expect(mockSolicitudRepo.findByTenant).toHaveBeenCalledWith(
        'tenant-123',
        50,
        0,
        'revision',
      );
    });
  });

  describe('getDetalleResolucion', () => {
    it('should return enriched details including payment, cobro, and ticket', async () => {
      const mockSol = {
        id: 'sol-1',
        tenantId: 'tenant-123',
        cobroId: 'cobro-1',
        pagoId: 'pago-1',
      };
      mockSolicitudRepo.findById.mockResolvedValue(mockSol);
      mockCobroRepo.findById.mockResolvedValue({
        id: 'cobro-1',
        concepto: 'Septiembre — Cuota 1',
        monto: 2000000,
        montoPagado: 2000000,
        estado: 'PAGADA',
        fechaVencimiento: '2026-09-30',
      });
      mockPagoRepo.findById.mockResolvedValue({
        id: 'pago-1',
        monto: 2000000,
        fechaPago: '2026-09-03',
        cobradorId: 'cob-1',
        cobrador: { nombre: 'Carlos Cobrador' },
        estado: 'VALIDADO',
        clientPaymentId: 'CP-1',
      });
      mockTicketRepo.findByPago.mockResolvedValue({
        id: 'tkt-1',
        numero: 'TKT-2026-000001',
        estado: 'EMITIDO',
        fecha: new Date(),
      });

      const res = await controller.getDetalleResolucion('sol-1', 'tenant-123');

      expect(res.solicitud).toEqual(mockSol);
      expect(res.cobro?.concepto).toBe('Septiembre — Cuota 1');
      expect(res.pago?.monto).toBe(2000000);
      expect(res.ticket?.numero).toBe('TKT-2026-000001');
    });
  });

  describe('corregirPagoDesdeSolicitud', () => {
    it('should execute CorregirPagoUseCase and resolve solicitud', async () => {
      const mockSol = {
        id: 'sol-1',
        tenantId: 'tenant-123',
        cobroId: 'cobro-1',
        pagoId: 'pago-1',
        estado: SolicitudEstado.EN_REVISION,
      };
      mockSolicitudRepo.findById.mockResolvedValue(mockSol);
      mockPagoRepo.findById.mockResolvedValue({
        id: 'pago-1',
        tenantId: 'tenant-123',
        estado: EstadoValidacionPago.PENDIENTE_REVISION,
      });
      mockCorregirPagoUC.execute.mockResolvedValue({
        id: 'pago-1',
        monto: 1500000,
      });

      const res = await controller.corregirPagoDesdeSolicitud(
        'sol-1',
        { nuevoMonto: 1500000, motivo: 'Error en digitación' },
        mockAdmin,
        'tenant-123',
      );

      expect(mockCorregirPagoUC.execute).toHaveBeenCalledWith({
        pagoId: 'pago-1',
        nuevoMonto: 1500000,
        motivo: 'Error en digitación',
        usuarioId: 'admin-1',
        tenantId: 'tenant-123',
      });
      expect(mockSol.estado).toBe(SolicitudEstado.RESUELTA);
      expect(res.success).toBe(true);
    });
  });

  describe('revertirPagoDesdeSolicitud', () => {
    it('should execute EliminarPagoUseCase and resolve solicitud', async () => {
      const mockSol = {
        id: 'sol-1',
        tenantId: 'tenant-123',
        cobroId: 'cobro-1',
        pagoId: 'pago-1',
        estado: SolicitudEstado.EN_REVISION,
      };
      mockSolicitudRepo.findById.mockResolvedValue(mockSol);

      const res = await controller.revertirPagoDesdeSolicitud(
        'sol-1',
        { motivo: 'Cobro duplicado' },
        mockAdmin,
        'tenant-123',
      );

      expect(mockEliminarPagoUC.execute).toHaveBeenCalledWith(
        'pago-1',
        'tenant-123',
      );
      expect(mockSol.estado).toBe(SolicitudEstado.RESUELTA);
      expect(res.success).toBe(true);
    });
  });

  describe('marcarEnCamino', () => {
    it('should mark solicitud as EN_CAMINO when found in tenant', async () => {
      const mockSol = { id: 'sol-1', estado: SolicitudEstado.PENDIENTE };
      mockSolicitudRepo.findById.mockResolvedValue(mockSol);

      const res = await controller.marcarEnCamino('sol-1', 'tenant-123');

      expect(mockSolicitudRepo.findById).toHaveBeenCalledWith(
        'sol-1',
        'tenant-123',
      );
      expect(res.estado).toBe(SolicitudEstado.EN_CAMINO);
    });

    it('should throw NotFoundException when solicitud is from another tenant (repo filters by tenantId)', async () => {
      mockSolicitudRepo.findById.mockResolvedValue(null);

      await expect(
        controller.marcarEnCamino('sol-x', 'tenant-123'),
      ).rejects.toThrow(/no encontrada/);
    });
  });

  describe('resolver', () => {
    it('should throw NotFoundException when solicitud is from another tenant', async () => {
      mockSolicitudRepo.findById.mockResolvedValue(null);

      await expect(
        controller.resolver('sol-x', { estado: 'RESUELTA' }, 'tenant-123'),
      ).rejects.toThrow(/no encontrada/);
    });
  });

  describe('eliminar', () => {
    it('should throw NotFoundException when solicitud is from another tenant', async () => {
      mockSolicitudRepo.findById.mockResolvedValue(null);

      await expect(controller.eliminar('sol-x', 'tenant-123')).rejects.toThrow(
        /no encontrada/,
      );
    });
  });

  describe('getDetalleResolucion (cross-tenant)', () => {
    it('should throw NotFoundException when solicitud is from another tenant', async () => {
      mockSolicitudRepo.findById.mockResolvedValue(null);

      await expect(
        controller.getDetalleResolucion('sol-x', 'tenant-123'),
      ).rejects.toThrow(/no encontrada/);
    });
  });
});
