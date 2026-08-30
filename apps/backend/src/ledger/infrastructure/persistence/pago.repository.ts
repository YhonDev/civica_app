import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Pago } from '../../domain/pago.entity';
import { BaseTenantRepository } from '../../../shared/common/infrastructure/base-tenant.repository';

@Injectable()
export class PagoRepository extends BaseTenantRepository<Pago> {
  constructor(
    @InjectRepository(Pago)
    protected readonly repo: Repository<Pago>,
  ) {
    super(repo);
  }

  async findById(id: string): Promise<Pago | null> {
    return this.repo.findOne({ where: { id } });
  }

  async findByIdempotentKey(
    tenantId: string,
    clientPaymentId: string,
  ): Promise<Pago | null> {
    return this.repo.findOne({ where: { tenantId, clientPaymentId } });
  }

  async findByPropietario(residenteId: string, tenantId: string): Promise<Pago[]> {
    return this.repo.find({
      where: { residenteId, tenantId },
      relations: {
        residente: { casaActual: { manzana: { etapa: true } } },
        cobro: { casa: { manzana: { etapa: true } } },
      },
      order: { createdAt: 'DESC' },
    });
  }

  async findByCobro(cobroId: string): Promise<Pago[]> {
    return this.repo.find({
      where: { cobroId },
      order: { createdAt: 'DESC' },
    });
  }

  async countByCobro(cobroId: string): Promise<number> {
    return this.repo.count({ where: { cobroId } });
  }

  async saveMany(pagos: Pago[]): Promise<Pago[]> {
    return this.repo.save(pagos);
  }

  // ── Dashboard queries ───────────────────────────────────

  async sumMontoByMonth(
    tenantId: string,
    year: number,
    month: number,
  ): Promise<number> {
    const qb = this.repo.createQueryBuilder('pago');
    this.applyTenantFilter(qb, tenantId, 'pago');
    
    const result = await qb
      .select('COALESCE(SUM(pago.monto), 0)', 'total')
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

  async countDistinctResidentesByMonth(
    tenantId: string,
    year: number,
    month: number,
  ): Promise<number> {
    const qb = this.repo.createQueryBuilder('pago');
    this.applyTenantFilter(qb, tenantId, 'pago');
    
    const result = await qb
      .select('COUNT(DISTINCT pago.residenteId)', 'count')
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
    const qb = this.repo.createQueryBuilder('pago');
    this.applyTenantFilter(qb, tenantId, 'pago');
    
    const rows = await qb
      .select(
        "EXTRACT(DAY FROM pago.fecha_pago::timestamp)",
        'dia',
      )
      .addSelect('SUM(pago.monto)', 'valor')
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
    const qb = this.repo.createQueryBuilder('pago');
    this.applyTenantFilter(qb, tenantId, 'pago');
    
    const result = await qb
      .select("CEIL(EXTRACT(DAY FROM pago.fecha_pago::timestamp) / 7.0)", 'semana')
      .addSelect('COUNT(*)', 'pagados')
      .addSelect('COALESCE(SUM(pago.monto), 0)', 'monto')
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

  /**
   * Find today's pagos made by a specific cobrador.
   * Used by COBRADOR dashboard to show "cobrados hoy".
   */
  async findByCobradorToday(
    cobradorId: string,
  ): Promise<{ pagos: Pago[]; total: number; count: number }> {
    const hoy = new Date();
    const start = `${hoy.getFullYear()}-${String(hoy.getMonth() + 1).padStart(2, '0')}-${String(hoy.getDate()).padStart(2, '0')} 00:00:00`;
    const end = `${hoy.getFullYear()}-${String(hoy.getMonth() + 1).padStart(2, '0')}-${String(hoy.getDate()).padStart(2, '0')} 23:59:59`;

    const pagos = await this.repo.find({
      where: { cobradorId },
      order: { fechaPago: 'DESC' },
    });

    // Filter in-memory by today's date (fechaPago is a string YYYY-MM-DD)
    const hoyStr = `${hoy.getFullYear()}-${String(hoy.getMonth() + 1).padStart(2, '0')}-${String(hoy.getDate()).padStart(2, '0')}`;
    const hoyPagos = pagos.filter((p) => p.fechaPago.startsWith(hoyStr));

    const total = hoyPagos.reduce((sum, p) => sum + p.monto, 0);

    return { pagos: hoyPagos, total, count: hoyPagos.length };
  }

  async sumMontoByYear(tenantId: string, year: number): Promise<number> {
    const qb = this.repo.createQueryBuilder('pago');
    this.applyTenantFilter(qb, tenantId, 'pago');
    
    const result = await qb
      .select('COALESCE(SUM(pago.monto), 0)', 'total')
      .andWhere('pago.fecha_pago >= :start AND pago.fecha_pago < :end', {
        start: `${year}-01-01`,
        end: `${year + 1}-01-01`,
      })
      .getRawOne();
    return Number(result?.total ?? 0);
  }
}
