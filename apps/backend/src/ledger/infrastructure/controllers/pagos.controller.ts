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
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { RegistrarPagoUseCase } from '../../application/use-cases/registrar-pago.use-case';
import { EliminarPagoUseCase } from '../../application/use-cases/eliminar-pago.use-case';
import { CorregirPagoUseCase } from '../../application/use-cases/corregir-pago.use-case';
import { ValidarPagoUseCase } from '../../application/use-cases/validar-pago.use-case';
import { PagoRepository } from '../persistence/pago.repository';
import { RegistrarPagoDto } from './dtos/pagos.dto';
import { JwtAuthGuard } from '../../../shared/auth/jwt-auth.guard';
import { MantenimientoService } from '../../../community/application/services/mantenimiento.service';
import { RolesGuard } from '../../../shared/auth/guards/roles.guard';
import { Roles } from '../../../shared/auth/decorators/roles.decorator';
import { CurrentUser } from '../../../shared/tenant/current-user.decorator';
import { CurrentTenant } from '../../../shared/tenant/current-tenant.decorator';
import { RolUsuario, Usuario } from '../../../iam/domain/usuario.entity';
import { EstadoValidacionPago } from '../../domain/pago.entity';
import {
  RegistrarActividad,
  ActividadInterceptor,
} from '../../../shared/common/decorators/registrar-actividad.decorator';

@ApiTags('Pagos')
@ApiBearerAuth('jwt-auth')
@Controller('pagos')
@UseGuards(JwtAuthGuard)
export class PagosController {
  constructor(
    private readonly registrarPagoUC: RegistrarPagoUseCase,
    private readonly eliminarPagoUC: EliminarPagoUseCase,
    private readonly corregirPagoUC: CorregirPagoUseCase,
    private readonly validarPagoUC: ValidarPagoUseCase,
    private readonly pagoRepo: PagoRepository,
    private readonly mantenimientoService: MantenimientoService,
  ) {}

