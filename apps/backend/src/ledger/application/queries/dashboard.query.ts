import { Injectable, Logger } from '@nestjs/common';
import { PagoRepository } from '../../infrastructure/persistence/pago.repository';
import { CuotaRepository } from '../../infrastructure/persistence/cuota.repository';
import { ActividadRepository } from '../../../notifications/domain/actividad.repository';
import {
  DashboardResponse,
  ActividadItem,
} from '../dtos/dashboard.dto';

@Injectable()
export class DashboardQuery {
  private readonly logger = new Logger(DashboardQuery.name);

  constructor(
    private readonly pagoRepo: PagoRepository,
    private readonly cuotaRepo: CuotaRepository,
    private readonly actividadRepo: ActividadRepository,
  ) {}

  async execute(
    mes: number,
    anio: number,
    tenantId: string,
  ): Promise<DashboardResponse> {
    const [
      recaudoTotal,
      metaMensual,
      pagaron,
      pendientes,
      moraTotal,
      evolucion,
      modalidadesRaw,
      estadoCobrosRaw,
      actividadRecords,
    ] = await Promise.all([
      this.pagoRepo.sumMontoByMonth(tenantId, anio, mes),
      this.cuotaRepo.sumMontoByMonth(tenantId, anio, mes),
      this.pagoRepo.countDistinctPropietariosByMonth(tenantId, anio, mes),
      this.cuotaRepo.countPendientesByMonth(tenantId, anio, mes),
      this.cuotaRepo.sumSaldoVencidasByTenant(tenantId),
      this.pagoRepo.groupByDayByMonth(tenantId, anio, mes),
      this.cuotaRepo.groupByTarifaFrecuencia(tenantId, anio, mes),
      this.cuotaRepo.countByEstadoInMonth(tenantId, anio, mes),
      this.actividadRepo.findByTenant(tenantId, 20),
    ]);

    const porcentajeMeta =
      metaMensual > 0
        ? Math.round((recaudoTotal / metaMensual) * 10000) / 100
        : 0;

    const totalCobros =
      estadoCobrosRaw.pagadas + estadoCobrosRaw.pendientes;

    const modalidades = modalidadesRaw.map((m) => ({
      frecuencia: m.frecuencia,
      totalCuotas: m.totalCuotas,
      pagadas: m.pagadas,
      porcentaje:
        m.totalCuotas > 0
          ? Math.round((m.pagadas / m.totalCuotas) * 10000) / 100
          : 0,
    }));

    const actividad: ActividadItem[] = actividadRecords.map((a) => ({
      id: a.id,
      tipo: a.tipo,
      descripcion: a.descripcion,
      usuario: a.usuarioNombre,
      timestamp: a.createdAt.toISOString(),
      hace: this.relativeTime(a.createdAt),
    }));

    return {
      mes,
      anio,
      resumen: {
        recaudoTotal,
        metaMensual,
        porcentajeMeta,
        pagaron,
        pendientes,
        moraTotal,
      },
      evolucion,
      modalidades,
      estadoCobros: {
        pagados:
          totalCobros > 0
            ? Math.round((estadoCobrosRaw.pagadas / totalCobros) * 10000) /
              100
            : 0,
        pendientes:
          totalCobros > 0
            ? Math.round(
                (estadoCobrosRaw.pendientes / totalCobros) * 10000,
              ) / 100
            : 0,
        revision: 0,
      },
      actividad,
    };
  }

  private relativeTime(date: Date): string {
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMin = Math.floor(diffMs / 60000);

    if (diffMin < 1) return 'ahora';
    if (diffMin < 60) return `hace ${diffMin} min`;

    const diffHours = Math.floor(diffMin / 60);
    if (diffHours < 24) return `hace ${diffHours}h`;

    const diffDays = Math.floor(diffHours / 24);
    if (diffDays < 30) return `hace ${diffDays}d`;

    const diffMonths = Math.floor(diffDays / 30);
    return `hace ${diffMonths}m`;
  }
}
