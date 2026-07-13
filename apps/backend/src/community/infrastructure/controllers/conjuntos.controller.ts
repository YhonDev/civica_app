import {
  Controller,
  Get,
  Post,
  Param,
  Query,
  Body,
  Delete,
} from '@nestjs/common';
import { DataSource } from 'typeorm';
import { CurrentTenant } from '../../../shared/tenant/current-tenant.decorator';
import { JwtAuthGuard } from '../../../shared/auth/jwt-auth.guard';
import { UseGuards } from '@nestjs/common';
import { CrearConjuntoUseCase } from '../../application/use-cases/crear-conjunto.use-case';
import { CrearEtapaUseCase } from '../../application/use-cases/crear-etapa.use-case';
import { CrearManzanaUseCase } from '../../application/use-cases/crear-manzana.use-case';
import { RegistrarCasaUseCase } from '../../application/use-cases/registrar-casa.use-case';
import { ConjuntoRepository } from '../../infrastructure/conjunto.repository';
import {
  CrearConjuntoDto,
  CrearEtapaDto,
  CrearManzanaDto,
  RegistrarCasaDto,
} from './dtos/conjuntos.dto';

@Controller('conjuntos')
@UseGuards(JwtAuthGuard)
export class ConjuntosController {
  constructor(
    private readonly crearConjuntoUseCase: CrearConjuntoUseCase,
    private readonly crearEtapaUseCase: CrearEtapaUseCase,
    private readonly crearManzanaUseCase: CrearManzanaUseCase,
    private readonly registrarCasaUseCase: RegistrarCasaUseCase,
    private readonly conjuntoRepository: ConjuntoRepository,
    private readonly dataSource: DataSource,
  ) {}

  @Post()
  async crear(@Body() dto: CrearConjuntoDto) {
    return this.crearConjuntoUseCase.execute(dto.nombre, dto.tenantId);
  }

  @Post(':id/etapas')
  async crearEtapa(
    @Param('id') conjuntoId: string,
    @Body() dto: CrearEtapaDto,
  ) {
    return this.crearEtapaUseCase.execute(dto.nombre, conjuntoId);
  }

  @Post('etapas/:id/manzanas')
  async crearManzana(
    @Param('id') etapaId: string,
    @Body() dto: CrearManzanaDto,
  ) {
    return this.crearManzanaUseCase.execute(dto.nombre, etapaId);
  }

  @Post('manzanas/:id/casas')
  async crearCasa(
    @Param('id') manzanaId: string,
    @Body() dto: RegistrarCasaDto,
  ) {
    return this.registrarCasaUseCase.execute(dto.direccionInterna, manzanaId);
  }

  @Delete('etapas/:id')
  async eliminarEtapa(@Param('id') id: string) {
    await this.dataSource.query('DELETE FROM etapas WHERE id = $1', [id]);
    return { success: true };
  }

  @Delete('manzanas/:id')
  async eliminarManzana(@Param('id') id: string) {
    await this.dataSource.query('DELETE FROM manzanas WHERE id = $1', [id]);
    return { success: true };
  }

  @Delete('casas/:id')
  async eliminarCasa(@Param('id') id: string) {
    await this.dataSource.query('DELETE FROM casas WHERE id = $1', [id]);
    return { success: true };
  }

  @Get()
  async listar(@CurrentTenant() tenantId: string) {
    if (!tenantId) return [];
    return this.conjuntoRepository.findByTenant(tenantId);
  }
}
