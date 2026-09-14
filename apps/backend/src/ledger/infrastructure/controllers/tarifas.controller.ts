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
  NotFoundException,
  Optional,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { ConfigurarTarifaUseCase } from '../../application/use-cases/configurar-tarifa.use-case';
import { ActualizarTarifaUseCase } from '../../application/use-cases/actualizar-tarifa.use-case';
import { TarifaRepository } from '../persistence/tarifa.repository';
import { CacheService } from '../../../shared/cache/cache.service';
import {
  CrearTarifaDto,
  ActualizarTarifaDto,
  ListarTarifasQueryDto,
  TarifasVigentesQueryDto,
} from './dtos/tarifas.dto';
import { JwtAuthGuard } from '../../../shared/auth/jwt-auth.guard';
import { RolesGuard } from '../../../shared/auth/guards/roles.guard';
import { Roles } from '../../../shared/auth/decorators/roles.decorator';
import { CurrentTenant } from '../../../shared/tenant/current-tenant.decorator';
import { RolUsuario } from '../../../iam/domain/usuario.entity';

@ApiTags('Tarifas')
@ApiBearerAuth('jwt-auth')
@Controller('tarifas')
@UseGuards(JwtAuthGuard)
export class TarifasController {
  constructor(
    private readonly configurarTarifaUseCase: ConfigurarTarifaUseCase,
    private readonly actualizarTarifaUseCase: ActualizarTarifaUseCase,
    private readonly tarifaRepository: TarifaRepository,
    @Optional()
    private readonly cacheService?: CacheService,
  ) {}

  @Post()
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  @ApiOperation({ summary: 'Crear nueva tarifa' })
  async crear(@Body() dto: CrearTarifaDto, @CurrentTenant() tenantId: string) {
    const result = await this.configurarTarifaUseCase.execute({
      proyectoId: dto.proyectoId,
      tenantId,
      modalidad: dto.modalidad,
      montoPesos: dto.monto,
      fechaVigencia: dto.fechaVigencia,
    });
    if (this.cacheService) {
      await this.cacheService.delByPrefix(`tarifas:${tenantId}`);
    }
    return result;
  }

  @Get()
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN, RolUsuario.COBRADOR, RolUsuario.RESIDENTE)
  @ApiOperation({ summary: 'Listar todas las tarifas' })
  async listar(
    @Query() query: ListarTarifasQueryDto,
    @CurrentTenant() tenantId: string,
  ) {
    return this.tarifaRepository.findAll(tenantId, query.proyectoId);
  }

  /** Tarifas vigentes hoy — siempre desde BD (editables por admin). */
  @Get('vigentes')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN, RolUsuario.COBRADOR, RolUsuario.RESIDENTE)
  @ApiOperation({ summary: 'Obtener tarifas vigentes por modalidad' })
  async vigentes(
    @Query() query: TarifasVigentesQueryDto,
    @CurrentTenant() tenantId: string,
  ) {
    const cacheKey = `tarifas:vigentes:${tenantId}:${query.proyectoId ?? 'all'}`;
    const compute = async () => {
      const vigentes = await this.tarifaRepository.findVigentesPorConjunto(
        query.proyectoId,
        tenantId,
      );

      const toDto = (tarifa: typeof vigentes.MENSUAL) =>
        tarifa
          ? {
              id: tarifa.id,
              modalidad: tarifa.modalidad,
              monto: tarifa.monto,
              montoPesos: Math.round(tarifa.monto / 100),
              fechaVigencia: tarifa.fechaVigencia,
            }
          : null;

      return {
        proyectoId: query.proyectoId,
        tenantId,
        tarifas: {
          MENSUAL: toDto(vigentes.MENSUAL),
          QUINCENAL: toDto(vigentes.QUINCENAL),
          SEMANAL: toDto(vigentes.SEMANAL),
        },
        cuotaMensualPesos: vigentes.MENSUAL
          ? Math.round(vigentes.MENSUAL.monto / 100)
          : null,
      };
    };

    if (this.cacheService) {
      return this.cacheService.wrap(cacheKey, 120, compute);
    }
    return compute();
  }

  @Get(':id')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN, RolUsuario.COBRADOR, RolUsuario.RESIDENTE)
  async obtener(@Param('id') id: string, @CurrentTenant() tenantId: string) {
    const tarifa = await this.tarifaRepository.findById(id, tenantId);
    if (!tarifa) {
      throw new NotFoundException('Tarifa no encontrada');
    }
    return tarifa;
  }

  @Patch(':id')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async actualizar(
    @Param('id') id: string,
    @Body() dto: ActualizarTarifaDto,
    @CurrentTenant() tenantId: string,
  ) {
    const result = await this.actualizarTarifaUseCase.execute({
      tarifaId: id,
      montoPesos: dto.monto,
      fechaVigencia: dto.fechaVigencia,
      tenantId,
    });
    if (this.cacheService) {
      await this.cacheService.delByPrefix(`tarifas:${tenantId}`);
    }
    return result;
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async desactivar(@Param('id') id: string, @CurrentTenant() tenantId: string) {
    const tarifa = await this.tarifaRepository.findById(id, tenantId);
    if (!tarifa) {
      throw new NotFoundException('Tarifa no encontrada');
    }
    tarifa.desactivar();
    await this.tarifaRepository.save(tarifa);
    if (this.cacheService) {
      await this.cacheService.delByPrefix(`tarifas:${tenantId}`);
    }
    return { message: 'Tarifa desactivada correctamente' };
  }
}
