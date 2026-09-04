import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Query,
  Body,
  UseGuards,
  UseInterceptors,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { SolicitudRepository } from '../persistence/solicitud.repository';
import { CobroRepository } from '../persistence/cobro.repository';
import { PagoRepository } from '../persistence/pago.repository';
import { TicketRepository } from '../persistence/ticket.repository';
import { CorregirPagoUseCase } from '../../application/use-cases/corregir-pago.use-case';
import { EliminarPagoUseCase } from '../../application/use-cases/eliminar-pago.use-case';
import { Solicitud, SolicitudEstado } from '../../domain/solicitud.entity';
import { Pago, EstadoValidacionPago } from '../../domain/pago.entity';
import { Ticket } from '../../domain/ticket.entity';
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

@ApiTags('Solicitudes')
@ApiBearerAuth('jwt-auth')
@Controller('solicitudes')
@UseGuards(JwtAuthGuard)
export class SolicitudesController {
  constructor(
    private readonly solicitudRepo: SolicitudRepository,
    private readonly cobroRepo: CobroRepository,
    private readonly pagoRepo: PagoRepository,
    private readonly ticketRepo: TicketRepository,
    private readonly corregirPagoUC: CorregirPagoUseCase,
    private readonly eliminarPagoUC: EliminarPagoUseCase,
  ) {}

