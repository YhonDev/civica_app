import {
  BadRequestException,
  Controller,
  Get,
  Body,
  Patch,
  Param,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import type { Request } from 'express';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { AccessScope } from '../../domain/access-scope.enum';
import { RequireScope } from '../../decorators/require-scope.decorator';
import { PlatformAdminGuard } from '../../guards/platform-admin.guard';
import { PlatformOverviewService } from '../../application/platform-overview.service';
import { TenantStatus } from '../../domain/tenant-status.enum';
import { PlatformAuditService } from '../../domain/platform-audit.service';
import { PlatformAuthService } from '../../application/platform-auth.service';
import { PlatformInvitationService } from '../../application/platform-invitation.service';
import {
  IsBoolean,
  IsEmail,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  MinLength,
} from 'class-validator';

class CreatePlatformAdministratorDto {
  @IsEmail()
  email: string;
  @IsString()
  @IsNotEmpty()
  name: string;
  @IsString()
  @MinLength(12)
  password: string;
}

class SetAdministratorStatusDto {
  @IsBoolean()
  active: boolean;
}

class CreateTenantDto {
  @IsString()
  @IsNotEmpty({ message: 'El nombre del tenant es obligatorio' })
  name: string;

  @IsOptional()
  @IsEnum(TenantStatus, { message: 'Estado de tenant inválido' })
  status?: TenantStatus;
}

class UpdateTenantStatusDto {
  @IsEnum(TenantStatus, { message: 'Estado de tenant inválido' })
  status: TenantStatus;
}

class InviteTenantAdminDto {
  @IsEmail({}, { message: 'Debe ingresar un correo electrónico válido' })
  email: string;

  @IsString()
  @IsNotEmpty({ message: 'El nombre del administrador es obligatorio' })
  name: string;
}

@ApiTags('Platform')
@ApiBearerAuth('jwt-auth')
@Controller('platform')
@UseGuards(PlatformAdminGuard)
@RequireScope(AccessScope.PLATFORM)
export class PlatformAdminController {
  constructor(
    private readonly overviewService: PlatformOverviewService,
    private readonly auditService: PlatformAuditService,
    private readonly authService: PlatformAuthService,
    private readonly invitationService: PlatformInvitationService,
  ) {}

  @Get('health')
  @ApiOperation({ summary: 'Health check de Cuentiva Platform' })
  async health(@Req() request: Request) {
    await this.audit(request, 'PLATFORM_HEALTH_READ', 'platform');
    return { status: 'ok', scope: AccessScope.PLATFORM };
  }

  @Get('overview')
  @ApiOperation({ summary: 'Resumen global de Cuentiva Platform' })
  async overview(@Req() request: Request) {
    const result = await this.overviewService.overview();
    await this.audit(request, 'PLATFORM_OVERVIEW_READ', 'platform');
    return result;
  }

  @Get('tenants')
  @ApiOperation({ summary: 'Inventario paginado de tenants' })
  async tenants(
    @Req() request: Request,
    @Query('page') pageParam = '1',
    @Query('limit') limitParam = '25',
    @Query('status') status?: TenantStatus,
  ) {
    const page = this.parsePositiveInteger(pageParam, 'page');
    const limit = Math.min(this.parsePositiveInteger(limitParam, 'limit'), 100);
    if (status && !Object.values(TenantStatus).includes(status)) {
      throw new BadRequestException('Estado de tenant inválido');
    }
    const result = await this.overviewService.listTenants(page, limit, status);
    await this.audit(request, 'PLATFORM_TENANTS_READ', 'tenant', undefined, {
      page,
      limit,
      status,
    });
    return result;
  }

  @Post('tenants')
  @ApiOperation({ summary: 'Crea un nuevo tenant en Cuentiva Platform' })
  async createTenant(
    @Body() dto: CreateTenantDto,
    @Req() request: Request,
  ) {
    const result = await this.overviewService.createTenant(dto.name, dto.status);
    await this.audit(request, 'TENANT_CREATED', 'tenant', result.id, {
      name: result.name,
      status: result.status,
    });
    return result;
  }

  @Get('tenants/:id')
  @ApiOperation({
    summary:
      'Consulta el detalle de un tenant con sus proyectos y administradores',
  })
  async tenantDetail(@Param('id') id: string, @Req() request: Request) {
    const result = await this.overviewService.getTenantDetail(id);
    await this.audit(request, 'TENANT_DETAIL_READ', 'tenant', id);
    return result;
  }

  @Patch('tenants/:id/status')
  @ApiOperation({
    summary:
      'Actualiza el estado de un tenant (activar, suspender, mantenimiento, archivar)',
  })
  async updateTenantStatus(
    @Param('id') id: string,
    @Body() dto: UpdateTenantStatusDto,
    @Req() request: Request,
  ) {
    const result = await this.overviewService.updateTenantStatus(id, dto.status);
    const auditAction =
      dto.status === TenantStatus.SUSPENDED
        ? 'TENANT_SUSPENDED'
        : dto.status === TenantStatus.ACTIVE
          ? 'TENANT_ACTIVATED'
          : 'TENANT_STATUS_UPDATED';
    await this.audit(request, auditAction, 'tenant', id, {
      newStatus: dto.status,
    });
    return result;
  }

  @Post('tenants/:id/invitations')
  @ApiOperation({
    summary:
      'Emite una invitación criptográfica de un solo uso para administrador de tenant',
  })
  async inviteTenantAdmin(
    @Param('id') id: string,
    @Body() dto: InviteTenantAdminDto,
    @Req() request: Request,
  ) {
    return this.invitationService.createInvitation(
      id,
      dto.email,
      dto.name,
      this.actorId(request),
      request.header('x-request-id') ?? undefined,
      request.ip,
    );
  }

  @Get('tenants/:id/invitations')
  @ApiOperation({
    summary: 'Lista el historial de invitaciones emitidas para un tenant',
  })
  async listTenantInvitations(
    @Param('id') id: string,
    @Req() request: Request,
  ) {
    await this.audit(request, 'TENANT_INVITATIONS_READ', 'tenant', id);
    return this.invitationService.listInvitations(id);
  }

  @Post('invitations/:id/revoke')
  @ApiOperation({ summary: 'Revoca una invitación pendiente' })
  async revokeInvitation(
    @Param('id') id: string,
    @Req() request: Request,
  ) {
    return this.invitationService.revokeInvitation(
      id,
      this.actorId(request),
      request.header('x-request-id') ?? undefined,
      request.ip,
    );
  }

  @Get('scopes')
  @ApiOperation({ summary: 'Catálogo de scopes de acceso' })
  async scopes(@Req() request: Request) {
    await this.audit(request, 'PLATFORM_SCOPES_READ', 'platform');
    return {
      active: AccessScope.PLATFORM,
      scopes: [
        {
          scope: AccessScope.PLATFORM,
          principal: 'SUPERADMIN',
          status: 'active',
          description: 'Alcance global de administración de la plataforma',
        },
        {
          scope: AccessScope.TENANT,
          principal: 'ADMIN',
          status: 'documented',
          description:
            'Alcance completo del tenantId del administrador operativo',
        },
        {
          scope: AccessScope.PROJECT,
          principal: 'ADMIN',
          status: 'inactive',
          description: 'Alcance reservado para un proyecto específico',
        },
        {
          scope: AccessScope.STAGE,
          principal: 'COBRADOR',
          status: 'documented',
          description: 'Alcance de etapas asignadas',
        },
        {
          scope: AccessScope.OWN_RESOURCE,
          principal: 'RESIDENTE',
          status: 'documented',
          description: 'Alcance de recursos propios',
        },
      ],
    };
  }

  @Get('administrators')
  @ApiOperation({ summary: 'Lista administradores de plataforma' })
  administrators() {
    return this.authService.listAdministrators();
  }

  @Post('administrators')
  @ApiOperation({ summary: 'Crea un administrador de plataforma' })
  createAdministrator(
    @Body() dto: CreatePlatformAdministratorDto,
    @Req() request: Request,
  ) {
    return this.authService.createAdministrator(
      dto.email,
      dto.name,
      dto.password,
      this.actorId(request),
    );
  }

  @Patch('administrators/:id/status')
  @ApiOperation({
    summary: 'Activa o desactiva un administrador de plataforma',
  })
  setAdministratorStatus(
    @Param('id') id: string,
    @Body() dto: SetAdministratorStatusDto,
    @Req() request: Request,
  ) {
    return this.authService.setActive(id, dto.active, this.actorId(request));
  }

  @Post('administrators/:id/revoke-sessions')
  @ApiOperation({ summary: 'Revoca sesiones de un administrador' })
  async revokeAdministratorSessions(
    @Param('id') id: string,
    @Req() request: Request,
  ) {
    await this.authService.revokeSessions(id);
    await this.audit(
      request,
      'PLATFORM_SESSIONS_REVOKED',
      'platform_admin',
      id,
    );
    return { success: true };
  }

  @Get('audit')
  @ApiOperation({ summary: 'Auditoría durable de Cuentiva Platform' })
  auditEvents(
    @Query('page') pageParam = '1',
    @Query('limit') limitParam = '25',
    @Query('action') action?: string,
    @Query('resource') resource?: string,
  ) {
    const page = this.parsePositiveInteger(pageParam, 'page');
    const limit = Math.min(this.parsePositiveInteger(limitParam, 'limit'), 100);
    return this.auditService.list({ page, limit, action, resource });
  }

  private async audit(
    request: Request,
    action: string,
    resource: string,
    resourceId?: string,
    metadata?: Record<string, unknown>,
  ): Promise<void> {
    await this.auditService.record({
      actorId: this.actorId(request),
      action,
      resource,
      resourceId,
      requestId: request.header('x-request-id') ?? undefined,
      ipAddress: request.ip,
      metadata,
    });
  }

  private actorId(request: Request): string {
    const actorId = Reflect.get(request.user ?? {}, 'sub');
    if (typeof actorId !== 'string' || actorId.length === 0) {
      throw new BadRequestException('Principal de plataforma inválido');
    }
    return actorId;
  }

  private parsePositiveInteger(value: string, parameter: string): number {
    const parsed = Number(value);
    if (!Number.isInteger(parsed) || parsed < 1) {
      throw new BadRequestException(
        `El parámetro ${parameter} debe ser un entero positivo`,
      );
    }
    return parsed;
  }
}
