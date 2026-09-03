import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { EventsGateway } from './events.gateway';

describe('EventsGateway', () => {
  let gateway: EventsGateway;
  let mockServer: any;
  let mockJwtService: any;

  beforeEach(async () => {
    mockServer = {
      to: jest.fn().mockReturnThis(),
      emit: jest.fn(),
    };

    mockJwtService = {
      verify: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        EventsGateway,
        {
          provide: JwtService,
          useValue: mockJwtService,
        },
      ],
    }).compile();

    gateway = module.get<EventsGateway>(EventsGateway);
    gateway.server = mockServer;
  });

  it('should be defined', () => {
    expect(gateway).toBeDefined();
  });

  describe('handleConnection security', () => {
    it('should reject connection if no token is provided in handshake', () => {
      const mockSocket: any = {
        id: 'socket-anon',
        handshake: { auth: {}, headers: {} },
        disconnect: jest.fn(),
        data: {},
      };

      gateway.handleConnection(mockSocket);

      expect(mockSocket.disconnect).toHaveBeenCalled();
      expect(mockSocket.data.user).toBeUndefined();
    });

    it('should reject connection if token is invalid or expired', () => {
      mockJwtService.verify.mockImplementation(() => {
        throw new Error('jwt expired');
      });

      const mockSocket: any = {
        id: 'socket-bad-token',
        handshake: { auth: { token: 'expired-token' } },
        disconnect: jest.fn(),
        data: {},
      };

      gateway.handleConnection(mockSocket);

      expect(mockSocket.disconnect).toHaveBeenCalled();
      expect(mockSocket.data.user).toBeUndefined();
    });

    it('should attach user payload to socket.data when token is valid', () => {
      const payload = { sub: 'user-123', tenantId: 'tenant-123', rol: 'ADMIN' };
      mockJwtService.verify.mockReturnValue(payload);

      const mockSocket: any = {
        id: 'socket-valid',
        handshake: { auth: { token: 'valid-token' } },
        disconnect: jest.fn(),
        data: {},
      };

      gateway.handleConnection(mockSocket);

      expect(mockSocket.disconnect).not.toHaveBeenCalled();
      expect(mockSocket.data.user).toEqual(payload);
    });
  });

  describe('room isolation security', () => {
    it('should reject joinTenantRoom if socket is not authenticated', () => {
      const mockSocket: any = { id: 'socket-1', join: jest.fn(), data: {} };
      gateway.handleJoinTenantRoom(mockSocket, 'tenant-123');

      expect(mockSocket.join).not.toHaveBeenCalled();
    });

    it('should reject joinTenantRoom if requested tenantId does not match token tenantId', () => {
      const mockSocket: any = {
        id: 'socket-1',
        join: jest.fn(),
        data: { user: { sub: 'user-1', tenantId: 'tenant-A' } },
      };

      gateway.handleJoinTenantRoom(mockSocket, 'tenant-B');

      expect(mockSocket.join).not.toHaveBeenCalled();
    });

    it('should allow joinTenantRoom if requested tenantId matches token tenantId', () => {
      const mockSocket: any = {
        id: 'socket-1',
        join: jest.fn(),
        data: { user: { sub: 'user-1', tenantId: 'tenant-A' } },
      };

      gateway.handleJoinTenantRoom(mockSocket, 'tenant-A');

      expect(mockSocket.join).toHaveBeenCalledWith('tenant:tenant-A');
    });

    it('should reject joinUserRoom if requested userId does not match token sub', () => {
      const mockSocket: any = {
        id: 'socket-2',
        join: jest.fn(),
        data: { user: { sub: 'user-1', tenantId: 'tenant-A' } },
      };

      gateway.handleJoinUserRoom(mockSocket, {
        tenantId: 'tenant-A',
        userId: 'user-999',
      });

      expect(mockSocket.join).not.toHaveBeenCalled();
    });

    it('should reject joinUserRoom residenteId if user is RESIDENTE and requested residenteId does not match token', () => {
      const mockSocket: any = {
        id: 'socket-2',
        join: jest.fn(),
        data: {
          user: {
            sub: 'user-456',
            tenantId: 'tenant-123',
            rol: 'RESIDENTE',
            residenteId: 'my-residente-id',
          },
        },
      };

      gateway.handleJoinUserRoom(mockSocket, {
        tenantId: 'tenant-123',
        userId: 'user-456',
        residenteId: 'victim-residente-id',
      });

      expect(mockSocket.join).toHaveBeenCalledWith('user:user-456');
      expect(mockSocket.join).not.toHaveBeenCalledWith(
        'residente:victim-residente-id',
      );
    });

    it('should allow joinUserRoom and residente room if requested userId and residenteId match token', () => {
      const mockSocket: any = {
        id: 'socket-2',
        join: jest.fn(),
        data: {
          user: {
            sub: 'user-456',
            tenantId: 'tenant-123',
            rol: 'RESIDENTE',
            residenteId: 'residente-789',
          },
        },
      };

      gateway.handleJoinUserRoom(mockSocket, {
        tenantId: 'tenant-123',
        userId: 'user-456',
        residenteId: 'residente-789',
      });

      expect(mockSocket.join).toHaveBeenCalledWith('user:user-456');
      expect(mockSocket.join).toHaveBeenCalledWith('residente:residente-789');
    });
  });

  describe('financial data leak prevention & room isolation', () => {
    it('should emit full payload to private residente room and redacted event to tenant room on emitPagoRegistrado', () => {
      const payload = {
        tenantId: 'tenant-123',
        residenteId: 'residente-789',
        cobroId: 'cobro-001',
        monto: 4000000,
      };

      gateway.emitPagoRegistrado(payload);

      // Private resident room gets full details
      expect(mockServer.to).toHaveBeenCalledWith('residente:residente-789');
      expect(mockServer.emit).toHaveBeenCalledWith('pago:registrado', payload);

      // General tenant room gets redacted notification without sensitive financial amount or resident ID
      expect(mockServer.to).toHaveBeenCalledWith('tenant:tenant-123');
      expect(mockServer.emit).toHaveBeenCalledWith('pago:registrado', {
        evento: 'PAGO_REGISTRADO',
        tenantId: 'tenant-123',
        cobroId: 'cobro-001',
      });
    });

    it('should emit full payload to private residente room and redacted event to tenant room on emitModalidadCambiada', () => {
      const payload = {
        tenantId: 'tenant-123',
        residenteId: 'residente-789',
        nuevaModalidad: 'QUINCENAL',
      };

      gateway.emitModalidadCambiada(payload);

      expect(mockServer.to).toHaveBeenCalledWith('residente:residente-789');
      expect(mockServer.emit).toHaveBeenCalledWith(
        'modalidad:cambiada',
        payload,
      );

      expect(mockServer.to).toHaveBeenCalledWith('tenant:tenant-123');
      expect(mockServer.emit).toHaveBeenCalledWith('modalidad:cambiada', {
        evento: 'MODALIDAD_CAMBIADA',
        tenantId: 'tenant-123',
      });
    });

    it('should emit full payload to private residente room and anonymized event to tenant room on emitSolicitudCreada', () => {
      const payload = {
        tenantId: 'tenant-123',
        residenteId: 'residente-789',
        casaId: 'casa-001',
        solicitudId: 'sol-001',
      };

      gateway.emitSolicitudCreada(payload);

      expect(mockServer.to).toHaveBeenCalledWith('residente:residente-789');
      expect(mockServer.emit).toHaveBeenCalledWith('solicitud:creada', payload);

      expect(mockServer.to).toHaveBeenCalledWith('tenant:tenant-123');
      expect(mockServer.emit).toHaveBeenCalledWith('solicitud:creada', {
        evento: 'SOLICITUD_CREADA',
        tenantId: 'tenant-123',
        solicitudId: 'sol-001',
      });
    });
  });
});
