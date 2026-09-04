import { Test, TestingModule } from '@nestjs/testing';
import { TicketsController } from './tickets.controller';
import { TicketRepository } from '../persistence/ticket.repository';
import { TicketCobro } from '../../domain/ticket-cobro.entity';
import { RolUsuario, Usuario } from '../../../iam/domain/usuario.entity';
import { NotFoundException } from '@nestjs/common';

describe('TicketsController', () => {
  let controller: TicketsController;

  const mockTicket = new TicketCobro();
  mockTicket.id = 'ticket-1';
  mockTicket.tipo = 'COBRO';
  mockTicket.numero = 'TKT-2026-000001';
  mockTicket.fecha = new Date('2026-07-25T10:00:00Z');
  mockTicket.tenantId = 'tenant-1';
  mockTicket.residenteId = 'residente-1';
  mockTicket.residenteNombre = 'Maria Lopez';
  mockTicket.residenteDocumento = '98765432';
  mockTicket.casaDireccion = 'Casa 15';
  mockTicket.etapa = 'Etapa 2';
  mockTicket.manzana = 'Manzana C';
  mockTicket.estado = 'EMITIDO';
  mockTicket.pagoId = 'pago-1';
  mockTicket.cobroId = 'cobro-1';
  mockTicket.cobradorId = 'cobrador-1';
  mockTicket.cobradorNombre = 'Pedro Cobrador';
  mockTicket.monto = 40000;
  mockTicket.metodo = 'EFECTIVO';
  mockTicket.concepto = 'Cuota Julio';
  mockTicket.createdAt = new Date('2026-07-25T10:00:00Z');
  mockTicket.updatedAt = new Date('2026-07-25T10:00:00Z');

  const mockTicketRepo = {
    findById: jest.fn(),
    findByNumero: jest.fn(),
    findByPago: jest.fn(),
    findByResidente: jest.fn(),
    findByTenantPaginated: jest.fn(),
  };

  const createMockUser = (rol: RolUsuario): Usuario => {
    const user = new Usuario();
    user.id = 'user-1';
    user.rol = rol;
    user.tenantId = 'tenant-1';
    user.residenteId = rol === RolUsuario.RESIDENTE ? 'residente-1' : null;
    return user;
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      controllers: [TicketsController],
      providers: [{ provide: TicketRepository, useValue: mockTicketRepo }],
    }).compile();

    controller = module.get<TicketsController>(TicketsController);
  });

  describe('getById', () => {
    it('should throw NotFoundException if ticket does not exist', async () => {
      mockTicketRepo.findById.mockResolvedValue(null);
      await expect(
        controller.getById(
          'non-existent',
          createMockUser(RolUsuario.RESIDENTE),
          'tenant-1',
        ),
      ).rejects.toThrow(NotFoundException);
    });

    it('should return RESIDENTE projection for RESIDENTE role', async () => {
      mockTicketRepo.findById.mockResolvedValue(mockTicket);

      const result = (await controller.getById(
        'ticket-1',
        createMockUser(RolUsuario.RESIDENTE),
        'tenant-1',
      )) as any;

      expect(result.numero).toBe('TKT-2026-000001');
      expect(result.residenteNombre).toBe('Maria Lopez');
      expect(result.monto).toBe(40000);
      // Residente should NOT see internal IDs or documento
      expect(result.residenteId).toBeUndefined();
      expect(result.cobradorNombre).toBeUndefined();
      expect(result.pagoId).toBeUndefined();
    });

    it('should return COBRADOR projection for COBRADOR role', async () => {
      mockTicketRepo.findById.mockResolvedValue(mockTicket);

      const result = (await controller.getById(
        'ticket-1',
        createMockUser(RolUsuario.COBRADOR),
        'tenant-1',
      )) as any;

      expect(result.residenteId).toBe('residente-1');
      expect(result.cobradorNombre).toBe('Pedro Cobrador');
      expect(result.pagoId).toBe('pago-1');
      // Cobrador should NOT see tenantId or documento
      expect(result.tenantId).toBeUndefined();
      expect(result.residenteDocumento).toBeUndefined();
    });

    it('should return ADMIN projection for ADMIN role', async () => {
      mockTicketRepo.findById.mockResolvedValue(mockTicket);

      const result = (await controller.getById(
        'ticket-1',
        createMockUser(RolUsuario.ADMIN),
        'tenant-1',
      )) as any;

      expect(result.residenteId).toBe('residente-1');
      expect(result.cobradorNombre).toBe('Pedro Cobrador');
      expect(result.tenantId).toBe('tenant-1');
      expect(result.residenteDocumento).toBe('98765432');
    });
  });

  describe('list', () => {
    it('should return ticket by pagoId', async () => {
      mockTicketRepo.findByPago.mockResolvedValue(mockTicket);

      const result = await controller.list(
        '',
        'pago-1',
        '',
        createMockUser(RolUsuario.RESIDENTE),
        'tenant-1',
      );

      expect(mockTicketRepo.findByPago).toHaveBeenCalledWith(
        'pago-1',
        'tenant-1',
      );
      expect((result as any).numero).toBe('TKT-2026-000001');
    });

    it('should return tickets by residenteId', async () => {
      mockTicketRepo.findByResidente.mockResolvedValue([mockTicket]);

      const result = (await controller.list(
        'residente-1',
        '',
        '10',
        createMockUser(RolUsuario.RESIDENTE),
        'tenant-1',
      )) as any[];

      expect(mockTicketRepo.findByResidente).toHaveBeenCalledWith(
        'residente-1',
        'tenant-1',
        { limit: 10 },
      );
      expect(result).toHaveLength(1);
      expect(result[0].numero).toBe('TKT-2026-000001');
    });
  });

  describe('tenant isolation', () => {
    it('should not return a ticket from another tenant by id', async () => {
      mockTicketRepo.findById.mockResolvedValue(null);

      await expect(
        controller.getById(
          'ticket-1',
          createMockUser(RolUsuario.ADMIN),
          'tenant-2',
        ),
      ).rejects.toThrow(NotFoundException);
      expect(mockTicketRepo.findById).toHaveBeenCalledWith(
        'ticket-1',
        'tenant-2',
      );
    });

    it('should not list tickets for another residente when resident role', async () => {
      const result = await controller.list(
        'residente-2',
        '',
        '',
        createMockUser(RolUsuario.RESIDENTE),
        'tenant-1',
      );

      expect(result).toEqual([]);
      expect(mockTicketRepo.findByResidente).not.toHaveBeenCalled();
    });
  });

  describe('getByNumero', () => {
    it('should return full ADMIN projection when found by number', async () => {
      mockTicketRepo.findByNumero.mockResolvedValue(mockTicket);

      const result = (await controller.getByNumero(
        'TKT-2026-000001',
        createMockUser(RolUsuario.ADMIN),
        'tenant-1',
      )) as any;

      expect(mockTicketRepo.findByNumero).toHaveBeenCalledWith(
        'tenant-1',
        'TKT-2026-000001',
      );
      expect(result.numero).toBe('TKT-2026-000001');
      expect(result.tenantId).toBe('tenant-1');
    });
  });
});