  @Post()
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.RESIDENTE, RolUsuario.ADMIN)
  @UseInterceptors(ActividadInterceptor)
  @RegistrarActividad({
    tipo: 'SOLICITUD',
    descripcionFn: (r) =>
      `Nueva solicitud creada: ${r.tipo ?? 'Solicitud de cobro'}`,
    metadataFn: (r) => ({
      solicitudId: r.id,
      cobroId: r.cobroId,
      tipo: r.tipo,
      estado: r.estado,
      descripcion: r.descripcion,
    }),
  })
  @ApiOperation({ summary: 'Crear solicitud de cobro presencial' })
  async crear(
    @Body()
    dto: {
      cuotaId?: string;
      cobroId?: string;
      pagoId?: string;
      tipo: string;
      descripcion: string;
    },
    @CurrentUser() user: Usuario,
    @CurrentTenant() tenantId: string,
  ) {
    const targetCobroId = dto.cobroId || dto.cuotaId;
    if (!targetCobroId) {
      throw new BadRequestException('Se requiere cobroId o cuotaId');
    }
    const cobro = await this.cobroRepo.findById(targetCobroId);
    if (!cobro) {
      throw new NotFoundException(
        `No existe un cobro válido asignado para el id ${targetCobroId}`,
      );
    }
    const solicitud = Solicitud.crear(
      tenantId,
      user.id,
      targetCobroId,
      dto.tipo,
      dto.descripcion,
    );
    if (user.residenteId) {
      solicitud.residenteId = user.residenteId;
    }
    if (dto.pagoId) {
      solicitud.pagoId = dto.pagoId;
    }
    return this.solicitudRepo.save(solicitud);
  }

  @Get()
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.RESIDENTE, RolUsuario.ADMIN)
  @ApiOperation({ summary: 'Listar mis solicitudes' })
  async listar(
    @CurrentUser() user: Usuario,
    @Query('limit') limit?: number,
    @Query('offset') offset?: number,
  ) {
    return this.solicitudRepo.findByUsuario(user.id, limit, offset);
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
  async listarAdmin(
    @CurrentTenant() tenantId: string,
    @Query('limit') limit?: number,
    @Query('offset') offset?: number,
  ) {
    return this.solicitudRepo.findByTenant(tenantId, limit, offset);
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
    descripcionFn: (r) =>
      `Cobrador en camino a la casa para la solicitud ${r.nroRecibo}`,
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
  @ApiOperation({ summary: 'Resolver una solicitud (aprobar/rechazar)' })
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

  @Get(':id/detalle-resolucion')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN, RolUsuario.COBRADOR)
  @ApiOperation({
    summary:
      'Obtener información completa para resolver solicitud (pago, cobro, ticket)',
  })
  async getDetalleResolucion(
    @Param('id') id: string,
    @CurrentTenant() tenantId: string,
  ) {
    const solicitud = await this.solicitudRepo.findById(id);
    if (!solicitud || solicitud.tenantId !== tenantId) {
      throw new NotFoundException(`Solicitud ${id} no encontrada`);
    }

    const cobro = await this.cobroRepo.findById(solicitud.cobroId);

    let pago: Pago | null = null;
    if (solicitud.pagoId) {
      pago = await this.pagoRepo.findById(solicitud.pagoId);
    }
    if (!pago && solicitud.cobroId) {
      const pagos = await this.pagoRepo.findByCobro(solicitud.cobroId);
      if (pagos.length > 0) {
        pago = pagos[0];
      }
    }

    let ticket: Ticket | null = null;
    if (pago) {
      ticket = await this.ticketRepo.findByPago(pago.id);
    }

    return {
      solicitud,
      cobro: cobro
        ? {
            id: cobro.id,
            concepto: cobro.concepto,
            monto: cobro.monto,
            montoPagado: cobro.montoPagado,
            estado: cobro.estado,
            fechaVencimiento: cobro.fechaVencimiento,
          }
        : null,
      pago: pago
        ? {
            id: pago.id,
            monto: pago.monto,
            fechaPago: pago.fechaPago,
            cobradorId: pago.cobradorId,
            cobradorNombre: pago.cobrador?.nombre ?? 'Cobrador',
            estado: pago.estado,
            clientPaymentId: pago.clientPaymentId,
          }
        : null,
      ticket: ticket
        ? {
            id: ticket.id,
            numero: ticket.numero,
            estado: ticket.estado,
            fecha: ticket.fecha,
          }
        : null,
    };
  }

  @Patch(':id/corregir-pago')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  @UseInterceptors(ActividadInterceptor)
  @RegistrarActividad({
    tipo: 'SOLICITUD',
    descripcionFn: (r) => `Pago corregido y solicitud resuelta: ${r.id}`,
    metadataFn: (r) => ({
      solicitudId: r.id,
      pagoId: r.pagoId,
    }),
  })
  @ApiOperation({
    summary:
      'Corregir el valor de un pago asociado y resolver la solicitud (solo ADMIN)',
  })
  async corregirPagoDesdeSolicitud(
    @Param('id') id: string,
    @Body() dto: { nuevoMonto: number; motivo: string },
    @CurrentUser() user: Usuario,
    @CurrentTenant() tenantId: string,
  ) {
    const solicitud = await this.solicitudRepo.findById(id);
    if (!solicitud || solicitud.tenantId !== tenantId) {
      throw new NotFoundException(`Solicitud ${id} no encontrada`);
    }

    let targetPagoId = solicitud.pagoId;
    if (!targetPagoId && solicitud.cobroId) {
      const pagos = await this.pagoRepo.findByCobro(solicitud.cobroId);
      if (pagos.length > 0) targetPagoId = pagos[0].id;
    }

    if (!targetPagoId) {
      throw new BadRequestException(
        'No se encontró un pago asociado a esta solicitud para corregir.',
      );
    }

    const pago = await this.pagoRepo.findById(targetPagoId);
    if (!pago || pago.tenantId !== tenantId) {
      throw new NotFoundException(`Pago ${targetPagoId} no encontrado`);
    }

    if (pago.estado !== EstadoValidacionPago.PENDIENTE_REVISION) {
      pago.estado = EstadoValidacionPago.PENDIENTE_REVISION;
      await this.pagoRepo.saveMany([pago]);
    }

    const pagoCorregido = await this.corregirPagoUC.execute({
      pagoId: targetPagoId,
      nuevoMonto: dto.nuevoMonto,
      motivo: dto.motivo,
      usuarioId: user.id,
      tenantId,
    });

    const montoPesos = (dto.nuevoMonto / 100).toFixed(0);
    solicitud.estado = SolicitudEstado.RESUELTA;
    solicitud.respuesta = `Pago corregido a $${montoPesos} COP por administración. Motivo: ${dto.motivo}`;
    solicitud.fechaRespuesta = new Date();
    await this.solicitudRepo.save(solicitud);

    return {
      success: true,
      solicitud,
      pago: pagoCorregido,
    };
  }

  @Patch(':id/revertir-pago')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  @UseInterceptors(ActividadInterceptor)
  @RegistrarActividad({
    tipo: 'SOLICITUD',
    descripcionFn: (r) => `Pago revertido y solicitud resuelta: ${r.id}`,
    metadataFn: (r) => ({
      solicitudId: r.id,
    }),
  })
  @ApiOperation({
    summary:
      'Revertir / eliminar el pago asociado y resolver la solicitud (solo ADMIN)',
  })
  async revertirPagoDesdeSolicitud(
    @Param('id') id: string,
    @Body() dto: { motivo?: string },
    @CurrentUser() user: Usuario,
    @CurrentTenant() tenantId: string,
  ) {
    const solicitud = await this.solicitudRepo.findById(id);
    if (!solicitud || solicitud.tenantId !== tenantId) {
      throw new NotFoundException(`Solicitud ${id} no encontrada`);
    }

    let targetPagoId = solicitud.pagoId;
    if (!targetPagoId && solicitud.cobroId) {
      const pagos = await this.pagoRepo.findByCobro(solicitud.cobroId);
      if (pagos.length > 0) targetPagoId = pagos[0].id;
    }

    if (!targetPagoId) {
      throw new BadRequestException(
        'No se encontró un pago asociado a esta solicitud para revertir.',
      );
    }

    await this.eliminarPagoUC.execute(targetPagoId, tenantId);

    solicitud.estado = SolicitudEstado.RESUELTA;
    solicitud.respuesta =
      dto.motivo?.trim() ||
      'Pago revertido y cuota liberada por la administración.';
    solicitud.fechaRespuesta = new Date();
    await this.solicitudRepo.save(solicitud);

    return {
      success: true,
      solicitud,
      message: 'Pago revertido y cuota liberada exitosamente.',
    };
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.RESIDENTE, RolUsuario.ADMIN, RolUsuario.COBRADOR)
  @UseInterceptors(ActividadInterceptor)
  @RegistrarActividad({
    tipo: 'SOLICITUD',
    descripcionFn: (r) => `Solicitud ${r.id} eliminada / cancelada`,
    metadataFn: (r) => ({
      solicitudId: r.id,
    }),
  })
  async eliminar(@Param('id') id: string) {
    const solicitud = await this.solicitudRepo.findById(id);
    if (!solicitud) {
      throw new NotFoundException(`Solicitud ${id} no encontrada`);
    }
    if (
      solicitud.estado === SolicitudEstado.COBRADA ||
      solicitud.estado === SolicitudEstado.APROBADA
    ) {
      throw new BadRequestException(
        'No se puede cancelar una solicitud que ya ha sido procesada.',
      );
    }
    await this.solicitudRepo.delete(id);
    return { ok: true, message: 'Solicitud cancelada exitosamente', id };
  }
}
