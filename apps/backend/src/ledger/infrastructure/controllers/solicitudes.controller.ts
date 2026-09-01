import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Query,
  Body,
  UseGuards,
  UseInterceptors,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { SolicitudRepository } from '../persistence/solicitud.repository';
import { Solicitud, SolicitudEstado } from '../../domain/solicitud.entity';
import { JwtAuthGuard } from '../../../shared/auth/jwt-auth.guard';
import { CurrentUser } from '../../../shared/tenant/current-user.decorator';
import { CurrentTenant } from '../../../shared/tenant/current-tenant.decorator';
import { RolesGuard } from '../../../shared/auth/guards/roles.guard';
import { Roles } from '../../../shared/auth/decorators/roles.decorator';
import { Usuario, RolUsuario } from '../../../iam/domain/usuario.entity';
import {
  RegistrarActividad,
  ActividadInterceptor,
} from '../../../shared/common/decorators/registrar-actividad.decorator';

@Controller('solicitudes')
@UseGuards(JwtAuthGuard)
export class SolicitudesController {
  constructor(private readonly solicitudRepo: SolicitudRepository) {}

  @Post()
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.RESIDENTE, RolUsuario.ADMIN)
  @UseInterceptors(ActividadInterceptor)
  @RegistrarActividad({
    tipo: 'SOLICITUD',
    descripcionFn: (r) => `Nueva solicitud creada: ${r.tipo ?? 'Solicitud de cobro'}`,
    metadataFn: (r) => ({
      solicitudId: r.id,
      cobroId: r.cobroId,
      tipo: r.tipo,
      estado: r.estado,
      descripcion: r.descripcion,
    }),
  })
  async crear(
    @Body() dto: { cuotaId?: string; cobroId?: string; tipo: string; descripcion: string },
    @CurrentUser() user: Usuario,
    @CurrentTenant() tenantId: string,
  ) {
    const targetCobroId = dto.cobroId || dto.cuotaId;
    if (!targetCobroId) {
      throw new BadRequestException('Se requiere cobroId o cuotaId');
    }
    const solicitud = Solicitud.crear(
      tenantId,
      user.id,
      targetCobroId,
      dto.tipo,
      dto.descripcion,
    );
    return this.solicitudRepo.save(solicitud);
  }

  @Get()
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.RESIDENTE, RolUsuario.ADMIN)
  async listar(@CurrentUser() user: Usuario) {
    return this.solicitudRepo.findByUsuario(user.id);
  }

  @Get('pendientes')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN, RolUsuario.COBRADOR)
  async listarPendientes(@CurrentTenant() tenantId: string) {
    return this.solicitudRepo.findPendingByTenant(tenantId);
  }

  @Get('admin')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN, RolUsuario.COBRADOR)
  async listarAdmin(@CurrentTenant() tenantId: string) {
    return this.solicitudRepo.findByTenant(tenantId);
  }

  @Get('admin/pendientes')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN, RolUsuario.COBRADOR)
  async listarPendientesAdmin(@CurrentTenant() tenantId: string) {
    return this.solicitudRepo.findPendingByTenant(tenantId);
  }

  @Patch(':id/en-camino')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.COBRADOR, RolUsuario.ADMIN)
  @UseInterceptors(ActividadInterceptor)
  @RegistrarActividad({
    tipo: 'SOLICITUD',
    descripcionFn: (r) => `Cobrador en camino a la casa para la solicitud ${r.nroRecibo}`,
    metadataFn: (r) => ({
      solicitudId: r.id,
      cobroId: r.cobroId,
      tipo: r.tipo,
      estado: r.estado,
    }),
  })
  async marcarEnCamino(@Param('id') id: string) {
    const solicitud = await this.solicitudRepo.findById(id);
    if (!solicitud) {
      throw new NotFoundException(`Solicitud ${id} no encontrada`);
    }
    solicitud.estado = SolicitudEstado.EN_CAMINO;
    return this.solicitudRepo.save(solicitud);
  }

  @Patch(':id/resolver')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN, RolUsuario.COBRADOR)
  @UseInterceptors(ActividadInterceptor)
  @RegistrarActividad({
    tipo: 'SOLICITUD',
    descripcionFn: (r) => `Solicitud ${r.estado}: ${r.respuesta ?? ''}`,
    metadataFn: (r) => ({
      solicitudId: r.id,
      cobroId: r.cobroId,
      tipo: r.tipo,
      estado: r.estado,
      respuesta: r.respuesta,
    }),
  })
  async resolver(
    @Param('id') id: string,
    @Body() dto: { estado: string; respuesta?: string },
  ) {
    const solicitud = await this.solicitudRepo.findById(id);
    if (!solicitud) {
      throw new NotFoundException(`Solicitud ${id} no encontrada`);
    }

    const estadosValidos = [
      SolicitudEstado.RESUELTA,
      SolicitudEstado.COBRADA,
      SolicitudEstado.APROBADA,
      SolicitudEstado.RECHAZADA,
      SolicitudEstado.EN_CAMINO,
    ];
    if (!estadosValidos.includes(dto.estado as SolicitudEstado)) {
      throw new BadRequestException(
        `Estado no válido: ${dto.estado}. Debe ser uno de ${estadosValidos.join(', ')}`,
      );
    }

    solicitud.estado = dto.estado as SolicitudEstado;
    if (dto.respuesta && dto.respuesta.trim().length > 0) {
      solicitud.respuesta = dto.respuesta.trim();
    }
    solicitud.fechaRespuesta = new Date();

    return this.solicitudRepo.save(solicitud);
  }
}
