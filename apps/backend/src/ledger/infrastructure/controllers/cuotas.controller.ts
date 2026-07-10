import {
  Controller,
  Get,
  Post,
  Param,
  Query,
  Body,
  UseGuards,
} from '@nestjs/common';
import { GenerarCuotasUseCase } from '../../application/use-cases/generar-cuotas.use-case';
import { CuotaRepository } from '../persistence/cuota.repository';
import { GenerarCuotasDto, ListarCuotasQueryDto } from './dtos/cuotas.dto';
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
    private readonly cuotaRepository: CuotaRepository,
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

  @Get('propietario/:propietarioId')
  async listarPorPropietario(
    @Param('propietarioId') propietarioId: string,
    @Query() query: ListarCuotasQueryDto,
  ) {
    return this.cuotaRepository.findByPropietario(
      propietarioId,
      query.estado || query.estadoFilter,
    );
  }
}
