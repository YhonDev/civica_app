import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Logger, Injectable } from '@nestjs/common';
import { Server, Socket } from 'socket.io';

/**
 * WebSocket Gateway for real-time events.
 * CORS is restricted to origins from CORS_ORIGIN env var (same as HTTP).
 */
@Injectable()
@WebSocketGateway({
  cors: {
    origin: process.env.CORS_ORIGIN?.split(',') ?? ['http://localhost:3000'],
    methods: ['GET', 'POST'],
    credentials: true,
  },
})
export class EventsGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(EventsGateway.name);

  handleConnection(client: Socket) {
    this.logger.log(`Cliente conectado a WebSockets: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    this.logger.log(`Cliente desconectado de WebSockets: ${client.id}`);
  }

  @SubscribeMessage('joinTenantRoom')
  handleJoinTenantRoom(client: Socket, tenantId: string) {
    if (!tenantId) return;
    const room = `tenant:${tenantId}`;
    client.join(room);
    this.logger.log(`Cliente ${client.id} unido a sala ${room}`);
  }

  @SubscribeMessage('joinUserRoom')
  handleJoinUserRoom(
    client: Socket,
    payload: { tenantId: string; userId: string; residenteId?: string },
  ) {
    if (!payload?.userId) return;
    const userRoom = `user:${payload.userId}`;
    client.join(userRoom);
    this.logger.log(`Cliente ${client.id} unido a sala ${userRoom}`);

    if (payload.residenteId) {
      const resRoom = `residente:${payload.residenteId}`;
      client.join(resRoom);
      this.logger.log(`Cliente ${client.id} unido a sala ${resRoom}`);
    }
  }

  /// Emitido cuando un cobrador o admin registra un pago
  emitPagoRegistrado(payload: {
    tenantId: string;
    residenteId: string;
    cobroId: string;
    monto: number;
  }) {
    this.logger.log(
      `Emitiendo evento real-time PAGO_REGISTRADO para residente ${payload.residenteId}`,
    );
    if (this.server) {
      this.server
        .to(`residente:${payload.residenteId}`)
        .emit('pago:registrado', payload);
      this.server
        .to(`tenant:${payload.tenantId}`)
        .emit('pago:registrado', payload);
    }
  }

  /// Emitido cuando se cambia la modalidad de recaudo
  emitModalidadCambiada(payload: {
    tenantId: string;
    residenteId: string;
    nuevaModalidad: string;
  }) {
    this.logger.log(
      `Emitiendo evento real-time MODALIDAD_CAMBIADA para residente ${payload.residenteId}`,
    );
    if (this.server) {
      this.server
        .to(`residente:${payload.residenteId}`)
        .emit('modalidad:cambiada', payload);
      this.server
        .to(`tenant:${payload.tenantId}`)
        .emit('modalidad:cambiada', payload);
    }
  }

  /// Emitido cuando un residente crea una solicitud de cobro
  emitSolicitudCreada(payload: {
    tenantId: string;
    residenteId: string;
    casaId?: string;
    solicitudId: string;
  }) {
    this.logger.log(
      `Emitiendo evento real-time SOLICITUD_CREADA para tenant ${payload.tenantId}`,
    );
    if (this.server) {
      this.server
        .to(`tenant:${payload.tenantId}`)
        .emit('solicitud:creada', payload);
    }
  }
}
