import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Logger, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { JwtService } from '@nestjs/jwt';
import { Repository } from 'typeorm';
import { Usuario } from '../iam/domain/usuario.entity';
import { Server, Socket } from 'socket.io';

/**
 * WebSocket Gateway for real-time events.
 * Protected with JWT handshake authentication and strict multi-tenant room isolation.
 */
const isDev = process.env.NODE_ENV !== 'production';
const wsCorsOrigins = process.env.CORS_ORIGIN?.split(',').map((s) => s.trim()) ?? [
  'http://localhost:3000',
];

function isOriginAllowed(origin: string | undefined): boolean {
  if (!origin) return true;
  if (isDev && /^https?:\/\/(localhost|127\.0\.0\.1)(:[0-9]+)?$/.test(origin)) {
    return true;
  }
  return wsCorsOrigins.includes(origin);
}

@Injectable()
@WebSocketGateway({
  cors: {
    origin: (
      origin: string | undefined,
      callback: (err: Error | null, allow?: boolean) => void,
    ) => {
      if (isOriginAllowed(origin)) {
        callback(null, true);
      } else {
        callback(new Error(`WebSocket CORS blocked for origin: ${origin}`), false);
      }
    },
    methods: ['GET', 'POST'],
    credentials: true,
  },
})
export class EventsGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(EventsGateway.name);

  constructor(
    private readonly jwtService: JwtService,
    @InjectRepository(Usuario)
    private readonly usuarioRepository: Repository<Usuario>,
  ) {}

  async handleConnection(client: Socket) {
    try {
      const rawHeader = client.handshake.headers?.authorization;
      const headerToken =
        typeof rawHeader === 'string' && rawHeader.startsWith('Bearer ')
          ? rawHeader.slice(7)
          : rawHeader;

      const token =
        client.handshake.auth?.token ||
        headerToken ||
        client.handshake.query?.token;

      if (!token || typeof token !== 'string') {
        this.logger.warn(
          `Conexión WS rechazada para socket ${client.id}: token ausente.`,
        );
        client.disconnect();
        return;
      }

      const payload = this.jwtService.verify<{
        sub?: string;
        tenantId?: string;
        type?: string;
      }>(token);
      if (payload.type === 'refresh' || !payload.sub || !payload.tenantId) {
        client.disconnect();
        return;
      }

      const user = await this.usuarioRepository.findOne({
        where: { id: payload.sub, tenantId: payload.tenantId },
      });
      if (!user || !user.activo) {
        client.disconnect();
        return;
      }

      client.data = client.data || {};
      client.data.user = payload;
      this.logger.log(`Cliente autenticado en WebSockets: ${client.id}`);
    } catch (err: any) {
      this.logger.warn(
        `Conexión WS rechazada para socket ${client.id}: token inválido.`,
      );
      client.disconnect();
    }
  }

  handleDisconnect(client: Socket) {
    this.logger.log(`Cliente desconectado de WebSockets: ${client.id}`);
  }

  @SubscribeMessage('joinTenantRoom')
  handleJoinTenantRoom(client: Socket, tenantId: string) {
    const user = client.data?.user;
    if (!user) {
      this.logger.warn(
        `Intento no autenticado de unirse a sala tenant por socket ${client.id}`,
      );
      return;
    }

    // Aislamiento estricto multi-tenant: no se permite unirse a sala ajena
    if (user.tenantId !== tenantId) {
      this.logger.warn(
        `Socket ${client.id} (tenant ${user.tenantId}) intentó unirse a sala ajena ${tenantId}`,
      );
      return;
    }

    const room = `tenant:${tenantId}`;
    client.join(room);
    this.logger.log(`Cliente ${client.id} unido a sala ${room}`);
  }

  @SubscribeMessage('joinUserRoom')
  handleJoinUserRoom(
    client: Socket,
    payload: { tenantId: string; userId: string; residenteId?: string },
  ) {
    const user = client.data?.user;
    if (!user) return;

    // Aislamiento estricto de usuario y tenant
    if (user.sub !== payload?.userId || user.tenantId !== payload?.tenantId) {
      this.logger.warn(
        `Socket ${client.id} intentó unirse a userRoom no autorizada (solicitó ${payload?.userId}, es ${user.sub})`,
      );
      return;
    }

    const userRoom = `user:${payload.userId}`;
    client.join(userRoom);
    this.logger.log(`Cliente ${client.id} unido a sala ${userRoom}`);

    if (payload.residenteId) {
      // Si el usuario es un RESIDENTE, debe coincidir estrictamente con su propio residenteId
      if (
        user.rol === 'RESIDENTE' &&
        (!user.residenteId || user.residenteId !== payload.residenteId)
      ) {
        this.logger.warn(
          `Socket ${client.id} (residente ${user.residenteId}) intentó unirse a sala residente ajena ${payload.residenteId}`,
        );
        return;
      }
      // Para cualquier rol, si tiene residenteId asignado, no puede suscribirse a otro residente
      if (user.residenteId && user.residenteId !== payload.residenteId) {
        this.logger.warn(
          `Socket ${client.id} intentó unirse a sala residente ajena ${payload.residenteId}`,
        );
        return;
      }
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
      // Sala privada del residente recibe el detalle completo
      this.server
        .to(`residente:${payload.residenteId}`)
        .emit('pago:registrado', payload);

      // Sala general del tenant recibe evento anonimizado sin monto ni ID de residente (evita fuga financiera)
      this.server.to(`tenant:${payload.tenantId}`).emit('pago:registrado', {
        evento: 'PAGO_REGISTRADO',
        tenantId: payload.tenantId,
        cobroId: payload.cobroId,
      });
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
      // Sala privada del residente recibe la modalidad específica
      this.server
        .to(`residente:${payload.residenteId}`)
        .emit('modalidad:cambiada', payload);

      // Sala general recibe notificación anonimizada sin revelar residente ni nueva modalidad
      this.server.to(`tenant:${payload.tenantId}`).emit('modalidad:cambiada', {
        evento: 'MODALIDAD_CAMBIADA',
        tenantId: payload.tenantId,
      });
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
      // Sala privada del residente recibe el detalle completo
      this.server
        .to(`residente:${payload.residenteId}`)
        .emit('solicitud:creada', payload);

      // Sala general recibe notificación sin datos personales de residente ni casaId
      this.server.to(`tenant:${payload.tenantId}`).emit('solicitud:creada', {
        evento: 'SOLICITUD_CREADA',
        tenantId: payload.tenantId,
        solicitudId: payload.solicitudId,
      });
    }
  }
}
