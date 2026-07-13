import { Injectable, Logger } from '@nestjs/common';
import { PagoRepository } from '../../infrastructure/persistence/pago.repository';
import { CuotaRepository } from '../../infrastructure/persistence/cuota.repository';
import { ActividadRepository } from '../../../notifications/domain/actividad.repository';
import { SolicitudRepository } from '../../infrastructure/persistence/solicitud.repository';
import { PropietarioRepository } from '../../../community/infrastructure/propietario.repository';
import {
  DashboardResponse,
  ActividadItem,
  CobroSemanaItem,
} from '../dtos/dashboard.dto';

@Injectable()
export class DashboardQuery {
  private readonly logger = new Logger(DashboardQuery.name);

  constructor(
    private readonly pagoRepo: PagoRepository,
    private readonly cuotaRepo: CuotaRepository,
    private readonly actividadRepo: ActividadRepository,
    private readonly solicitudRepo: SolicitudRepository,
    private readonly propietarioRepo: PropietarioRepository,
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
      solicitudesPendientesList,
      nuevosPropietariosSemana,
      propietariosMora,
      acumuladoAnual,
      metaAnual,
      cobrosSemanaPagos,
      cobrosSemanaCuotas,
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
      this.solicitudRepo.findPendingByTenant(tenantId),
      this.propietarioRepo.countNuevosByWeek(tenantId),
      this.cuotaRepo.countPropietariosInMora(tenantId),
      this.pagoRepo.sumMontoByYear(tenantId, anio),
      this.cuotaRepo.sumMontoByYear(tenantId, anio),
      this.pagoRepo.groupByWeekInMonth(tenantId, anio, mes),
      this.cuotaRepo.countPendientesByWeek(tenantId, anio, mes),
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
      montoRecaudo: Math.round(
        ((m.totalCuotas > 0
          ? Math.round((m.pagadas / m.totalCuotas) * 10000) / 100
          : 0) /
          100) *
          recaudoTotal,
      ),
    }));

    // Merge pagos + cuotas by semana
    const semanaMap = new Map<
      number,
      { pagados: number; pendientes: number; mora: number }
    >();
    for (const p of cobrosSemanaPagos) {
      semanaMap.set(p.semana, {
        pagados: p.pagados,
        pendientes: 0,
        mora: 0,
      });
    }
    for (const c of cobrosSemanaCuotas) {
      const existing = semanaMap.get(c.semana);
      if (existing) {
        existing.pendientes = c.pendientes;
        existing.mora = c.enMora;
      } else {
        semanaMap.set(c.semana, {
          pagados: 0,
          pendientes: c.pendientes,
          mora: c.enMora,
        });
      }
    }
    const cobrosPorSemana: CobroSemanaItem[] = Array.from(semanaMap.entries())
      .sort((a, b) => a[0] - b[0])
      .map(([semana, data]) => ({ semana, ...data }));

    const actividad: ActividadItem[] = actividadRecords.map((a) => ({
      id: a.id,
      tipo: a.tipo,
      descripcion: a.descripcion,
      usuario: a.usuarioNombre,
      timestamp: a.createdAt.toISOString(),
      hace: this.relativeTime(a.createdAt),
    }));

    // Calcular historial de los últimos 12 meses
    const historialPromesas = [];
    let tempMes = mes;
    let tempAnio = anio;
    for (let i = 0; i < 12; i++) {
      const targetMes = tempMes;
      const targetAnio = tempAnio;
      historialPromesas.push(
        Promise.all([
          this.pagoRepo.sumMontoByMonth(tenantId, targetAnio, targetMes),
          this.cuotaRepo.countPendientesByMonth(tenantId, targetAnio, targetMes),
          this.cuotaRepo.sumSaldoVencidasByMonth(tenantId, targetAnio, targetMes),
        ]).then(([recaudo, mPendientes, mMora]) => ({
          mes: targetMes,
          anio: targetAnio,
          recaudo,
          pendientes: mPendientes,
          mora: mMora,
        })),
      );
      tempMes--;
      if (tempMes < 1) {
        tempMes = 12;
        tempAnio--;
      }
    }
    const historialMeses = await Promise.all(historialPromesas);

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
      evolucion: evolucion.map(e => ({ dia: e.dia, valor: e.valor })),
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
      solicitudesPendientes: solicitudesPendientesList.length,
      nuevosPropietariosSemana,
      propietariosMora,
      acumuladoAnual,
      metaAnual,
      historialMeses,
      cobrosPorSemana,
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
