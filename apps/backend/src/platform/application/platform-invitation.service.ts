import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DataSource } from 'typeorm';
import { randomBytes, createHash, randomUUID } from 'node:crypto';
import bcrypt from 'bcrypt';
import { PlatformAuditService } from '../domain/platform-audit.service';

export interface TenantInvitationDto {
  id: string;
  tenantId: string;
  email: string;
  name: string;
  status: string;
  expiresAt: Date;
  acceptedAt: Date | null;
  createdBy: string;
  createdAt: Date;
  invitationToken?: string;
}

@Injectable()
export class PlatformInvitationService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly auditService: PlatformAuditService,
  ) {}

  async createInvitation(
    tenantId: string,
    email: string,
    name: string,
    actorId: string,
    requestId?: string,
    ipAddress?: string,
  ): Promise<TenantInvitationDto> {
    const cleanEmail = email.trim().toLowerCase();
    const cleanName = name.trim();

    // 1. Validar que el tenant exista
    const tenantRows = await this.dataSource.query(
      'SELECT id, name, status FROM tenants WHERE id = $1',
      [tenantId],
    );
    if (tenantRows.length === 0) {
      throw new NotFoundException(`Tenant con ID ${tenantId} no encontrado`);
    }

    // 2. Validar que no sea ya un ADMIN activo en este tenant
    const existingAdmin = await this.dataSource.query(
      "SELECT id FROM usuarios WHERE tenant_id = $1 AND email = $2 AND rol = 'ADMIN' AND activo = true",
      [tenantId, cleanEmail],
    );
    if (existingAdmin.length > 0) {
      throw new BadRequestException(
        `El correo ${cleanEmail} ya está registrado como administrador activo en este tenant`,
      );
    }

    // 3. Revocar invitaciones previas PENDING para el mismo correo y tenant (reenvío limpio)
    await this.dataSource.query(
      "UPDATE tenant_invitations SET status = 'REVOKED', updated_at = now() WHERE tenant_id = $1 AND email = $2 AND status = 'PENDING'",
      [tenantId, cleanEmail],
    );

    // 4. Generar token criptográfico seguro y su hash SHA-256
    const rawToken = randomBytes(32).toString('hex');
    const tokenHash = createHash('sha256').update(rawToken).digest('hex');
    const id = randomUUID();

    const insertRows = await this.dataSource.query(
      `INSERT INTO tenant_invitations (
        id, tenant_id, email, name, token_hash, status, expires_at, created_by, created_at, updated_at
      )
      VALUES ($1, $2, $3, $4, $5, 'PENDING', now() + interval '48 hours', $6, now(), now())
      RETURNING id, tenant_id AS "tenantId", email, name, status, expires_at AS "expiresAt", accepted_at AS "acceptedAt", created_by AS "createdBy", created_at AS "createdAt"`,
      [id, tenantId, cleanEmail, cleanName, tokenHash, actorId],
    );

    const invitation = insertRows[0];

    // 5. Registrar auditoría inmutable
    await this.auditService.record({
      actorId,
      action: 'ADMIN_INVITATION_CREATED',
      resource: 'tenant_invitation',
      resourceId: id,
      requestId,
      ipAddress,
      metadata: {
        tenantId,
        email: cleanEmail,
        name: cleanName,
        expiresAt: invitation.expiresAt,
      },
    });

    return {
      ...invitation,
      invitationToken: rawToken,
    };
  }

  async listInvitations(tenantId: string): Promise<TenantInvitationDto[]> {
    const rows = await this.dataSource.query(
      `SELECT id, tenant_id AS "tenantId", email, name, status,
              expires_at AS "expiresAt", accepted_at AS "acceptedAt",
              created_by AS "createdBy", created_at AS "createdAt"
       FROM tenant_invitations
       WHERE tenant_id = $1
       ORDER BY created_at DESC`,
      [tenantId],
    );
    return rows;
  }

  async revokeInvitation(
    invitationId: string,
    actorId: string,
    requestId?: string,
    ipAddress?: string,
  ): Promise<{ success: boolean }> {
    const result = await this.dataSource.query(
      "UPDATE tenant_invitations SET status = 'REVOKED', updated_at = now() WHERE id = $1 AND status = 'PENDING' RETURNING id, tenant_id, email",
      [invitationId],
    );

    const rows = Array.isArray(result[0]) ? result[0] : result;
    if (!rows || rows.length === 0) {
      throw new NotFoundException(
        'Invitación no encontrada o no se encuentra en estado pendiente',
      );
    }

    const row = rows[0];
    await this.auditService.record({
      actorId,
      action: 'ADMIN_INVITATION_REVOKED',
      resource: 'tenant_invitation',
      resourceId: invitationId,
      requestId,
      ipAddress,
      metadata: {
        tenantId: row.tenant_id,
        email: row.email,
      },
    });

    return { success: true };
  }

  async acceptInvitation(
    rawToken: string,
    password: string,
    requestId?: string,
    ipAddress?: string,
  ): Promise<{ success: boolean; email: string; tenantId: string }> {
    const cleanToken = rawToken.trim();
    const tokenHash = createHash('sha256').update(cleanToken).digest('hex');

    const inviteRows = await this.dataSource.query(
      'SELECT id, tenant_id, email, name, status, expires_at FROM tenant_invitations WHERE token_hash = $1',
      [tokenHash],
    );

    if (inviteRows.length === 0) {
      throw new BadRequestException(
        'El enlace de invitación es inválido o no existe',
      );
    }

    const invite = inviteRows[0];
    if (invite.status !== 'PENDING') {
      throw new BadRequestException(
        `Esta invitación ya no está activa (estado: ${invite.status})`,
      );
    }

    if (new Date(invite.expires_at) < new Date()) {
      await this.dataSource.query(
        "UPDATE tenant_invitations SET status = 'EXPIRED', updated_at = now() WHERE id = $1",
        [invite.id],
      );
      throw new BadRequestException(
        'La invitación ha expirado. Solicita una nueva.',
      );
    }

    const passwordHash = bcrypt.hashSync(password, 10);

    // Transaccional: crear o activar el usuario como ADMIN y consumir la invitación
    await this.dataSource.transaction(async (manager) => {
      // 1. Consumir la invitación
      await manager.query(
        "UPDATE tenant_invitations SET status = 'ACCEPTED', accepted_at = now(), updated_at = now() WHERE id = $1",
        [invite.id],
      );

      // 2. Crear o actualizar el usuario
      const existingUser = await manager.query(
        'SELECT id FROM usuarios WHERE email = $1',
        [invite.email],
      );

      if (existingUser.length > 0) {
        await manager.query(
          `UPDATE usuarios
           SET nombre = $1, password_hash = $2, rol = 'ADMIN', tenant_id = $3, activo = true, updated_at = now()
           WHERE id = $4`,
          [invite.name, passwordHash, invite.tenant_id, existingUser[0].id],
        );
      } else {
        await manager.query(
          `INSERT INTO usuarios (id, email, password_hash, nombre, rol, tenant_id, activo, created_at, updated_at)
           VALUES ($1, $2, $3, $4, 'ADMIN', $5, true, now(), now())`,
          [
            randomUUID(),
            invite.email,
            passwordHash,
            invite.name,
            invite.tenant_id,
          ],
        );
      }
    });

    // 3. Auditar activación
    await this.auditService.record({
      actorId: invite.email,
      action: 'ADMIN_ACTIVATED',
      resource: 'usuario',
      requestId,
      ipAddress,
      metadata: {
        tenantId: invite.tenant_id,
        email: invite.email,
        name: invite.name,
      },
    });

    return {
      success: true,
      email: invite.email,
      tenantId: invite.tenant_id,
    };
  }
}
