import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Pago } from '../../domain/pago.entity';

@Injectable()
export class PagoRepository {
  constructor(
    @InjectRepository(Pago)
    private readonly repo: Repository<Pago>,
  ) {}

  async findById(id: string): Promise<Pago | null> {
    return this.repo.findOne({ where: { id } });
  }

  async findByIdempotentKey(
    tenantId: string,
    clientPaymentId: string,
  ): Promise<Pago | null> {
    return this.repo.findOne({ where: { tenantId, clientPaymentId } });
  }

  async findByPropietario(propietarioId: string): Promise<Pago[]> {
    return this.repo.find({
      where: { propietarioId },
      order: { createdAt: 'DESC' },
    });
  }

  async findByCuota(cuotaId: string): Promise<Pago[]> {
    return this.repo.find({
      where: { cuotaId },
      order: { createdAt: 'DESC' },
    });
  }

  async countByCuota(cuotaId: string): Promise<number> {
    return this.repo.count({ where: { cuotaId } });
  }

  async save(pago: Pago): Promise<Pago> {
    return this.repo.save(pago);
  }

  async saveMany(pagos: Pago[]): Promise<Pago[]> {
    return this.repo.save(pagos);
  }

  async delete(id: string): Promise<void> {
    await this.repo.delete(id);
  }

  // ── Dashboard queries ───────────────────────────────────

  async sumMontoByMonth(
    tenantId: string,
    year: number,
    month: number,
  ): Promise<number> {
    const result = await this.repo
      .createQueryBuilder('pago')
      .select('COALESCE(SUM(pago.monto), 0)', 'total')
      .where('pago.tenantId = :tenantId', { tenantId })
      .andWhere(
        'pago.fecha_pago >= :start AND pago.fecha_pago < :end',
        {
          start: `${year}-${String(month).padStart(2, '0')}-01`,
          end: month === 12
            ? `${year + 1}-01-01`
            : `${year}-${String(month + 1).padStart(2, '0')}-01`,
        },
      )
      .getRawOne();
    return Number(result?.total ?? 0);
  }

  async countDistinctPropietariosByMonth(
    tenantId: string,
    year: number,
    month: number,
  ): Promise<number> {
    const result = await this.repo
      .createQueryBuilder('pago')
      .select('COUNT(DISTINCT pago.propietarioId)', 'count')
      .where('pago.tenantId = :tenantId', { tenantId })
      .andWhere(
        'pago.fecha_pago >= :start AND pago.fecha_pago < :end',
        {
          start: `${year}-${String(month).padStart(2, '0')}-01`,
          end: month === 12
            ? `${year + 1}-01-01`
            : `${year}-${String(month + 1).padStart(2, '0')}-01`,
        },
      )
      .getRawOne();
    return Number(result?.count ?? 0);
  }

  async groupByDayByMonth(
    tenantId: string,
    year: number,
    month: number,
  ): Promise<Array<{ dia: number; valor: number }>> {
    const rows = await this.repo
      .createQueryBuilder('pago')
      .select(
        "EXTRACT(DAY FROM pago.fecha_pago::timestamp)",
        'dia',
      )
      .addSelect('SUM(pago.monto)', 'valor')
      .where('pago.tenantId = :tenantId', { tenantId })
      .andWhere(
        'pago.fecha_pago >= :start AND pago.fecha_pago < :end',
        {
          start: `${year}-${String(month).padStart(2, '0')}-01`,
          end: month === 12
            ? `${year + 1}-01-01`
            : `${year}-${String(month + 1).padStart(2, '0')}-01`,
        },
      )
      .groupBy("EXTRACT(DAY FROM pago.fecha_pago::timestamp)")
      .orderBy('dia', 'ASC')
      .getRawMany();

    return rows.map((r) => ({
      dia: Number(r.dia),
      valor: Number(r.valor),
    }));
  }

  async groupByWeekInMonth(
    tenantId: string,
    year: number,
    month: number,
  ): Promise<Array<{ semana: number; pagados: number; monto: number }>> {
    const result = await this.repo
      .createQueryBuilder('pago')
      .select("CEIL(EXTRACT(DAY FROM pago.fecha_pago::timestamp) / 7.0)", 'semana')
      .addSelect('COUNT(*)', 'pagados')
      .addSelect('COALESCE(SUM(pago.monto), 0)', 'monto')
      .where('pago.tenantId = :tenantId', { tenantId })
      .andWhere(
        'pago.fecha_pago >= :start AND pago.fecha_pago < :end',
        {
          start: `${year}-${String(month).padStart(2, '0')}-01`,
          end: month === 12
            ? `${year + 1}-01-01`
            : `${year}-${String(month + 1).padStart(2, '0')}-01`,
        },
      )
      .groupBy('semana')
      .orderBy('semana', 'ASC')
      .getRawMany();

    return result.map((r) => ({
      semana: Number(r.semana),
      pagados: Number(r.pagados),
      monto: Number(r.monto),
    }));
  }

  async sumMontoByYear(tenantId: string, year: number): Promise<number> {
    const result = await this.repo
      .createQueryBuilder('pago')
      .select('COALESCE(SUM(pago.monto), 0)', 'total')
      .where('pago.tenantId = :tenantId', { tenantId })
      .andWhere('pago.fecha_pago >= :start AND pago.fecha_pago < :end', {
        start: `${year}-01-01`,
        end: `${year + 1}-01-01`,
      })
      .getRawOne();
    return Number(result?.total ?? 0);
  }
}
