import {
  Controller,
  Get,
  Post,
  Delete,
  Param,
  Query,
  Body,
  UseGuards,
  UseInterceptors,
  NotFoundException,
} from '@nestjs/common';
import { RegistrarPagoUseCase } from '../../application/use-cases/registrar-pago.use-case';
import { EliminarPagoUseCase } from '../../application/use-cases/eliminar-pago.use-case';
import { PagoRepository } from '../persistence/pago.repository';
import { RegistrarPagoDto } from './dtos/pagos.dto';
import { JwtAuthGuard } from '../../../shared/auth/jwt-auth.guard';
import { RolesGuard } from '../../../shared/auth/guards/roles.guard';
import { Roles } from '../../../shared/auth/decorators/roles.decorator';
import { CurrentUser } from '../../../shared/tenant/current-user.decorator';
import { CurrentTenant } from '../../../shared/tenant/current-tenant.decorator';
import { RolUsuario } from '../../../iam/domain/usuario.entity';
import { Usuario } from '../../../iam/domain/usuario.entity';
import {
  RegistrarActividad,
  ActividadInterceptor,
} from '../../../shared/common/decorators/registrar-actividad.decorator';

@Controller('pagos')
@UseGuards(JwtAuthGuard)
export class PagosController {
  constructor(
    private readonly registrarPagoUC: RegistrarPagoUseCase,
    private readonly eliminarPagoUC: EliminarPagoUseCase,
    private readonly pagoRepo: PagoRepository,
  ) {}

  @Post()
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN, RolUsuario.COBRADOR)
  @UseInterceptors(ActividadInterceptor)
  @RegistrarActividad({
    tipo: 'PAGO',
    descripcionFn: (result) =>
      `Pago registrado: $${(result.pago.monto / 100).toFixed(0)} COP (${result.cuotasAfectadas.length} cuota(s))`,
  })
  async registrar(
    @Body() dto: RegistrarPagoDto,
    @CurrentUser() user: Usuario,
    @CurrentTenant() tenantId: string,
  ) {
    return this.registrarPagoUC.execute({
      clientPaymentId: dto.clientPaymentId,
      monto: dto.monto,
      fechaPago: dto.fechaPago,
      propietarioId: dto.propietarioId,
      cobradorId: user.id,
      tenantId,
      solicitudId: dto.solicitudId,
    });
  }

  @Get(':id')
  async getById(@Param('id') id: string) {
    const pago = await this.pagoRepo.findById(id);
    if (!pago) {
      throw new NotFoundException(`Pago ${id} no encontrado`);
    }
    return pago;
  }

  @Get()
  async listByPropietario(@Query('propietarioId') propietarioId: string) {
    return this.pagoRepo.findByPropietario(propietarioId);
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  @UseInterceptors(ActividadInterceptor)
  @RegistrarActividad({
    tipo: 'PAGO',
    descripcionFn: (result) => `Pago reversado/eliminado correctamente`,
  })
  async eliminar(
    @Param('id') id: string,
    @CurrentTenant() tenantId: string,
  ) {
    await this.eliminarPagoUC.execute(id, tenantId);
    return { success: true };
  }
}
