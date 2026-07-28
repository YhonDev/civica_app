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
import { DataSource, In, Repository } from 'typeorm';
import { InjectRepository } from '@nestjs/typeorm';
import { RegistrarResidenteUseCase } from '../../application/use-cases/registrar-residente.use-case';
import { ResidenteRepository } from '../../infrastructure/residente.repository';
import { ResidenteDetailQuery } from '../../application/queries/residente-detail.query';
import { RegistrarResidenteDto } from './dtos/residentes.dto';
import { EliminarResidenteUseCase } from '../../application/use-cases/eliminar-residente.use-case';
import { ActualizarResidenteUseCase } from '../../application/use-cases/actualizar-residente.use-case';
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

@Controller('residentes')
@UseGuards(JwtAuthGuard)
export class ResidentesController {
  constructor(
    private readonly registrarResidenteUseCase: RegistrarResidenteUseCase,
    private readonly eliminarResidenteUseCase: EliminarResidenteUseCase,
    private readonly actualizarResidenteUseCase: ActualizarResidenteUseCase,
    private readonly residenteRepository: ResidenteRepository,
    private readonly residenteDetailQuery: ResidenteDetailQuery,
    private readonly dataSource: DataSource,
    @InjectRepository(Usuario)
    private readonly usuarioRepository: Repository<Usuario>,
  ) {}

  @Get(':id/detalle')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN, RolUsuario.COBRADOR, RolUsuario.RESIDENTE)
  async getDetalle(
    @Param('id') id: string,
    @CurrentTenant() tenantId: string,
    @CurrentUser() user: Usuario,
  ) {
    if (!user.tenantId) throw new UnauthorizedException();
    
    // El RESIDENTE solo puede ver su propio detalle
    if (user.rol === RolUsuario.RESIDENTE && user.residenteId !== id) {
      throw new UnauthorizedException('No tienes permiso para ver este residente');
    }

    return this.residenteDetailQuery.execute(id, tenantId);
  }

  @Post()
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  @UseInterceptors(ActividadInterceptor)
  @RegistrarActividad({
    tipo: 'RESIDENTE',
    descripcionFn: (result: any) => `Nuevo residente registrado: ${result.nombre}`,
  })
  async registrar(
    @Body() dto: RegistrarResidenteDto,
    @CurrentTenant() tenantId: string,
  ): Promise<any> {
    return this.registrarResidenteUseCase.execute({
      nombre: dto.nombre,
      telefono: dto.telefono,
      email: dto.email ?? null,
      tenantId,
      casaId: dto.casaId,
      fechaInicio: dto.fechaInicio ? new Date(dto.fechaInicio) : undefined,
      modalidadPago: dto.modalidadPago as any,
    });
  }

  @Patch(':id')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  @UseInterceptors(ActividadInterceptor)
  @RegistrarActividad({
    tipo: 'RESIDENTE',
    descripcionFn: (result) => `Residente actualizado`,
  })
  async actualizar(
    @Param('id') id: string,
    @Body() dto: Partial<RegistrarResidenteDto>,
    @CurrentUser() user: Usuario,
  ) {
    if (!user.tenantId) throw new UnauthorizedException();
    await this.actualizarResidenteUseCase.execute({
      id,
      tenantId: user.tenantId,
      nombre: dto.nombre,
      telefono: dto.telefono,
      email: dto.email,
      casaId: dto.casaId,
      modalidadPago: dto.modalidadPago as any,
    });
    return { success: true };
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  @UseInterceptors(ActividadInterceptor)
  @RegistrarActividad({
    tipo: 'RESIDENTE',
    descripcionFn: (result) => `Residente eliminado`,
  })
  async eliminar(
    @Param('id') id: string,
    @CurrentUser() user: Usuario,
  ) {
    if (!user.tenantId) throw new UnauthorizedException();
    await this.eliminarResidenteUseCase.execute(id, user.tenantId);
    return { success: true };
  }

  @Get()
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN, RolUsuario.COBRADOR, RolUsuario.RESIDENTE)
  async listar(
    @CurrentTenant() tenantId: string,
    @Query('etapa') etapaId?: string,
    @Query('casa') casaId?: string,
    @CurrentUser() user?: Usuario,
  ) {
    if (!user || !tenantId) {
      throw new UnauthorizedException('Usuario no autenticado o sin tenant');
    }

    // ADMIN: retorna todos los residentes
    if (user.rol === RolUsuario.ADMIN) {
      const residentes = await this.residenteRepository.buscarPorFiltros({
        tenantId,
        etapaId,
        casaId,
      });
      return this.adjuntarUsernames(residentes);
    }

    // COBRADOR: solo residentes cuyas casas están en etapas asignadas
    if (user.rol === RolUsuario.COBRADOR) {
      const residentes = await this.listarParaCobrador(user.id, tenantId, etapaId, casaId);
      return this.adjuntarUsernames(residentes);
    }

    // RESIDENTE: solo sus propios datos
    if (user.rol === RolUsuario.RESIDENTE) {
      if (!user.residenteId) {
        return [];
      }
      const residente = await this.residenteRepository.findById(
        user.residenteId,
      );
      if (!residente) return [];
      return this.adjuntarUsernames([residente]);
    }

    return [];
  }

  private async adjuntarUsernames(residentes: any[]) {
    if (residentes.length === 0) return residentes;

    const ids = residentes.map(r => r.id);
    const usuarios = await this.usuarioRepository.find({
      where: { residenteId: In(ids) },
      select: { id: true, residenteId: true, email: true },
    });

    const usuarioMap = new Map(usuarios.map(u => [u.residenteId, { id: u.id, email: u.email }]));

    return residentes.map(r => {
      const usuario = usuarioMap.get(r.id);
      return {
        ...r,
        username: usuario?.email ?? null,
        usuarioId: usuario?.id ?? null,
      };
    });
  }

  private async listarParaCobrador(
    usuarioId: string,
    tenantId: string,
    etapaId?: string,
    casaId?: string,
  ) {
    // Si ya se especificó una etapa en el query, usamos ese filtro directamente
    if (etapaId) {
      return this.residenteRepository.buscarPorFiltros({
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
      await this.residenteRepository.buscarPorEtapas(tenantId, etapaIds);

    // Si hay filtro adicional de casa, aplicarlo en memoria
    if (casaId) {
      return resultados.filter((p) =>
        p.tenencias?.some((t) => t.casaId === casaId),
      );
    }

    return resultados;
  }
}
