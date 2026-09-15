import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { DataSource } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { randomUUID, createHash } from 'node:crypto';
import { PlatformAuditService } from '../domain/platform-audit.service';

@Injectable()
export class PlatformAuthService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly jwtService: JwtService,
    private readonly auditService: PlatformAuditService,
  ) {}

  async login(email: string, password: string, requestId?: string) {
    const rows = await this.dataSource.query(
      `SELECT id, email, name, password_hash, active
       FROM platform_admins
       WHERE email = $1`,
      [email.toLowerCase().trim()],
    );
    const admin = rows[0];
    if (
      !admin ||
      !admin.active ||
      !(await bcrypt.compare(password, admin.password_hash))
    ) {
      throw new UnauthorizedException('Credenciales inválidas');
    }

    const jti = randomUUID();
    const accessToken = this.jwtService.sign(
      {
        sub: admin.id,
        email: admin.email,
        scope: 'PLATFORM',
        platformRole: 'SUPERADMIN',
        mfaLevel: 'NONE',
        jti,
      },
      { expiresIn: '15m' },
    );
    const tokenHash = createHash('sha256').update(accessToken).digest('hex');

    await this.dataSource.query(
      `INSERT INTO platform_sessions
        (admin_id, jti, access_token_hash, expires_at)
       VALUES ($1, $2, $3, now() + interval '15 minutes')`,
      [admin.id, jti, tokenHash],
    );
    await this.auditService.record({
      actorId: admin.id,
      action: 'PLATFORM_LOGIN',
      resource: 'platform_session',
      resourceId: jti,
      requestId,
    });

    return {
      accessToken,
      expiresIn: 900,
      administrator: { id: admin.id, email: admin.email, name: admin.name },
    };
  }

  async createAdministrator(
    email: string,
    name: string,
    password: string,
    actorId: string,
  ) {
    const normalizedEmail = email.toLowerCase().trim();
    const passwordHash = await bcrypt.hash(password, 12);
    try {
      const rows = await this.dataSource.query(
        `INSERT INTO platform_admins (email, name, password_hash)
         VALUES ($1, $2, $3)
         RETURNING id, email, name, active, created_at AS "createdAt"`,
        [normalizedEmail, name.trim(), passwordHash],
      );
      await this.auditService.record({
        actorId,
        action: 'PLATFORM_ADMIN_CREATED',
        resource: 'platform_admin',
        resourceId: rows[0].id,
      });
      return rows[0];
    } catch (error) {
      if (error instanceof Error && 'code' in error && error.code === '23505') {
        throw new ConflictException('El correo ya está registrado');
      }
      throw error;
    }
  }

  async listAdministrators() {
    return this.dataSource.query(
      `SELECT id, email, name, active, created_at AS "createdAt", updated_at AS "updatedAt"
       FROM platform_admins
       ORDER BY created_at DESC`,
    );
  }

  async setActive(id: string, active: boolean, actorId: string) {
    const rows = await this.dataSource.query(
      `UPDATE platform_admins
       SET active = $2, updated_at = now()
       WHERE id = $1
       RETURNING id, email, name, active`,
      [id, active],
    );
    if (!rows[0]) {
      throw new UnauthorizedException(
        'Administrador de plataforma no encontrado',
      );
    }
    if (!active) {
      await this.revokeSessions(id);
    }
    await this.auditService.record({
      actorId,
      action: active
        ? 'PLATFORM_ADMIN_ACTIVATED'
        : 'PLATFORM_ADMIN_DEACTIVATED',
      resource: 'platform_admin',
      resourceId: id,
    });
    return rows[0];
  }

  async revokeSessions(adminId: string) {
    await this.dataSource.query(
      `UPDATE platform_sessions
       SET revoked_at = now()
       WHERE admin_id = $1 AND revoked_at IS NULL`,
      [adminId],
    );
  }
}
