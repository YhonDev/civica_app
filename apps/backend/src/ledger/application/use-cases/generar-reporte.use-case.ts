import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { Cobro } from '../../domain/cobro.entity';
import { Pago } from '../../domain/pago.entity';

export interface GenerarReporteDto {
  proyectoId: string;
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
    const { mes, anio, etapaId } = dto;
    const mesFormatted = String(mes).padStart(2, '0');
    const periodoInicio = `${anio}-${mesFormatted}-01`;

    const cobroRepo = this.dataSource.getRepository(Cobro);
    const pagoRepo = this.dataSource.getRepository(Pago);

    const queryBuilder = cobroRepo
      .createQueryBuilder('cobro')
      .where('cobro.periodoInicio = :periodoInicio', { periodoInicio });

    const cobros = await queryBuilder.getMany();

    let totalRecaudadoCents = 0;
    let totalPendienteCents = 0;
    let totalVencidoCents = 0;
    let pagadasCount = 0;
    let pendientesCount = 0;
    let vencidasCount = 0;

    for (const c of cobros) {
      if (c.estado === 'PAGADA') {
        totalRecaudadoCents += c.monto;
        pagadasCount++;
      } else if (c.estado === 'PENDIENTE') {
        totalPendienteCents += c.monto;
        pendientesCount++;
      } else if (c.estado === 'VENCIDA') {
        totalVencidoCents += c.monto;
        vencidasCount++;
      }
    }

    const metaCents = totalRecaudadoCents + totalPendienteCents + totalVencidoCents;
    const porcentaje = metaCents > 0 ? Math.round((totalRecaudadoCents / metaCents) * 100) : 0;

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
      desglosePorEtapa: [],
    };
  }
}
