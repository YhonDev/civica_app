import { Injectable, Logger } from '@nestjs/common';
import { PagoRepository } from '../../infrastructure/persistence/pago.repository';
import { CobroRepository } from '../../infrastructure/persistence/cobro.repository';
import { ActividadRepository } from '../../../notifications/domain/actividad.repository';
import { SolicitudRepository } from '../../infrastructure/persistence/solicitud.repository';
import { ResidenteRepository } from '../../../community/infrastructure/residente.repository';
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
    private readonly cobroRepo: CobroRepository,
    private readonly actividadRepo: ActividadRepository,
    private readonly solicitudRepo: SolicitudRepository,
    private readonly residenteRepo: ResidenteRepository,
  ) {}

  async execute(
    mes: number,
    anio: number,
    tenantId: string,
  ): Promise<DashboardResponse> {
    try {
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
        nuevosResidentesSemana,
        residentesMora,
        acumuladoAnual,
        metaAnual,
        cobrosSemanaPagos,
        cobrosSemanaCuotas,
        totalResidentes,
      ] = await Promise.all([
        this.pagoRepo.sumMontoByMonth(tenantId, anio, mes).catch(() => 0),
        this.cobroRepo.sumMontoByMonth(tenantId, anio, mes).catch(() => 0),
        this.pagoRepo.countDistinctResidentesByMonth(tenantId, anio, mes).catch(() => 0),
        this.cobroRepo.countPendientesByMonth(tenantId, anio, mes).catch(() => 0),
        this.cobroRepo.sumSaldoVencidasByTenant(tenantId).catch(() => 0),
        this.pagoRepo.groupByDayByMonth(tenantId, anio, mes).catch(() => [] as any[]),
        this.cobroRepo.groupByTarifaFrecuencia(tenantId, anio, mes).catch(() => [] as any[]),
        this.cobroRepo.countByEstadoInMonth(tenantId, anio, mes).catch(() => ({ pagadas: 0, pendientes: 0 })),
        this.actividadRepo.findByTenant(tenantId, 20).catch(() => [] as any[]),
        this.solicitudRepo.findPendingByTenant(tenantId).catch(() => [] as any[]),
        this.residenteRepo.countNuevosByWeek(tenantId).catch(() => 0),
        this.cobroRepo.countPropietariosInMora(tenantId).catch(() => 0),
        this.pagoRepo.sumMontoByYear(tenantId, anio).catch(() => 0),
        this.cobroRepo.sumMontoByYear(tenantId, anio).catch(() => 0),
        this.pagoRepo.groupByWeekInMonth(tenantId, anio, mes).catch(() => [] as any[]),
        this.cobroRepo.countPendientesByWeek(tenantId, anio, mes).catch(() => [] as any[]),
        this.residenteRepo.countByTenant(tenantId).catch(() => 0),
      ]);

      const safeRecaudoTotal = Number(recaudoTotal) || 0;
      const safeMetaMensual = Number(metaMensual) || 0;

      const porcentajeMeta =
        safeMetaMensual > 0
          ? Math.round((safeRecaudoTotal / safeMetaMensual) * 10000) / 100
          : 0;

      const totalCobros =
        (estadoCobrosRaw?.pagadas ?? 0) + (estadoCobrosRaw?.pendientes ?? 0);

      const modalidades = (modalidadesRaw || []).map((m: any) => {
        const total = Number(m.totalCuotas) || 0;
        const pagadas = Number(m.pagadas) || 0;
        const porcentaje = total > 0 ? Math.round((pagadas / total) * 10000) / 100 : 0;
        
        return {
          frecuencia: m.frecuencia || 'DESCONOCIDO',
          totalCuotas: total,
          pagadas: pagadas,
          porcentaje: porcentaje,
          montoRecaudo: Math.round((porcentaje / 100) * safeRecaudoTotal),
        };
      });

      // Merge pagos + cobros by semana
      const semanaMap = new Map<
        number,
        { pagados: number; pendientes: number; mora: number }
      >();
      
      (cobrosSemanaPagos || []).forEach((p: any) => {
        semanaMap.set(p.semana, { pagados: Number(p.pagados) || 0, pendientes: 0, mora: 0 });
      });
      
      (cobrosSemanaCuotas || []).forEach((c: any) => {
        const existing = semanaMap.get(c.semana) || { pagados: 0, pendientes: 0, mora: 0 };
        semanaMap.set(c.semana, {
          ...existing,
          pendientes: Number(c.pendientes) || 0,
          mora: Number(c.enMora) || 0,
        });
      });

      const cobrosPorSemana: CobroSemanaItem[] = Array.from(semanaMap.entries())
        .sort((a, b) => a[0] - b[0])
        .map(([semana, data]) => ({ semana, ...data }));

      const actividad: ActividadItem[] = (actividadRecords || []).map((a: any) => ({
        id: String(a.id),
        tipo: a.tipo,
        descripcion: a.descripcion,
        usuario: a.usuarioNombre,
        timestamp: a.createdAt?.toISOString() || new Date().toISOString(),
        hace: a.createdAt ? this.relativeTime(a.createdAt) : 'ahora',
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
            this.pagoRepo.sumMontoByMonth(tenantId, targetAnio, targetMes).catch(() => 0),
            this.cobroRepo.countPendientesByMonth(tenantId, targetAnio, targetMes).catch(() => 0),
            this.cobroRepo.sumSaldoVencidasByMonth(tenantId, targetAnio, targetMes).catch(() => 0),
          ]).then(([recaudo, mPendientes, mMora]) => ({
            mes: targetMes,
            anio: targetAnio,
            recaudo: Number(recaudo) || 0,
            pendientes: Number(mPendientes) || 0,
            mora: Number(mMora) || 0,
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
          recaudoTotal: safeRecaudoTotal,
          metaMensual: safeMetaMensual,
          porcentajeMeta,
          pagaron: Number(pagaron) || 0,
          pendientes: Number(pendientes) || 0,
          moraTotal: Number(moraTotal) || 0,
        },
        evolucion: (evolucion || []).map((e: any) => ({ dia: String(e.dia), valor: Number(e.valor) })),
        modalidades,
        estadoCobros: {
          pagados: totalCobros > 0 ? Math.round(((estadoCobrosRaw?.pagadas ?? 0) / totalCobros) * 10000) / 100 : 0,
          pendientes: totalCobros > 0 ? Math.round(((estadoCobrosRaw?.pendientes ?? 0) / totalCobros) * 10000) / 100 : 0,
          revision: 0,
        },
        actividad,
        solicitudesPendientes: Number(solicitudesPendientesList?.length) || 0,
        nuevosResidentesSemana: Number(nuevosResidentesSemana) || 0,
        residentesMora: Number(residentesMora) || 0,
        pagosRevision: 0,
        totalResidentes: Number(totalResidentes) || 0,
        acumuladoAnual: Number(acumuladoAnual) || 0,
        metaAnual: Number(metaAnual) || 0,
        historialMeses,
        cobrosPorSemana,
      };
    } catch (error) {
      this.logger.error(`Critical error in DashboardQuery: ${error.message}`, error.stack);
      return {
        mes,
        anio,
        resumen: { recaudoTotal: 0, metaMensual: 0, porcentajeMeta: 0, pagaron: 0, pendientes: 0, moraTotal: 0 },
        evolucion: [],
        modalidades: [],
        estadoCobros: { pagados: 0, pendientes: 0, revision: 0 },
        actividad: [],
        solicitudesPendientes: 0,
        nuevosResidentesSemana: 0,
        residentesMora: 0,
        pagosRevision: 0,
        totalResidentes: 0,
        acumuladoAnual: 0,
        metaAnual: 0,
        historialMeses: [],
        cobrosPorSemana: [],
      };
    }
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