  @Post()
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN, RolUsuario.COBRADOR)
  @UseInterceptors(ActividadInterceptor)
  @RegistrarActividad({
    tipo: 'PAGO',
    descripcionFn: (result) =>
      `Pago registrado: $${((result.pago?.monto ?? 0) / 100).toFixed(0)} COP (${result.cobrosAfectados?.length ?? result.cuotasAfectadas?.length ?? 0} cuota(s))`,
    metadataFn: (result) => ({
      pagoId: result.pago?.id,
      monto: result.pago?.monto,
      residenteId: result.pago?.residenteId,
      cobradorId: result.pago?.cobradorId,
      cobradorNombre: result.pago?.cobradorNombre,
      clientPaymentId: result.pago?.clientPaymentId,
      solicitudId: result.pago?.solicitudId,
    }),
  })
  @ApiOperation({ summary: 'Registrar pago (Cobrador/ADMIN)' })
  async registrar(
    @Body() dto: RegistrarPagoDto,
    @CurrentUser() user: Usuario,
    @CurrentTenant() tenantId: string,
  ) {
    // Verificar mantenimiento — solo bloquea a COBRADOR, el ADMIN nunca se bloquea
    if (user.rol !== RolUsuario.ADMIN) {
      await this.mantenimientoService.verificarResidenteNoBloqueado(
        dto.residenteId,
      );
    }

    return this.registrarPagoUC.execute({
      clientPaymentId: dto.clientPaymentId,
      monto: dto.monto,
      fechaPago: dto.fechaPago,
      residenteId: dto.residenteId,
      cobradorId: user.id,
      cobradorNombre: user.nombre,
      tenantId,
      solicitudId: dto.solicitudId,
    });
  }

  @Patch(':id/corregir')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN, RolUsuario.COBRADOR)
  @UseInterceptors(ActividadInterceptor)
  @RegistrarActividad({
    tipo: 'PAGO',
    descripcionFn: (result) =>
      `Monto de pago corregido a: $${(result.monto / 100).toFixed(0)} COP`,
  })
  @ApiOperation({ summary: 'Corregir monto de un pago registrado' })
  async corregir(
    @Param('id') pagoId: string,
    @Body() dto: { nuevoMonto: number; motivo: string },
    @CurrentUser() user: Usuario,
    @CurrentTenant() tenantId: string,
  ) {
    return this.corregirPagoUC.execute({
      pagoId,
      nuevoMonto: dto.nuevoMonto,
      motivo: dto.motivo,
      usuarioId: user.id,
      tenantId,
    });
  }

  @Patch(':id/validar')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  @UseInterceptors(ActividadInterceptor)
  @RegistrarActividad({
    tipo: 'PAGO',
    descripcionFn: (result) =>
      `Pago ${result.id} marcado como ${result.estado}`,
  })
  @ApiOperation({ summary: 'Validar o rechazar un pago (solo ADMIN)' })
  async validar(
    @Param('id') pagoId: string,
    @Body() dto: { estado: string },
    @CurrentTenant() tenantId: string,
  ) {
    const estadoEnum = dto.estado as
      EstadoValidacionPago.VALIDADO | EstadoValidacionPago.RECHAZADO;
    return this.validarPagoUC.execute({
      pagoId,
      estado: estadoEnum,
      tenantId,
    });
  }

  @Get(':id')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN, RolUsuario.COBRADOR)
  async getById(@Param('id') id: string, @CurrentTenant() tenantId: string) {
    const pago = await this.pagoRepo.findById(id);
    if (!pago || pago.tenantId !== tenantId) {
      throw new NotFoundException(`Pago ${id} no encontrado`);
    }
    return pago;
  }

  @Get('cobrador/mis-cobros')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN, RolUsuario.COBRADOR)
  async listCobrosPorCobrador(
    @CurrentUser() user: Usuario,
    @CurrentTenant() tenantId: string,
  ) {
    const pagos = await this.pagoRepo.findByCobrador(user.id, tenantId);
    return pagos.map((pago) => {
      const residente = pago.residente;
      const casa = pago.cobro?.casa ?? residente?.casaActual;
      const manzana = casa?.manzana;
      const etapa = manzana?.etapa;

      return {
        ...pago,
        residenteNombre: residente?.nombre ?? 'Residente',
        cobradorNombre: pago.cobrador?.nombre ?? user.nombre,
        nroRecibo:
          pago.clientPaymentId ||
          `TK-${pago.id.replace(/-/g, '').substring(0, 6).toUpperCase()}`,
        casaDireccion: casa?.direccionInterna ?? 'Inmueble',
        manzanaNombre: manzana?.nombre ?? 'Manzana',
        etapaNombre: etapa?.nombre ?? 'Etapa',
        esViaSolicitud: Boolean((pago as any).solicitudId),
      };
    });
  }

  @Get()
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN, RolUsuario.COBRADOR, RolUsuario.RESIDENTE)
  async listByResidente(
    @Query('residenteId') residenteId: string,
    @CurrentUser() user: Usuario,
    @CurrentTenant() tenantId: string,
  ) {
    const targetId =
      user.rol === RolUsuario.RESIDENTE
        ? (user.residenteId ?? residenteId)
        : (residenteId ?? user.residenteId);

    if (!targetId) return [];
    const pagos = await this.pagoRepo.findByPropietario(targetId, tenantId);
    return pagos.map((pago) => {
      const residente = pago.residente;
      const casa = pago.cobro?.casa ?? residente?.casaActual;
      const manzana = casa?.manzana;
      const etapa = manzana?.etapa;

      return {
        ...pago,
        residenteNombre: residente?.nombre ?? 'Residente',
        cobradorNombre: pago.cobrador?.nombre ?? 'Administración',
        nroRecibo:
          pago.clientPaymentId ||
          `TK-${pago.id.replace(/-/g, '').substring(0, 6).toUpperCase()}`,
        casaDireccion: casa?.direccionInterna ?? 'Inmueble',
        manzanaNombre: manzana?.nombre ?? 'Manzana',
        etapaNombre: etapa?.nombre ?? 'Etapa',
        esViaSolicitud: Boolean((pago as any).solicitudId),
        residente: residente
          ? {
              id: residente.id,
              nombre: residente.nombre,
            }
          : null,
        casa: casa
          ? {
              id: casa.id,
              direccionInterna: casa.direccionInterna,
              manzana: manzana
                ? {
                    id: manzana.id,
                    nombre: manzana.nombre,
                    etapa: etapa
                      ? {
                          id: etapa.id,
                          nombre: etapa.nombre,
                        }
                      : null,
                  }
                : null,
            }
          : null,
      };
    });
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  @UseInterceptors(ActividadInterceptor)
  @RegistrarActividad({
    tipo: 'PAGO',
    descripcionFn: (result) => `Pago reversado/eliminado correctamente`,
  })
  @ApiOperation({ summary: 'Eliminar/revertir un pago (solo ADMIN)' })
  async eliminar(@Param('id') id: string, @CurrentTenant() tenantId: string) {
    await this.eliminarPagoUC.execute(id, tenantId);
    return { success: true };
  }
}
