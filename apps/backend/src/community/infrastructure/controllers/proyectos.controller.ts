import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Query,
  Body,
  Delete,
  UseGuards,
  NotFoundException,
  BadRequestException,
  ParseUUIDPipe,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
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
  ActualizarAjustesProyectoDto,
} from './dtos/proyectos.dto';

@ApiTags('Proyectos')
@ApiBearerAuth('jwt-auth')
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
  async crear(
    @Body() dto: CrearProyectoDto,
    @CurrentTenant() tenantId: string,
  ) {
    return this.crearProyectoUseCase.execute(dto.nombre, tenantId);
  }

  @Get('etapas')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN, RolUsuario.COBRADOR)
  async listarEtapas(@CurrentTenant() tenantId: string) {
    return this.dataSource.query(
      `SELECT e.id, e.nombre, e.proyecto_id AS "proyectoId" 
       FROM etapas e 
       JOIN proyectos p ON e.proyecto_id = p.id 
       WHERE p.tenant_id = $1 
       ORDER BY e.created_at ASC`,
      [tenantId],
    );
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
  async eliminarEtapa(@Param('id', ParseUUIDPipe) id: string) {
    const tenenciasCount = await this.dataSource.query(
      'SELECT COUNT(*) as count FROM tenencias t JOIN casas c ON t.casa_id = c.id JOIN manzanas m ON c.manzana_id = m.id WHERE m.etapa_id = $1',
      [id],
    );
    const cobrosCount = await this.dataSource.query(
      'SELECT COUNT(*) as count FROM cobros co JOIN casas c ON co.casa_id = c.id JOIN manzanas m ON c.manzana_id = m.id WHERE m.etapa_id = $1',
      [id],
    );
    if (
      Number(tenenciasCount[0]?.count ?? 0) > 0 ||
      Number(cobrosCount[0]?.count ?? 0) > 0
    ) {
      throw new BadRequestException(
        'No se puede eliminar una etapa con tenencias o cobros activos',
      );
    }

    await this.dataSource.query('DELETE FROM etapas WHERE id = $1', [id]);
    return { success: true };
  }

  @Delete('manzanas/:id')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async eliminarManzana(@Param('id', ParseUUIDPipe) id: string) {
    const tenenciasCount = await this.dataSource.query(
      'SELECT COUNT(*) as count FROM tenencias t JOIN casas c ON t.casa_id = c.id WHERE c.manzana_id = $1',
      [id],
    );
    const cobrosCount = await this.dataSource.query(
      'SELECT COUNT(*) as count FROM cobros co JOIN casas c ON co.casa_id = c.id WHERE c.manzana_id = $1',
      [id],
    );
    if (
      Number(tenenciasCount[0]?.count ?? 0) > 0 ||
      Number(cobrosCount[0]?.count ?? 0) > 0
    ) {
      throw new BadRequestException(
        'No se puede eliminar una manzana con tenencias o cobros activos',
      );
    }

    await this.dataSource.query('DELETE FROM manzanas WHERE id = $1', [id]);
    return { success: true };
  }

  @Delete('casas/:id')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async eliminarCasa(@Param('id', ParseUUIDPipe) id: string) {
    const tenenciasCount = await this.dataSource.query(
      'SELECT COUNT(*) as count FROM tenencias WHERE casa_id = $1',
      [id],
    );
    const cobrosCount = await this.dataSource.query(
      'SELECT COUNT(*) as count FROM cobros WHERE casa_id = $1',
      [id],
    );
    if (
      Number(tenenciasCount[0]?.count ?? 0) > 0 ||
      Number(cobrosCount[0]?.count ?? 0) > 0
    ) {
      throw new BadRequestException(
        'No se puede eliminar una casa con tenencias o cobros activos',
      );
    }

    await this.dataSource.query('DELETE FROM casas WHERE id = $1', [id]);
    return { success: true };
  }

  @Get('actual')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN, RolUsuario.COBRADOR, RolUsuario.RESIDENTE)
  async getProyectoActual(@CurrentTenant() tenantId: string) {
    if (!tenantId) return { nombre: '' };
    const proyectos = await this.proyectoRepository.findByTenant(tenantId);
    if (!proyectos || proyectos.length === 0) return { nombre: '' };
    const p = proyectos[0];
    return { id: p.id, nombre: p.nombre, tenantId: p.tenantId };
  }

  @Get()
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async listar(@CurrentTenant() tenantId: string) {
    if (!tenantId) return [];
    return this.proyectoRepository.findByTenant(tenantId);
  }

  @Get(':id/ajustes')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async getAjustes(@Param('id') id: string) {
    const proyecto = await this.proyectoRepository.findByIdPlano(id);
    if (!proyecto) {
      throw new NotFoundException(`Proyecto ${id} no encontrado`);
    }
    return {
      id: proyecto.id,
      nombre: proyecto.nombre,
      recordatoriosAutomaticos: proyecto.recordatoriosAutomaticos,
      permitePagosParciales: proyecto.permitePagosParciales,
      modoMantenimiento: proyecto.modoMantenimiento,
      fechaMantenimiento: proyecto.fechaMantenimiento,
    };
  }

  @Patch(':id/ajustes')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async actualizarAjustes(
    @Param('id') id: string,
    @Body() dto: ActualizarAjustesProyectoDto,
  ) {
    const proyecto = await this.proyectoRepository.findByIdPlano(id);
    if (!proyecto) {
      throw new NotFoundException(`Proyecto ${id} no encontrado`);
    }

    if (dto.recordatoriosAutomaticos !== undefined) {
      proyecto.recordatoriosAutomaticos = dto.recordatoriosAutomaticos;
    }
    if (dto.permitePagosParciales !== undefined) {
      proyecto.permitePagosParciales = dto.permitePagosParciales;
    }
    if (dto.modoMantenimiento !== undefined) {
      if (dto.modoMantenimiento) {
        proyecto.activarMantenimiento();
      } else {
        proyecto.desactivarMantenimiento();
      }
    }

    const guardado = await this.proyectoRepository.save(proyecto);
    return {
      id: guardado.id,
      recordatoriosAutomaticos: guardado.recordatoriosAutomaticos,
      permitePagosParciales: guardado.permitePagosParciales,
      modoMantenimiento: guardado.modoMantenimiento,
      fechaMantenimiento: guardado.fechaMantenimiento,
    };
  }
}
