import { Test, TestingModule } from '@nestjs/testing';
import { EventsGateway } from './events.gateway';

describe('EventsGateway', () => {
  let gateway: EventsGateway;
  let mockServer: any;

  beforeEach(async () => {
    mockServer = {
      to: jest.fn().mockReturnThis(),
      emit: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [EventsGateway],
    }).compile();

    gateway = module.get<EventsGateway>(EventsGateway);
    gateway.server = mockServer;
  });

  it('should be defined', () => {
    expect(gateway).toBeDefined();
  });

  it('should handle client joinTenantRoom correctly', () => {
    const mockSocket: any = { id: 'socket-1', join: jest.fn() };
    gateway.handleJoinTenantRoom(mockSocket, 'tenant-123');

    expect(mockSocket.join).toHaveBeenCalledWith('tenant:tenant-123');
  });

  it('should handle client joinUserRoom correctly', () => {
    const mockSocket: any = { id: 'socket-2', join: jest.fn() };
    gateway.handleJoinUserRoom(mockSocket, {
      tenantId: 'tenant-123',
      userId: 'user-456',
      residenteId: 'residente-789',
    });

    expect(mockSocket.join).toHaveBeenCalledWith('user:user-456');
    expect(mockSocket.join).toHaveBeenCalledWith('residente:residente-789');
  });

  it('should emit pago:registrado event to residente and tenant rooms', () => {
    const payload = {
      tenantId: 'tenant-123',
      residenteId: 'residente-789',
      cobroId: 'cobro-001',
      monto: 4000000,
    };

    gateway.emitPagoRegistrado(payload);

    expect(mockServer.to).toHaveBeenCalledWith('residente:residente-789');
    expect(mockServer.to).toHaveBeenCalledWith('tenant:tenant-123');
    expect(mockServer.emit).toHaveBeenCalledWith('pago:registrado', payload);
  });

  it('should emit modalidad:cambiada event to residente and tenant rooms', () => {
    const payload = {
      tenantId: 'tenant-123',
      residenteId: 'residente-789',
      nuevaModalidad: 'QUINCENAL',
    };

    gateway.emitModalidadCambiada(payload);

    expect(mockServer.to).toHaveBeenCalledWith('residente:residente-789');
    expect(mockServer.to).toHaveBeenCalledWith('tenant:tenant-123');
    expect(mockServer.emit).toHaveBeenCalledWith('modalidad:cambiada', payload);
  });

  it('should emit solicitud:creada event to tenant room', () => {
    const payload = {
      tenantId: 'tenant-123',
      residenteId: 'residente-789',
      casaId: 'casa-001',
      solicitudId: 'sol-001',
    };

    gateway.emitSolicitudCreada(payload);

    expect(mockServer.to).toHaveBeenCalledWith('tenant:tenant-123');
    expect(mockServer.emit).toHaveBeenCalledWith('solicitud:creada', payload);
  });
});
