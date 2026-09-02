import {
  Injectable,
  UnauthorizedException,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import * as crypto from 'crypto';
import { Usuario } from '../../iam/domain/usuario.entity';
import { AuthSession } from '../../iam/domain/auth-session.entity';
import { TokenRevocationService } from './token-revocation.service';

export interface DeviceInfo {
  deviceId?: string;
  deviceName?: string;
  ipAddress?: string;
  userAgent?: string;
}

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(Usuario)
    private readonly usuarioRepository: Repository<Usuario>,
    @InjectRepository(AuthSession)
    private readonly sessionRepository: Repository<AuthSession>,
    private readonly jwtService: JwtService,
    private readonly tokenRevocation: TokenRevocationService,
  ) {}

  private hashToken(token: string): string {
    return crypto.createHash('sha256').update(token).digest('hex');
  }

  async validateUser(username: string, password: string): Promise<Usuario> {
    const user = await this.usuarioRepository.findOne({
      where: { email: username },
    });
    if (!user) {
      throw new UnauthorizedException('Credenciales inválidas');
    }

    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Credenciales inválidas');
    }

    if (!user.activo) {
      throw new UnauthorizedException('Usuario inactivo');
    }

    return user;
  }

  async login(
    usuario: Usuario,
    deviceInfo?: DeviceInfo,
  ): Promise<{ accessToken: string; refreshToken: string; usuario: Usuario }> {
    const payload = {
      sub: usuario.id,
      email: usuario.email,
      rol: usuario.rol,
      tenantId: usuario.tenantId,
    };

    const accessToken = this.jwtService.sign(payload, { expiresIn: '15m' });
    const refreshToken = this.jwtService.sign(
      { sub: usuario.id, type: 'refresh' },
      { expiresIn: '30d' },
    );

    const session = new AuthSession();
    session.usuarioId = usuario.id;
    session.refreshTokenHash = this.hashToken(refreshToken);
    session.deviceId = deviceInfo?.deviceId ?? null;
    session.deviceName = deviceInfo?.deviceName ?? null;
    session.ipAddress = deviceInfo?.ipAddress ?? null;
    session.userAgent = deviceInfo?.userAgent ?? null;
    session.expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
    session.isRevoked = false;
    session.lastUsedAt = new Date();

    await this.sessionRepository.save(session);

    return { accessToken, refreshToken, usuario };
  }

  async refreshToken(
    token: string,
  ): Promise<{ accessToken: string; refreshToken: string; usuario: Usuario }> {
    const isRevokedInRedis = await this.tokenRevocation.isRevoked(token);
    if (isRevokedInRedis) {
      throw new UnauthorizedException('Sesión cerrada. Inicia sesión nuevamente.');
    }

    try {
      const payload = this.jwtService.verify<{
        sub: string;
        type: string;
      }>(token);

      if (payload.type !== 'refresh') {
        throw new UnauthorizedException('Token de refresco inválido');
      }

      const user = await this.usuarioRepository.findOne({
        where: { id: payload.sub },
      });

      if (!user) {
        throw new NotFoundException('Usuario no encontrado');
      }

      if (!user.activo) {
        throw new UnauthorizedException('Usuario inactivo');
      }

      const incomingHash = this.hashToken(token);

      const session = await this.sessionRepository.findOne({
        where: { usuarioId: user.id, refreshTokenHash: incomingHash },
      });

      if (!session) {
        const revokedSession = await this.sessionRepository.findOne({
          where: { refreshTokenHash: incomingHash },
        });

        if (revokedSession) {
          await this.sessionRepository.update(
            { usuarioId: user.id },
            { isRevoked: true },
          );
          throw new UnauthorizedException(
            'Se detectó un intento de reutilización de token. Por seguridad, todas las sesiones han sido cerradas.',
          );
        }

        throw new UnauthorizedException('Sesión no encontrada o expirada. Inicia sesión nuevamente.');
      }

      if (session.isRevoked || session.expiresAt < new Date()) {
        throw new UnauthorizedException('Sesión expirada o revocada. Inicia sesión nuevamente.');
      }

      const newPayload = {
        sub: user.id,
        email: user.email,
        rol: user.rol,
        tenantId: user.tenantId,
      };

      const newAccessToken = this.jwtService.sign(newPayload, { expiresIn: '15m' });
      const newRefreshToken = this.jwtService.sign(
        { sub: user.id, type: 'refresh' },
        { expiresIn: '30d' },
      );

      session.refreshTokenHash = this.hashToken(newRefreshToken);
      session.lastUsedAt = new Date();
      session.expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
      await this.sessionRepository.save(session);

      return { accessToken: newAccessToken, refreshToken: newRefreshToken, usuario: user };
    } catch (error) {
      if (error instanceof UnauthorizedException || error instanceof NotFoundException) {
        throw error;
      }
      throw new UnauthorizedException('Token de refresco inválido o expirado');
    }
  }

  async revokeRefreshToken(token: string): Promise<void> {
    await this.tokenRevocation.revoke(token);
    const hash = this.hashToken(token);
    await this.sessionRepository.update(
      { refreshTokenHash: hash },
      { isRevoked: true },
    );
  }

  async revokeAllSessionsForUser(usuarioId: string): Promise<void> {
    await this.sessionRepository.update(
      { usuarioId },
      { isRevoked: true },
    );
  }

  async getUserSessions(usuarioId: string): Promise<AuthSession[]> {
    return this.sessionRepository.find({
      where: { usuarioId, isRevoked: false },
      order: { lastUsedAt: 'DESC' },
    });
  }

  async revokeSessionById(sessionId: string, usuarioId: string): Promise<void> {
    const session = await this.sessionRepository.findOne({
      where: { id: sessionId, usuarioId },
    });
    if (!session) {
      throw new NotFoundException('Sesión no encontrada');
    }
    session.isRevoked = true;
    await this.sessionRepository.save(session);
  }

  async resetPasswordForUser(params: {
    residenteId?: string;
    usuarioId?: string;
    tenantId: string;
  }): Promise<{ username: string; password: string }> {
    let usuario: Usuario | null = null;

    if (params.usuarioId) {
      usuario = await this.usuarioRepository.findOne({
        where: { id: params.usuarioId, tenantId: params.tenantId },
      });
    } else if (params.residenteId) {
      usuario = await this.usuarioRepository.findOne({
        where: { residenteId: params.residenteId, tenantId: params.tenantId },
      });
    }

    if (!usuario) {
      throw new NotFoundException('No se encontró usuario para este ID');
    }

    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
    const randomBytes = crypto.randomBytes(12);
    let nuevaPassword = '';
    for (let i = 0; i < 12; i++) {
      nuevaPassword += chars.charAt(randomBytes[i] % chars.length);
    }

    const passwordHash = await bcrypt.hash(nuevaPassword, 10);
    usuario.passwordHash = passwordHash;
    await this.usuarioRepository.save(usuario);

    return { username: usuario.email, password: nuevaPassword };
  }

  async updateCredentials(params: {
    usuarioId?: string;
    tenantId: string;
    newUsername?: string;
    newPassword?: string;
    currentPassword?: string;
  }): Promise<{ username: string }> {
    const usuario = await this.usuarioRepository.findOne({
      where: { id: params.usuarioId, tenantId: params.tenantId },
    });

    if (!usuario) {
      throw new NotFoundException('Usuario no encontrado');
    }

    if (params.currentPassword) {
      const valid = await bcrypt.compare(params.currentPassword, usuario.passwordHash);
      if (!valid) {
        throw new UnauthorizedException('La contraseña actual es incorrecta');
      }
    }

    if (params.newUsername && params.newUsername !== usuario.email) {
      const existente = await this.usuarioRepository.findOne({
        where: { email: params.newUsername, tenantId: params.tenantId },
      });
      if (existente && existente.id !== usuario.id) {
        throw new BadRequestException('Este nombre de usuario ya está en uso');
      }
      usuario.email = params.newUsername;
    }

    if (params.newPassword) {
      const passwordHash = await bcrypt.hash(params.newPassword, 10);
      usuario.passwordHash = passwordHash;
    }

    await this.usuarioRepository.save(usuario);

    return { username: usuario.email };
  }

  async getCredentials(usuarioId: string, tenantId: string): Promise<{ username: string }> {
    const usuario = await this.usuarioRepository.findOne({
      where: { id: usuarioId, tenantId },
    });

    if (!usuario) {
      throw new NotFoundException('Usuario no encontrado');
    }

    return { username: usuario.email };
  }
}
