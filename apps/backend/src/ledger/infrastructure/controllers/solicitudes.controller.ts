import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Query,
  Body,
  UseGuards,
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

@Controller('solicitudes')
@UseGuards(JwtAuthGuard)
export class SolicitudesController {
  constructor(private readonly solicitudRepo: SolicitudRepository) {}

  @Post()
  async crear(
    @Body() dto: { cuotaId: string; tipo: string; descripcion: string },
    @CurrentUser() user: Usuario,
    @CurrentTenant() tenantId: string,
  ) {
    const solicitud = Solicitud.crear(
      tenantId,
      user.id,
      dto.cuotaId,
      dto.tipo,
      dto.descripcion,
    );
    return this.solicitudRepo.save(solicitud);
  }

  @Get()
  async listar(@CurrentUser() user: Usuario) {
    return this.solicitudRepo.findByUsuario(user.id);
  }

  @Get('pendientes')
  async listarPendientes(@CurrentUser() user: Usuario) {
    return this.solicitudRepo.findPendingByUsuario(user.id);
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

  @Patch(':id/resolver')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async resolver(
    @Param('id') id: string,
    @Body() dto: { estado: string; respuesta: string },
  ) {
    const solicitud = await this.solicitudRepo.findById(id);
    if (!solicitud) {
      throw new NotFoundException(`Solicitud ${id} no encontrada`);
    }

    const estadoValido = dto.estado === 'RESUELTA' || dto.estado === 'RECHAZADA';
    if (!estadoValido) {
      throw new BadRequestException(
        'Estado debe ser RESUELTA o RECHAZADA',
      );
    }

    if (!dto.respuesta || dto.respuesta.trim().length === 0) {
      throw new BadRequestException('La respuesta es obligatoria');
    }

    solicitud.estado = dto.estado as SolicitudEstado;
    solicitud.respuesta = dto.respuesta.trim();
    solicitud.fechaRespuesta = new Date();

    return this.solicitudRepo.save(solicitud);
  }
}
