import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';

export interface CarteraViviendaResumenItem {
  casaId: string;
  direccionInterna: string;
  manzanaNombre: string;
  etapaNombre: string;
  residenteNombre: string | null;
  residenteId: string | null;
  estadoMora: 'AL_DIA' | 'PENDIENTE' | 'EN_MORA' | 'SIN_CUOTAS';
  totalCuotasPagadas: number;
  totalCuotasPendientes: number;
  totalCuotasVencidas: number;
  saldoMoraCentavos: number;
}

@Injectable()
export class CarteraViviendaResumenQuery {
  constructor(private readonly dataSource: DataSource) {}

  async execute(
    tenantId: string,
    etapaId?: string,
    manzanaId?: string,
  ): Promise<CarteraViviendaResumenItem[]> {
    // 1. Obtener todas las casas con sus manzanas, etapas y tenencias activas
    let query = this.dataSource
      .createQueryBuilder()
      .select('casa.id', 'casaId')
      .addSelect('casa.direccion_interna', 'direccionInterna')
      .addSelect('manzana.nombre', 'manzanaNombre')
      .addSelect('etapa.nombre', 'etapaNombre')
      .addSelect('residente.nombre', 'residenteNombre')
      .addSelect('residente.id', 'residenteId')
      .from('casas', 'casa')
      .innerJoin('manzanas', 'manzana', 'manzana.id = casa.manzana_id')
      .innerJoin('etapas', 'etapa', 'etapa.id = manzana.etapa_id')
      .innerJoin('proyectos', 'proyecto', 'proyecto.id = etapa.proyecto_id')
      .leftJoin(
        'tenencias',
        'tenencia',
        'tenencia.casa_id = casa.id AND tenencia.fecha_fin IS NULL',
      )
      .leftJoin(
        'residentes',
        'residente',
        'residente.id = tenencia.residente_id',
      )
      .where('proyecto.tenant_id = :tenantId', { tenantId });

    if (etapaId) {
      query = query.andWhere('etapa.id = :etapaId', { etapaId });
    }

    if (manzanaId) {
      query = query.andWhere('manzana.id = :manzanaId', { manzanaId });
    }

    const casas = await query.getRawMany();

    if (casas.length === 0) {
      return [];
    }

    // 2. Obtener todos los cobros del tenant para calcular estados
    const cobros = await this.dataSource
      .createQueryBuilder()
      .select('cobro.id', 'id')
      .addSelect('cobro.casa_id', 'casaId')
      .addSelect('cobro.estado', 'estado')
      .addSelect('cobro.monto', 'monto')
      .addSelect('cobro.monto_pagado', 'montoPagado')
      .addSelect('cobro.fecha_vencimiento', 'fechaVencimiento')
      .from('cobros', 'cobro')
      .where('cobro.tenant_id = :tenantId', { tenantId })
      .getRawMany();

    // Indexar cobros por casaId para búsqueda O(1)
    const cobrosPorCasa = new Map<string, any[]>();
    for (const c of cobros) {
      if (c.casaId) {
        if (!cobrosPorCasa.has(c.casaId)) {
          cobrosPorCasa.set(c.casaId, []);
        }
        cobrosPorCasa.get(c.casaId)!.push(c);
      }
    }

    const hoyStr = new Date().toISOString().split('T')[0];

    // 3. Procesar y mapear cada casa con sus métricas consolidadas
    return casas.map((casa) => {
      const casaCobros = cobrosPorCasa.get(casa.casaId) || [];

      let totalCuotasPagadas = 0;
      let totalCuotasPendientes = 0;
      let totalCuotasVencidas = 0;
      let saldoMoraCentavos = 0;

      for (const c of casaCobros) {
        if (c.estado === 'PAGADA') {
          totalCuotasPagadas++;
        } else if (
          c.estado === 'VENCIDA' ||
          (c.estado === 'PENDIENTE' && c.fechaVencimiento < hoyStr)
        ) {
          totalCuotasVencidas++;
          saldoMoraCentavos += c.monto - c.montoPagado;
        } else if (c.estado === 'PENDIENTE' || c.estado === 'PARCIAL') {
          totalCuotasPendientes++;
        }
      }

      let estadoMora: 'AL_DIA' | 'PENDIENTE' | 'EN_MORA' | 'SIN_CUOTAS' =
        'SIN_CUOTAS';

      if (casaCobros.length > 0) {
        if (totalCuotasVencidas > 0) {
          estadoMora = 'EN_MORA';
        } else if (totalCuotasPendientes > 0) {
          estadoMora = 'PENDIENTE';
        } else if (totalCuotasPagadas > 0) {
          estadoMora = 'AL_DIA';
        }
      }

      return {
        casaId: casa.casaId,
        direccionInterna: casa.direccionInterna,
        manzanaNombre: casa.manzanaNombre,
        etapaNombre: casa.etapaNombre,
        residenteNombre: casa.residenteNombre,
        residenteId: casa.residenteId,
        estadoMora,
        totalCuotasPagadas,
        totalCuotasPendientes,
        totalCuotasVencidas,
        saldoMoraCentavos,
      };
    });
  }
}
