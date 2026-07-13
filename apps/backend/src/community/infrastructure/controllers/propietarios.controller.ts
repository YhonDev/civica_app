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
  UnauthorizedException,
} from '@nestjs/common';
import { DataSource } from 'typeorm';
import { RegistrarPropietarioUseCase } from '../../application/use-cases/registrar-propietario.use-case';
import { PropietarioRepository } from '../../infrastructure/propietario.repository';
import { RegistrarPropietarioDto } from './dtos/propietarios.dto';
import { EliminarPropietarioUseCase } from '../../application/use-cases/eliminar-propietario.use-case';
import { ActualizarPropietarioUseCase } from '../../application/use-cases/actualizar-propietario.use-case';
import { JwtAuthGuard } from '../../../shared/auth/jwt-auth.guard';
import { RolesGuard } from '../../../shared/auth/guards/roles.guard';
import { Roles } from '../../../shared/auth/decorators/roles.decorator';
import { CurrentUser } from '../../../shared/tenant/current-user.decorator';
import { CurrentTenant } from '../../../shared/tenant/current-tenant.decorator';
import { Usuario, RolUsuario } from '../../../iam/domain/usuario.entity';
import {
  RegistrarActividad,
  ActividadInterceptor,
} from '../../../shared/common/decorators/registrar-actividad.decorator';

@Controller('propietarios')
@UseGuards(JwtAuthGuard)
export class PropietariosController {
  constructor(
    private readonly registrarPropietarioUseCase: RegistrarPropietarioUseCase,
    private readonly eliminarPropietarioUseCase: EliminarPropietarioUseCase,
    private readonly actualizarPropietarioUseCase: ActualizarPropietarioUseCase,
    private readonly propietarioRepository: PropietarioRepository,
    private readonly dataSource: DataSource,
  ) {}

  @Post()
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  @UseInterceptors(ActividadInterceptor)
  @RegistrarActividad({
    tipo: 'PROPIETARIO',
    descripcionFn: (result) => `Nuevo propietario registrado: ${result.nombre}`,
  })
  async registrar(@Body() dto: RegistrarPropietarioDto) {
    return this.registrarPropietarioUseCase.execute({
      nombre: dto.nombre,
      telefono: dto.telefono,
      email: dto.email ?? null,
      tenantId: dto.tenantId,
      casaId: dto.casaId,
      fechaInicio: dto.fechaInicio ? new Date(dto.fechaInicio) : undefined,
      modalidadPago: dto.modalidadPago,
    });
  }

  @Patch(':id')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  @UseInterceptors(ActividadInterceptor)
  @RegistrarActividad({
    tipo: 'PROPIETARIO',
    descripcionFn: (result) => `Propietario actualizado`,
  })
  async actualizar(
    @Param('id') id: string,
    @Body() dto: Partial<RegistrarPropietarioDto>,
    @CurrentUser() user: Usuario,
  ) {
    if (!user.tenantId) throw new UnauthorizedException();
    await this.actualizarPropietarioUseCase.execute({
      id,
      tenantId: user.tenantId,
      nombre: dto.nombre,
      telefono: dto.telefono,
      email: dto.email,
      casaId: dto.casaId,
      modalidadPago: dto.modalidadPago,
    });
    return { success: true };
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  @UseInterceptors(ActividadInterceptor)
  @RegistrarActividad({
    tipo: 'PROPIETARIO',
    descripcionFn: (result) => `Propietario eliminado`,
  })
  async eliminar(
    @Param('id') id: string,
    @CurrentUser() user: Usuario,
  ) {
    if (!user.tenantId) throw new UnauthorizedException();
    await this.eliminarPropietarioUseCase.execute(id, user.tenantId);
    return { success: true };
  }

  @Get()
  async listar(
    @CurrentTenant() tenantId: string,
    @Query('etapa') etapaId?: string,
    @Query('casa') casaId?: string,
    @CurrentUser() user?: Usuario,
  ) {
    if (!user || !tenantId) {
      throw new UnauthorizedException('Usuario no autenticado o sin tenant');
    }

    // ADMIN: retorna todos los propietarios (comportamiento existente)
    if (user.rol === RolUsuario.ADMIN) {
      return this.propietarioRepository.buscarPorFiltros({
        tenantId,
        etapaId,
        casaId,
      });
    }

    // COBRADOR: solo propietarios cuyas casas están en etapas asignadas
    if (user.rol === RolUsuario.COBRADOR) {
      return this.listarParaCobrador(user.id, tenantId, etapaId, casaId);
    }

    // PROPIETARIO: solo sus propios datos
    if (user.rol === RolUsuario.PROPIETARIO) {
      if (!user.propietarioId) {
        return [];
      }
      const propietario = await this.propietarioRepository.findById(
        user.propietarioId,
      );
      return propietario ? [propietario] : [];
    }

    return [];
  }

  private async listarParaCobrador(
    usuarioId: string,
    tenantId: string,
    etapaId?: string,
    casaId?: string,
  ) {
    // Si ya se especificó una etapa en el query, usamos ese filtro directamente
    if (etapaId) {
      return this.propietarioRepository.buscarPorFiltros({
        tenantId,
        etapaId,
        casaId,
      });
    }

    // Buscamos las etapas asignadas al cobrador
    const asignaciones = await this.dataSource.query(
      'SELECT etapa_id FROM asignaciones_etapa WHERE usuario_id = $1',
      [usuarioId],
    );

    const etapaIds = asignaciones.map((a: any) => a.etapa_id);
    if (etapaIds.length === 0) {
      return [];
    }

    const resultados =
      await this.propietarioRepository.buscarPorEtapas(tenantId, etapaIds);

    // Si hay filtro adicional de casa, aplicarlo en memoria
    if (casaId) {
      return resultados.filter((p) =>
        p.tenencias?.some((t) => t.casaId === casaId),
      );
    }

    return resultados;
  }
}
