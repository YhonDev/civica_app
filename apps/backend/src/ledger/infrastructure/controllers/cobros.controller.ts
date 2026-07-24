import {
  Controller,
  Get,
  Post,
  Param,
  Query,
  Body,
  Delete,
  UseGuards,
  UnauthorizedException,
} from '@nestjs/common';
import { DataSource } from 'typeorm';
import { JwtAuthGuard } from '../../../shared/auth/jwt-auth.guard';
import { RolesGuard } from '../../../shared/auth/guards/roles.guard';
import { Roles } from '../../../shared/auth/decorators/roles.decorator';
import { CurrentTenant } from '../../../shared/tenant/current-tenant.decorator';
import { CurrentUser } from '../../../shared/tenant/current-user.decorator';
import { Usuario, RolUsuario } from '../../../iam/domain/usuario.entity';
import { CobroRepository } from '../../infrastructure/persistence/cobro.repository';
import { EliminarCobroUseCase } from '../../application/use-cases/eliminar-cobro.use-case';
import { CarteraViviendaResumenQuery } from '../../application/queries/cartera-vivienda-resumen.query';

@Controller('cobros')
@UseGuards(JwtAuthGuard)
export class CobrosController {
  constructor(
    private readonly cobroRepository: CobroRepository,
    private readonly eliminarCobroUseCase: EliminarCobroUseCase,
    private readonly carteraViviendaResumenQuery: CarteraViviendaResumenQuery,
    private readonly dataSource: DataSource,
  ) {}

  @Get()
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN, RolUsuario.COBRADOR)
  async listar(
    @CurrentTenant() tenantId: string,
    @CurrentUser() user: Usuario,
    @Query('etapaId') etapaId?: string,
    @Query('manzanaId') manzanaId?: string,
    @Query('status') status?: string,
  ) {
    if (!tenantId) return [];

    let allowedEtapaIds: string[] | undefined;

    if (user.rol === RolUsuario.COBRADOR) {
      const asignaciones = await this.dataSource.query(
        'SELECT etapa_id FROM asignaciones_etapa WHERE usuario_id = $1',
        [user.id],
      );
      const stageIds: string[] = asignaciones.map((a: any) => a.etapa_id);
      if (stageIds.length === 0) {
        return [];
      }
      allowedEtapaIds = stageIds;
    }

    return this.cobroRepository.findAllWithFilters(
      tenantId,
      { etapaId, manzanaId, status },
      allowedEtapaIds,
    );
  }

  @Get('residente/:residenteId')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN, RolUsuario.COBRADOR, RolUsuario.RESIDENTE)
  async listarPorResidente(
    @Param('residenteId') residenteId: string,
    @CurrentTenant() tenantId: string,
    @CurrentUser() user: Usuario,
  ) {
    if (!tenantId) return [];

    if (user.rol === RolUsuario.RESIDENTE && user.residenteId !== residenteId) {
      throw new UnauthorizedException('No tienes permiso para ver estos cobros');
    }

    return this.cobroRepository.findByResidente(residenteId);
  }

  @Get('casas/cartera-resumen')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN, RolUsuario.COBRADOR)
  async getCarteraViviendas(
    @CurrentTenant() tenantId: string,
    @Query('etapaId') etapaId?: string,
    @Query('manzanaId') manzanaId?: string,
  ) {
    if (!tenantId) return [];
    return this.carteraViviendaResumenQuery.execute(tenantId, etapaId, manzanaId);
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async eliminar(@Param('id') id: string) {
    await this.eliminarCobroUseCase.execute(id);
    return { success: true };
  }
}
