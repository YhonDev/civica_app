import { Controller, Get, Post, Param, UseGuards, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtAuthGuard } from '../../../shared/auth/jwt-auth.guard';
import { RolesGuard } from '../../../shared/auth/guards/roles.guard';
import { Roles } from '../../../shared/auth/decorators/roles.decorator';
import { RolUsuario } from '../../../iam/domain/usuario.entity';
import { Notificacion, EstadoNotificacion } from '../../domain/notificacion.entity';
import { CurrentTenant } from '../../../shared/tenant/current-tenant.decorator';

@Controller('notificaciones')
@UseGuards(JwtAuthGuard, RolesGuard)
export class NotificacionesController {
  constructor(
    @InjectRepository(Notificacion)
    private readonly notificacionRepository: Repository<Notificacion>,
  ) {}

  @Get('fallidas')
  @Roles(RolUsuario.ADMIN)
  async listarFallidas(@CurrentTenant() tenantId: string) {
    return this.notificacionRepository.find({
      where: { tenantId, estado: EstadoNotificacion.FALLIDA },
      order: { createdAt: 'DESC' },
    });
  }

  @Post(':id/reintentar')
  @Roles(RolUsuario.ADMIN)
  async reintentar(@Param('id') id: string, @CurrentTenant() tenantId: string) {
    const notif = await this.notificacionRepository.findOne({
      where: { id, tenantId },
    });

    if (!notif) {
      throw new NotFoundException('Notificación no encontrada');
    }

    notif.intentos = 0;
    notif.estado = EstadoNotificacion.PENDIENTE;
    await this.notificacionRepository.save(notif);

    return { message: 'Notificación reiniciada para reintento', notificacion: notif };
  }
}
