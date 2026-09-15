import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Reflector } from '@nestjs/core';
import { Request } from 'express';
import { DataSource } from 'typeorm';
import { AccessScope, PlatformPrincipal } from '../domain/access-scope.enum';
import { REQUIRED_SCOPE_KEY } from '../decorators/require-scope.decorator';

interface PlatformTokenPayload {
  sub?: string;
  scope?: string;
  platformRole?: string;
  mfaLevel?: string;
  jti?: string;
}

@Injectable()
export class PlatformAdminGuard implements CanActivate {
  constructor(
    private readonly jwtService: JwtService,
    private readonly reflector: Reflector,
    private readonly dataSource: DataSource,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const requiredScope = this.reflector.getAllAndOverride<AccessScope>(
      REQUIRED_SCOPE_KEY,
      [context.getHandler(), context.getClass()],
    );

    if (requiredScope !== AccessScope.PLATFORM) {
      throw new ForbiddenException('Scope de plataforma no configurado');
    }

    const request = context.switchToHttp().getRequest<Request>();
    const token = this.extractBearerToken(request);
    if (!token) {
      throw new UnauthorizedException('Credencial requerida');
    }

    let payload: PlatformTokenPayload;
    try {
      payload = this.jwtService.verify<PlatformTokenPayload>(token);
    } catch {
      throw new UnauthorizedException('Token inválido o expirado');
    }

    if (
      payload.scope !== AccessScope.PLATFORM ||
      payload.platformRole !== 'SUPERADMIN'
    ) {
      throw new ForbiddenException(
        'El token no tiene permisos de administrador de plataforma',
      );
    }

    if (!payload.sub) {
      throw new UnauthorizedException('Token de plataforma inválido');
    }

    if (
      payload.jti &&
      !(await this.hasActiveSession(payload.sub, payload.jti))
    ) {
      throw new UnauthorizedException(
        'Sesión de plataforma revocada o expirada',
      );
    }

    const principal: PlatformPrincipal = {
      sub: payload.sub,
      scope: AccessScope.PLATFORM,
      platformRole: 'SUPERADMIN',
      mfaLevel:
        payload.mfaLevel === 'WEBAUTHN' || payload.mfaLevel === 'PASSKEY'
          ? payload.mfaLevel
          : 'NONE',
    };
    request.user = principal;
    return true;
  }

  private async hasActiveSession(
    adminId: string,
    jti: string,
  ): Promise<boolean> {
    const rows = await this.dataSource.query(
      `SELECT 1
       FROM platform_sessions ps
       JOIN platform_admins pa ON pa.id = ps.admin_id
       WHERE ps.admin_id = $1
         AND ps.jti = $2
         AND ps.revoked_at IS NULL
         AND ps.expires_at > now()
         AND pa.active = true`,
      [adminId, jti],
    );
    return rows.length > 0;
  }

  private extractBearerToken(request: Request): string | null {
    const authorization = request.header('authorization');
    if (!authorization) return null;

    const [scheme, token] = authorization.split(' ');
    return scheme?.toLowerCase() === 'bearer' && token ? token : null;
  }
}
