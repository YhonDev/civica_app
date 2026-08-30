import { Injectable, NotFoundException } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { Cobro } from '../../domain/cobro.entity';
import { Etapa } from '../../../community/domain/etapa.entity';
import { Proyecto } from '../../../community/domain/proyecto.entity';

export interface GenerarReporteDto {
  tenantId: string;
  proyectoId?: string;
  mes: number;
  anio: number;
  etapaId?: string;
}

export interface ReporteRecaudoResponse {
  mes: number;
  anio: number;
  totalRecaudado: number;
  totalPendiente: number;
  totalVencido: number;
  meta: number;
  porcentaje: number;
  desglosePorEstado: {
    pagadasCount: number;
    pendientesCount: number;
    vencidasCount: number;
  };
  desglosePorEtapa: Array<{
    etapaId?: string;
    etapaNombre?: string;
    totalRecaudado: number;
    totalPendiente: number;
    totalVencido: number;
  }>;
}

@Injectable()
export class GenerarReporteUseCase {
  constructor(private readonly dataSource: DataSource) {}

  async execute(dto: GenerarReporteDto): Promise<ReporteRecaudoResponse> {
    const { mes, anio, etapaId, proyectoId, tenantId } = dto;
    const mesFormatted = String(mes).padStart(2, '0');
    const periodoInicio = `${anio}-${mesFormatted}-01`;

    const cobroRepo = this.dataSource.getRepository(Cobro);
    const etapaRepo = this.dataSource.getRepository(Etapa);

    // Validar que el proyecto pertenezca al tenant del llamador antes de usarlo.
    if (proyectoId) {
      const proyecto = await this.dataSource.getRepository(Proyecto).findOne({
        where: { id: proyectoId },
      });
      if (!proyecto || proyecto.tenantId !== tenantId) {
        throw new NotFoundException(`Proyecto ${proyectoId} no encontrado`);
      }
    }

    // Obtener etapas del proyecto para inicializar el desglose
    const etapasProyecto = proyectoId
      ? await etapaRepo.find({
          where: { proyectoId },
          order: { nombre: 'ASC' },
        })
      : await etapaRepo.find({ order: { nombre: 'ASC' } });

    const queryBuilder = cobroRepo
      .createQueryBuilder('cobro')
      .leftJoinAndSelect('cobro.casa', 'casa')
      .leftJoinAndSelect('casa.manzana', 'manzana')
      .leftJoinAndSelect('manzana.etapa', 'etapa')
      .leftJoinAndSelect('cobro.residente', 'residente')
      .leftJoinAndSelect('residente.casaActual', 'casaActual')
      .leftJoinAndSelect('casaActual.manzana', 'manzanaResidente')
      .leftJoinAndSelect('manzanaResidente.etapa', 'etapaResidente')
      .where('cobro.periodoInicio = :periodoInicio', { periodoInicio })
      .andWhere('cobro.tenantId = :tenantId', { tenantId });

    if (etapaId) {
      queryBuilder.andWhere(
        '(etapa.id = :etapaId OR etapaResidente.id = :etapaId)',
        { etapaId },
      );
    }

    const cobros = await queryBuilder.getMany();

    const desgloseMap = new Map<
      string,
      {
        etapaId: string;
        etapaNombre: string;
        totalRecaudadoCents: number;
        totalPendienteCents: number;
        totalVencidoCents: number;
      }
    >();

    for (const e of etapasProyecto) {
      if (!etapaId || e.id === etapaId) {
        desgloseMap.set(e.id, {
          etapaId: e.id,
          etapaNombre: e.nombre,
          totalRecaudadoCents: 0,
          totalPendienteCents: 0,
          totalVencidoCents: 0,
        });
      }
    }

    let totalRecaudadoCents = 0;
    let totalPendienteCents = 0;
    let totalVencidoCents = 0;
    let pagadasCount = 0;
    let pendientesCount = 0;
    let vencidasCount = 0;

    for (const c of cobros) {
      const cobroEtapa =
        c.casa?.manzana?.etapa || c.residente?.casaActual?.manzana?.etapa;
      const eId = cobroEtapa?.id;

      let target = eId ? desgloseMap.get(eId) : undefined;
      if (!target && eId) {
        target = {
          etapaId: eId,
          etapaNombre: cobroEtapa?.nombre || 'Sin Etapa',
          totalRecaudadoCents: 0,
          totalPendienteCents: 0,
          totalVencidoCents: 0,
        };
        desgloseMap.set(eId, target);
      }

      if (c.estado === 'PAGADA') {
        totalRecaudadoCents += c.monto;
        pagadasCount++;
        if (target) target.totalRecaudadoCents += c.monto;
      } else if (c.estado === 'PENDIENTE') {
        totalPendienteCents += c.monto;
        pendientesCount++;
        if (target) target.totalPendienteCents += c.monto;
      } else if (c.estado === 'VENCIDA') {
        totalVencidoCents += c.monto;
        vencidasCount++;
        if (target) target.totalVencidoCents += c.monto;
      } else if (c.estado === 'PARCIAL') {
        totalRecaudadoCents += c.montoPagado;
        const saldo = c.monto - c.montoPagado;
        totalPendienteCents += saldo;
        pendientesCount++;
        if (target) {
          target.totalRecaudadoCents += c.montoPagado;
          target.totalPendienteCents += saldo;
        }
      }
    }

    const metaCents =
      totalRecaudadoCents + totalPendienteCents + totalVencidoCents;
    const porcentaje =
      metaCents > 0
        ? Math.round((totalRecaudadoCents / metaCents) * 100)
        : 0;

    const desglosePorEtapa = Array.from(desgloseMap.values()).map((e) => ({
      etapaId: e.etapaId,
      etapaNombre: e.etapaNombre,
      totalRecaudado: Math.round(e.totalRecaudadoCents / 100),
      totalPendiente: Math.round(e.totalPendienteCents / 100),
      totalVencido: Math.round(e.totalVencidoCents / 100),
    }));

    return {
      mes,
      anio,
      totalRecaudado: Math.round(totalRecaudadoCents / 100),
      totalPendiente: Math.round(totalPendienteCents / 100),
      totalVencido: Math.round(totalVencidoCents / 100),
      meta: Math.round(metaCents / 100),
      porcentaje,
      desglosePorEstado: {
        pagadasCount,
        pendientesCount,
        vencidasCount,
      },
      desglosePorEtapa,
    };
  }
}
