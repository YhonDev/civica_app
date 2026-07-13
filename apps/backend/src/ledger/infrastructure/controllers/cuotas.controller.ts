import {
  Controller,
  Get,
  Post,
  Param,
  Query,
  Body,
  UseGuards,
  Delete,
} from '@nestjs/common';
import { GenerarCuotasUseCase } from '../../application/use-cases/generar-cuotas.use-case';
import { EliminarCuotaUseCase } from '../../application/use-cases/eliminar-cuota.use-case';
import { CuotaRepository } from '../persistence/cuota.repository';
import { PagoRepository } from '../persistence/pago.repository';
import { CuentaCarteraRepository } from '../persistence/cuenta-cartera.repository';
import { GenerarCuotasDto, ListarCuotasQueryDto } from './dtos/cuotas.dto';
import { Periodo, type Frecuencia } from '../../../shared/common/value-objects';
import { mapCuotaConParciales } from '../../application/mappers/cuota.mapper';
import { JwtAuthGuard } from '../../../shared/auth/jwt-auth.guard';
import { RolesGuard } from '../../../shared/auth/guards/roles.guard';
import { Roles } from '../../../shared/auth/decorators/roles.decorator';
import { CurrentTenant } from '../../../shared/tenant/current-tenant.decorator';
import { RolUsuario } from '../../../iam/domain/usuario.entity';

@Controller('cuotas')
@UseGuards(JwtAuthGuard)
export class CuotasController {
  constructor(
    private readonly generarCuotasUseCase: GenerarCuotasUseCase,
    private readonly eliminarCuotaUseCase: EliminarCuotaUseCase,
    private readonly cuotaRepository: CuotaRepository,
    private readonly pagoRepository: PagoRepository,
    private readonly cuentaCarteraRepository: CuentaCarteraRepository,
  ) {}

  @Post('generar')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async generar(
    @Body() dto: GenerarCuotasDto,
    @CurrentTenant() tenantId: string,
  ) {
    return this.generarCuotasUseCase.execute(tenantId, dto.conjuntoId);
  }

  @Get()
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async listar(@CurrentTenant() tenantId: string) {
    return this.cuotaRepository.findByTenant(tenantId);
  }

  @Get('propietario/:propietarioId')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async listarPorPropietario(
    @Param('propietarioId') propietarioId: string,
    @Query() query: ListarCuotasQueryDto,
  ) {
    const [cuotas, cuenta] = await Promise.all([
      this.cuotaRepository.findByPropietario(
        propietarioId,
        query.estado || query.estadoFilter,
      ),
      this.cuentaCarteraRepository.findByPropietario(propietarioId),
    ]);

    const frecuencia: Frecuencia = cuenta?.frecuencia ?? 'MENSUAL';
    const hoy = new Date();

    const visibles = cuotas.filter((c) =>
      Periodo.esVisible(c.periodoInicio, frecuencia, hoy),
    );

    return Promise.all(
      visibles.map(async (cuota) => {
        const pagosRegistrados = await this.pagoRepository.countByCuota(cuota.id);
        const mapped = mapCuotaConParciales(cuota, frecuencia, pagosRegistrados);
        const [year, month] = cuota.periodoInicio.split('-').map(Number);
        return {
          ...mapped,
          fechasCobroParciales: Periodo.fechasCobroParciales(
            frecuencia,
            year,
            month - 1,
          ),
        };
      }),
    );
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async eliminar(
    @Param('id') id: string,
    @CurrentTenant() tenantId: string,
  ) {
    await this.eliminarCuotaUseCase.execute(id, tenantId);
    return { success: true };
  }
}
