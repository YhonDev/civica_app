import {
  Controller,
  Get,
  Post,
  Param,
  Query,
  Body,
  Delete,
  UseGuards,
} from '@nestjs/common';
import { DataSource } from 'typeorm';
import { CurrentTenant } from '../../../shared/tenant/current-tenant.decorator';
import { JwtAuthGuard } from '../../../shared/auth/jwt-auth.guard';
import { RolesGuard } from '../../../shared/auth/guards/roles.guard';
import { Roles } from '../../../shared/auth/decorators/roles.decorator';
import { RolUsuario } from '../../../iam/domain/usuario.entity';
import { CrearProyectoUseCase } from '../../application/use-cases/crear-proyecto.use-case';
import { CrearEtapaUseCase } from '../../application/use-cases/crear-etapa.use-case';
import { CrearManzanaUseCase } from '../../application/use-cases/crear-manzana.use-case';
import { RegistrarCasaUseCase } from '../../application/use-cases/registrar-casa.use-case';
import { ProyectoRepository } from '../../infrastructure/proyecto.repository';
import {
  CrearProyectoDto,
  CrearEtapaDto,
  CrearManzanaDto,
  RegistrarCasaDto,
} from './dtos/proyectos.dto';

@Controller('proyectos')
@UseGuards(JwtAuthGuard)
export class ProyectosController {
  constructor(
    private readonly crearProyectoUseCase: CrearProyectoUseCase,
    private readonly crearEtapaUseCase: CrearEtapaUseCase,
    private readonly crearManzanaUseCase: CrearManzanaUseCase,
    private readonly registrarCasaUseCase: RegistrarCasaUseCase,
    private readonly proyectoRepository: ProyectoRepository,
    private readonly dataSource: DataSource,
  ) {}

  @Post()
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async crear(@Body() dto: CrearProyectoDto) {
    return this.crearProyectoUseCase.execute(dto.nombre, dto.tenantId);
  }

  @Post(':id/etapas')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async crearEtapa(
    @Param('id') proyectoId: string,
    @Body() dto: CrearEtapaDto,
  ) {
    return this.crearEtapaUseCase.execute(dto.nombre, proyectoId);
  }

  @Post('etapas/:id/manzanas')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async crearManzana(
    @Param('id') etapaId: string,
    @Body() dto: CrearManzanaDto,
  ) {
    return this.crearManzanaUseCase.execute(dto.nombre, etapaId);
  }

  @Post('manzanas/:id/casas')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async crearCasa(
    @Param('id') manzanaId: string,
    @Body() dto: RegistrarCasaDto,
  ) {
    return this.registrarCasaUseCase.execute(dto.direccionInterna, manzanaId);
  }

  @Delete('etapas/:id')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async eliminarEtapa(@Param('id') id: string) {
    await this.dataSource.query('DELETE FROM etapas WHERE id = $1', [id]);
    return { success: true };
  }

  @Delete('manzanas/:id')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async eliminarManzana(@Param('id') id: string) {
    await this.dataSource.query('DELETE FROM manzanas WHERE id = $1', [id]);
    return { success: true };
  }

  @Delete('casas/:id')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async eliminarCasa(@Param('id') id: string) {
    await this.dataSource.query('DELETE FROM casas WHERE id = $1', [id]);
    return { success: true };
  }

  @Get()
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async listar(@CurrentTenant() tenantId: string) {
    if (!tenantId) return [];
    return this.proyectoRepository.findByTenant(tenantId);
  }
}
