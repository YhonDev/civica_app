import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, LessThan } from 'typeorm';
import { Cuota } from '../../domain/cuota.entity';

@Injectable()
export class CuotaRepository {
  constructor(
    @InjectRepository(Cuota)
    private readonly repo: Repository<Cuota>,
  ) {}

  async findByPropietario(
    propietarioId: string,
    estado?: string,
  ): Promise<Cuota[]> {
    const where: any = { propietarioId };
    if (estado) {
      where.estado = estado;
    }
    return this.repo.find({
      where,
      order: { periodoInicio: 'DESC' },
    });
  }

  /** Cuotas in PENDIENTE or VENCIDA state */
  async findPendientesYVencidas(propietarioId: string): Promise<Cuota[]> {
    return this.repo.find({
      where: [
        { propietarioId, estado: 'PENDIENTE' },
        { propietarioId, estado: 'VENCIDA' },
      ],
      order: { periodoInicio: 'ASC' },
    });
  }

  /**
   * Find all cuotas where estado is PENDIENTE or PARCIAL
   * and fechaVencimiento < fechaHoy (for the cron job).
   */
  async findVencidas(fechaHoy: string): Promise<Cuota[]> {
    return this.repo
      .createQueryBuilder('cuota')
      .where('cuota.estado IN (:...estados)', {
        estados: ['PENDIENTE', 'PARCIAL'],
      })
      .andWhere('cuota.fechaVencimiento < :fechaHoy', { fechaHoy })
      .getMany();
  }

  /** Oldest cuota with saldo > 0 (for FIFO payment application) */
  async findMasAntiguaConSaldo(propietarioId: string): Promise<Cuota | null> {
    return this.repo
      .createQueryBuilder('cuota')
      .where('cuota.propietarioId = :propietarioId', { propietarioId })
      .andWhere('cuota.monto > cuota.montoPagado')
      .orderBy('cuota.periodoInicio', 'ASC')
      .limit(1)
      .getOne();
  }

  /** Latest cuota generated for a propietario (for period calculation) */
  async findUltimaPorPropietario(
    propietarioId: string,
  ): Promise<Cuota | null> {
    return this.repo
      .createQueryBuilder('cuota')
      .where('cuota.propietarioId = :propietarioId', { propietarioId })
      .orderBy('cuota.periodoFin', 'DESC')
      .limit(1)
      .getOne();
  }

  async existsForPropietarioAndPeriodo(
    propietarioId: string,
    periodoInicio: string,
  ): Promise<boolean> {
    const count = await this.repo.count({
      where: { propietarioId, periodoInicio },
    });
    return count > 0;
  }

  async save(cuota: Cuota): Promise<Cuota> {
    return this.repo.save(cuota);
  }

  async saveMany(cuotas: Cuota[]): Promise<Cuota[]> {
    return this.repo.save(cuotas);
  }

  // ── Dashboard queries ───────────────────────────────────

  async sumMontoByMonth(
    tenantId: string,
    year: number,
    month: number,
  ): Promise<number> {
    const result = await this.repo
      .createQueryBuilder('cuota')
      .select('COALESCE(SUM(cuota.monto), 0)', 'total')
      .where('cuota.tenantId = :tenantId', { tenantId })
      .andWhere('cuota.periodoInicio < :end', {
        end: month === 12
          ? `${year + 1}-01-01`
          : `${year}-${String(month + 1).padStart(2, '0')}-01`,
      })
      .andWhere('cuota.periodoFin >= :start', {
        start: `${year}-${String(month).padStart(2, '0')}-01`,
      })
      .getRawOne();
    return Number(result?.total ?? 0);
  }

  async countPendientesByMonth(
    tenantId: string,
    year: number,
    month: number,
  ): Promise<number> {
    const result = await this.repo
      .createQueryBuilder('cuota')
      .select(
        'COUNT(DISTINCT cuota.propietarioId)',
        'count',
      )
      .where('cuota.tenantId = :tenantId', { tenantId })
      .andWhere('cuota.periodoInicio < :end', {
        end: month === 12
          ? `${year + 1}-01-01`
          : `${year}-${String(month + 1).padStart(2, '0')}-01`,
      })
      .andWhere('cuota.periodoFin >= :start', {
        start: `${year}-${String(month).padStart(2, '0')}-01`,
      })
      .andWhere('cuota.estado IN (:...estados)', {
        estados: ['PENDIENTE', 'PARCIAL', 'VENCIDA'],
      })
      .getRawOne();
    return Number(result?.count ?? 0);
  }

  async sumSaldoVencidasByTenant(tenantId: string): Promise<number> {
    const result = await this.repo
      .createQueryBuilder('cuota')
      .select(
        'COALESCE(SUM(cuota.monto - cuota.montoPagado), 0)',
        'total',
      )
      .where('cuota.tenantId = :tenantId', { tenantId })
      .andWhere('cuota.estado = :estado', { estado: 'VENCIDA' })
      .getRawOne();
    return Number(result?.total ?? 0);
  }

  async countByEstadoInMonth(
    tenantId: string,
    year: number,
    month: number,
  ): Promise<{ pagadas: number; pendientes: number }> {
    const rows = await this.repo
      .createQueryBuilder('cuota')
      .select('cuota.estado', 'estado')
      .addSelect('COUNT(*)', 'count')
      .where('cuota.tenantId = :tenantId', { tenantId })
      .andWhere('cuota.periodoInicio < :end', {
        end: month === 12
          ? `${year + 1}-01-01`
          : `${year}-${String(month + 1).padStart(2, '0')}-01`,
      })
      .andWhere('cuota.periodoFin >= :start', {
        start: `${year}-${String(month).padStart(2, '0')}-01`,
      })
      .groupBy('cuota.estado')
      .getRawMany();

    const counts: Record<string, number> = {};
    for (const row of rows) {
      counts[row.estado] = Number(row.count);
    }

    return {
      pagadas: counts['PAGADA'] ?? 0,
      pendientes:
        (counts['PENDIENTE'] ?? 0) +
        (counts['PARCIAL'] ?? 0) +
        (counts['VENCIDA'] ?? 0),
    };
  }

  async groupByTarifaFrecuencia(
    tenantId: string,
    year: number,
    month: number,
  ): Promise<
    Array<{
      frecuencia: string;
      totalCuotas: number;
      pagadas: number;
    }>
  > {
    const rows = await this.repo
      .createQueryBuilder('cuota')
      .leftJoin(
        'tarifas',
        'tarifa',
        'tarifa.id = cuota.tarifa_id',
      )
      .select('tarifa.frecuencia', 'frecuencia')
      .addSelect('COUNT(*)', 'totalCuotas')
      .addSelect(
        "SUM(CASE WHEN cuota.estado = 'PAGADA' THEN 1 ELSE 0 END)",
        'pagadas',
      )
      .where('cuota.tenantId = :tenantId', { tenantId })
      .andWhere('cuota.periodoInicio < :end', {
        end: month === 12
          ? `${year + 1}-01-01`
          : `${year}-${String(month + 1).padStart(2, '0')}-01`,
      })
      .andWhere('cuota.periodoFin >= :start', {
        start: `${year}-${String(month).padStart(2, '0')}-01`,
      })
      .groupBy('tarifa.frecuencia')
      .getRawMany();

    return rows.map((r) => ({
      frecuencia: r.frecuencia ?? 'SIN_TARIFA',
      totalCuotas: Number(r.totalCuotas),
      pagadas: Number(r.pagadas),
    }));
  }
}
