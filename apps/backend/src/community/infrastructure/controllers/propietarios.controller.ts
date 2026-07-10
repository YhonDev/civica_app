import {
  Controller,
  Get,
  Post,
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
import { JwtAuthGuard } from '../../../shared/auth/jwt-auth.guard';
import { RolesGuard } from '../../../shared/auth/guards/roles.guard';
import { Roles } from '../../../shared/auth/decorators/roles.decorator';
import { CurrentUser } from '../../../shared/tenant/current-user.decorator';
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
    });
  }

  @Get()
  async listar(
    @Query('tenantId') tenantId: string,
    @Query('etapa') etapaId?: string,
    @Query('casa') casaId?: string,
    @CurrentUser() user?: Usuario,
  ) {
    if (!user) {
      throw new UnauthorizedException('Usuario no autenticado');
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
