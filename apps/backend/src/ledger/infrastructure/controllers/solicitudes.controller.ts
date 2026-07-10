import {
  Controller,
  Get,
  Post,
  Body,
  UseGuards,
} from '@nestjs/common';
import { SolicitudRepository } from '../persistence/solicitud.repository';
import { Solicitud } from '../../domain/solicitud.entity';
import { JwtAuthGuard } from '../../../shared/auth/jwt-auth.guard';
import { CurrentUser } from '../../../shared/tenant/current-user.decorator';
import { CurrentTenant } from '../../../shared/tenant/current-tenant.decorator';
import { Usuario } from '../../../iam/domain/usuario.entity';

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
}
