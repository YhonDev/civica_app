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
} from '@nestjs/common';
import { ConfigurarTarifaUseCase } from '../../application/use-cases/configurar-tarifa.use-case';
import { ActualizarTarifaUseCase } from '../../application/use-cases/actualizar-tarifa.use-case';
import { TarifaRepository } from '../persistence/tarifa.repository';
import {
  CrearTarifaDto,
  ActualizarTarifaDto,
  ListarTarifasQueryDto,
} from './dtos/tarifas.dto';
import { JwtAuthGuard } from '../../../shared/auth/jwt-auth.guard';
import { RolesGuard } from '../../../shared/auth/guards/roles.guard';
import { Roles } from '../../../shared/auth/decorators/roles.decorator';
import { CurrentTenant } from '../../../shared/tenant/current-tenant.decorator';
import { RolUsuario } from '../../../iam/domain/usuario.entity';

@Controller('tarifas')
@UseGuards(JwtAuthGuard)
export class TarifasController {
  constructor(
    private readonly configurarTarifaUseCase: ConfigurarTarifaUseCase,
    private readonly actualizarTarifaUseCase: ActualizarTarifaUseCase,
    private readonly tarifaRepository: TarifaRepository,
  ) {}

  @Post()
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async crear(
    @Body() dto: CrearTarifaDto,
    @CurrentTenant() tenantId: string,
  ) {
    return this.configurarTarifaUseCase.execute({
      conjuntoId: dto.conjuntoId,
      tenantId,
      frecuencia: dto.frecuencia,
      montoPesos: dto.monto,
      fechaVigencia: dto.fechaVigencia,
    });
  }

  @Get()
  async listar(
    @Query() query: ListarTarifasQueryDto,
    @CurrentTenant() tenantId: string,
  ) {
    return this.tarifaRepository.findAll(tenantId, query.conjuntoId);
  }

  @Get(':id')
  async obtener(@Param('id') id: string) {
    const tarifa = await this.tarifaRepository.findById(id);
    if (!tarifa) {
      return { error: 'Tarifa no encontrada' };
    }
    return tarifa;
  }

  @Patch(':id')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async actualizar(
    @Param('id') id: string,
    @Body() dto: ActualizarTarifaDto,
  ) {
    return this.actualizarTarifaUseCase.execute({
      tarifaId: id,
      montoPesos: dto.monto,
      fechaVigencia: dto.fechaVigencia,
    });
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async desactivar(@Param('id') id: string) {
    const tarifa = await this.tarifaRepository.findById(id);
    if (!tarifa) {
      return { error: 'Tarifa no encontrada' };
    }
    tarifa.desactivar();
    await this.tarifaRepository.save(tarifa);
    return { message: 'Tarifa desactivada correctamente' };
  }
}
