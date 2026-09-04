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
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
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

@ApiTags('Cobros')
@ApiBearerAuth('jwt-auth')
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
  @ApiOperation({ summary: 'Listar cobros (cuotas) con filtros' })
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

    const cobros = await this.cobroRepository.findAllWithFilters(
      tenantId,
      { etapaId, manzanaId, status },
      allowedEtapaIds,
    );
    const ticketsMap = await this.loadTicketsForCobros(cobros.map((c) => c.id));
    return cobros.map((cobro) =>
      this.mapCobroItem(cobro, ticketsMap.get(cobro.id)),
    );
  }

  @Get('residente/:residenteId')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN, RolUsuario.COBRADOR, RolUsuario.RESIDENTE)
  @ApiOperation({ summary: 'Listar cobros de un residente específico' })
  async listarPorResidente(
    @Param('residenteId') residenteId: string,
    @CurrentTenant() tenantId: string,
    @CurrentUser() user: Usuario,
  ) {
    if (!tenantId) return [];

    if (user.rol === RolUsuario.RESIDENTE && user.residenteId !== residenteId) {
      throw new UnauthorizedException(
        'No tienes permiso para ver estos cobros',
      );
    }

    // Mismo scope que `listar`: etapas asignadas al cobrador + tenant.
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

    const cobros = await this.cobroRepository.findByResidente(
      residenteId,
      tenantId,
    );

    const escoped = allowedEtapaIds
      ? cobros.filter((cobro) => {
          const etapa =
            cobro.casa?.manzana?.etapa ||
            cobro.residente?.casaActual?.manzana?.etapa;
          return etapa ? allowedEtapaIds.includes(etapa.id) : false;
        })
      : cobros;

    const ticketsMap = await this.loadTicketsForCobros(
      escoped.map((c) => c.id),
    );
    return escoped.map((cobro) =>
      this.mapCobroItem(cobro, ticketsMap.get(cobro.id)),
    );
  }

  private async loadTicketsForCobros(
    cobroIds: string[],
  ): Promise<Map<string, any>> {
    const ticketsMap = new Map<string, any>();
    if (!cobroIds || cobroIds.length === 0) return ticketsMap;

    try {
      const tickets = await this.dataSource.query(
        `SELECT id, numero, fecha, cobro_id, cobrador_nombre, metodo 
         FROM tickets 
         WHERE cobro_id = ANY($1) AND estado != 'ANULADO'
         ORDER BY fecha DESC`,
        [cobroIds],
      );
      for (const t of tickets) {
        if (t.cobro_id && !ticketsMap.has(t.cobro_id)) {
          ticketsMap.set(t.cobro_id, t);
        }
      }
    } catch {
      // Fallback gracioso si tabla tickets no responde
    }
    return ticketsMap;
  }

  private mapCobroItem(cobro: any, ticket?: any) {
    const residente = cobro.residente;
    const casa = cobro.casa ?? residente?.casaActual;
    const manzana = casa?.manzana;
    const etapa = manzana?.etapa;

    const fechaPagoIso = ticket?.fecha
      ? ticket.fecha instanceof Date
        ? ticket.fecha.toISOString()
        : new Date(ticket.fecha).toISOString()
      : cobro.fechaPago
        ? new Date(cobro.fechaPago).toISOString()
        : null;

    return {
      ...cobro,
      residenteNombre: residente?.nombre ?? 'Residente',
      cobradorNombre:
        ticket?.cobrador_nombre ?? cobro.cobradorNombre ?? 'Administración',
      nroRecibo:
        ticket?.numero ??
        cobro.nroRecibo ??
        `TK-${cobro.id.replace(/-/g, '').substring(0, 6).toUpperCase()}`,
      fechaPago: fechaPagoIso,
      metodoPago: ticket?.metodo ?? 'Efectivo',
      casaDireccion: casa?.direccionInterna ?? 'Inmueble',
      manzanaNombre: manzana?.nombre ?? 'Manzana',
      etapaNombre: etapa?.nombre ?? 'Etapa',
      residente: residente
        ? {
            id: residente.id,
            nombre: residente.nombre,
            modalidadPago: residente.modalidadPago,
          }
        : null,
      casa: casa
        ? {
            id: casa.id,
            direccionInterna: casa.direccionInterna,
            manzana: manzana
              ? {
                  id: manzana.id,
                  nombre: manzana.nombre,
                  etapa: etapa
                    ? {
                        id: etapa.id,
                        nombre: etapa.nombre,
                      }
                    : null,
                }
              : null,
          }
        : null,
    };
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
    return this.carteraViviendaResumenQuery.execute(
      tenantId,
      etapaId,
      manzanaId,
    );
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  @ApiOperation({ summary: 'Eliminar un cobro (solo ADMIN)' })
  async eliminar(@Param('id') id: string, @CurrentTenant() tenantId: string) {
    await this.eliminarCobroUseCase.execute(id, tenantId);
    return { success: true };
  }
}
