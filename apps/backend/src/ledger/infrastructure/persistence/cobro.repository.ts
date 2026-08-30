import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, LessThan, In, EntityManager } from 'typeorm';
import { Cobro } from '../../domain/cobro.entity';
import { BaseTenantRepository } from '../../../shared/common/infrastructure/base-tenant.repository';

@Injectable()
export class CobroRepository extends BaseTenantRepository<Cobro> {
  constructor(
    @InjectRepository(Cobro)
    protected readonly repo: Repository<Cobro>,
  ) {
    super(repo);
  }

  async findById(id: string): Promise<Cobro | null> {
    return this.repo.findOne({ where: { id } });
  }

  async findByResidente(residenteId: string, tenantId: string): Promise<Cobro[]> {
    return this.repo.find({
      where: { residenteId, tenantId },
      relations: {
        residente: { casaActual: { manzana: { etapa: true } } },
        casa: { manzana: { etapa: true } },
      },
      order: { periodoInicio: 'DESC' },
    });
  }

  async findByResidentes(residenteIds: string[]): Promise<Cobro[]> {
    if (residenteIds.length === 0) return [];
    return this.repo.createQueryBuilder('cobro')
      .where('cobro.residenteId IN (:...residenteIds)', { residenteIds })
      .orderBy('cobro.periodoInicio', 'DESC')
      .getMany();
  }

  async findPendientesByTenant(tenantId: string): Promise<Cobro[]> {
    return this.repo.find({
      where: { tenantId, estado: In(['PENDIENTE', 'VENCIDA', 'PARCIAL']) },
      relations: {
        residente: { tenencias: { casa: { manzana: { etapa: true } } }, casaActual: { manzana: { etapa: true } } },
        casa: { manzana: { etapa: true } },
      },
      order: { fechaVencimiento: 'ASC' },
    });
  }

  async countPendientesByMonth(tenantId: string, anio: number, mes: number): Promise<number> {
    const periodoInicioStr = `${anio}-${String(mes).padStart(2, '0')}-01`;
    const count = await this.repo.count({
      where: { tenantId, estado: 'PENDIENTE', periodoInicio: periodoInicioStr },
    });
    return count;
  }

  async sumSaldoVencidasByTenant(tenantId: string): Promise<number> {
    const result = await this.repo
      .createQueryBuilder('cobro')
      .select('COALESCE(SUM(cobro.monto - cobro.montoPagado), 0)', 'total')
      .where('cobro.tenantId = :tenantId', { tenantId })
      .andWhere('cobro.estado IN (:...estados)', { estados: ['VENCIDA', 'PENDIENTE', 'PARCIAL'] })
      .getRawOne();
    return Number(result?.total ?? 0);
  }

  async sumSaldoVencidasByMonth(tenantId: string, anio: number, mes: number): Promise<number> {
    const periodoInicioStr = `${anio}-${String(mes).padStart(2, '0')}-01`;
    const result = await this.repo
      .createQueryBuilder('cobro')
      .select('COALESCE(SUM(cobro.monto - cobro.montoPagado), 0)', 'total')
      .where('cobro.tenantId = :tenantId', { tenantId })
      .andWhere('cobro.periodoInicio = :periodoInicio', { periodoInicio: periodoInicioStr })
      .andWhere('cobro.estado IN (:...estados)', { estados: ['VENCIDA', 'PENDIENTE', 'PARCIAL'] })
      .getRawOne();
    return Number(result?.total ?? 0);
  }

  async sumMontoByMonth(tenantId: string, anio: number, mes: number): Promise<number> {
    const periodoInicioStr = `${anio}-${String(mes).padStart(2, '0')}-01`;
    const result = await this.repo
      .createQueryBuilder('cobro')
      .select('COALESCE(SUM(cobro.monto), 0)', 'total')
      .where('cobro.tenantId = :tenantId', { tenantId })
      .andWhere('cobro.periodoInicio = :periodoInicio', { periodoInicio: periodoInicioStr })
      .andWhere('cobro.estado != :estado', { estado: 'ANULADO' })
      .getRawOne();
    return Number(result?.total ?? 0);
  }

  async sumMontoByYear(tenantId: string, anio: number): Promise<number> {
    const result = await this.repo
      .createQueryBuilder('cobro')
      .select('COALESCE(SUM(cobro.monto), 0)', 'total')
      .where('cobro.tenantId = :tenantId', { tenantId })
      .andWhere('EXTRACT(YEAR FROM cobro.periodoInicio) = :anio', { anio })
      .getRawOne();
    return Number(result?.total ?? 0);
  }

  async countPropietariosInMora(tenantId: string): Promise<number> {
    const result = await this.repo
      .createQueryBuilder('cobro')
      .select('COUNT(DISTINCT cobro.residenteId)', 'count')
      .where('cobro.tenantId = :tenantId', { tenantId })
      .andWhere('cobro.estado IN (:...estados)', { estados: ['VENCIDA', 'PENDIENTE', 'PARCIAL'] })
      .getRawOne();
    return Number(result?.count ?? 0);
  }

  async countByEstadoInMonth(tenantId: string, anio: number, mes: number): Promise<{ pagadas: number; pendientes: number }> {
    const periodoInicioStr = `${anio}-${String(mes).padStart(2, '0')}-01`;
    const result = await this.repo
      .createQueryBuilder('cobro')
      .select([
        "COALESCE(SUM(CASE WHEN cobro.estado IN ('PAGADA', 'PARCIAL') THEN 1 ELSE 0 END), 0) AS pagadas",
        "COALESCE(SUM(CASE WHEN cobro.estado IN ('PENDIENTE', 'VENCIDA') THEN 1 ELSE 0 END), 0) AS pendientes",
      ])
      .where('cobro.tenantId = :tenantId', { tenantId })
      .andWhere('cobro.periodoInicio = :periodoInicio', { periodoInicio: periodoInicioStr })
      .getRawOne();
    return {
      pagadas: Number(result?.pagadas ?? 0),
      pendientes: Number(result?.pendientes ?? 0),
    };
  }

  async groupByTarifaModalidad(tenantId: string, anio: number, mes: number): Promise<any[]> {
    const periodoInicioStr = `${anio}-${String(mes).padStart(2, '0')}-01`;
    return this.repo
      .createQueryBuilder('cobro')
      .select([
        'tarifa.modalidad AS modalidad',
        'COUNT(cobro.id) AS totalCuotas',
        "COALESCE(SUM(CASE WHEN cobro.estado IN ('PAGADA', 'PARCIAL') THEN 1 ELSE 0 END), 0) AS pagadas",
      ])
      .leftJoin('tarifas', 'tarifa', 'tarifa.id = cobro.tarifaId')
      .where('cobro.tenantId = :tenantId', { tenantId })
      .andWhere('cobro.periodoInicio = :periodoInicio', { periodoInicio: periodoInicioStr })
      .groupBy('tarifa.modalidad')
      .getRawMany();
  }

  async groupByWeekInMonth(tenantId: string, anio: number, mes: number): Promise<{ semana: number; pagados: number }[]> {
    return this.repo
      .createQueryBuilder('cobro')
      .select([
        'EXTRACT(WEEK FROM cobro.periodoInicio) AS semana',
        'COUNT(cobro.id) AS pagados',
      ])
      .where('cobro.tenantId = :tenantId', { tenantId })
      .andWhere('EXTRACT(YEAR FROM cobro.periodoInicio) = :anio', { anio })
      .andWhere('EXTRACT(MONTH FROM cobro.periodoInicio) = :mes', { mes })
      .andWhere("cobro.estado IN ('PAGADA', 'PARCIAL')")
      .groupBy('EXTRACT(WEEK FROM cobro.periodoInicio)')
      .orderBy('semana', 'ASC')
      .getRawMany();
  }

  async countPendientesByWeek(tenantId: string, anio: number, mes: number): Promise<{ semana: number; pendientes: number; enMora: number }[]> {
    return this.repo
      .createQueryBuilder('cobro')
      .select([
        'EXTRACT(WEEK FROM cobro.periodoInicio) AS semana',
        "COALESCE(SUM(CASE WHEN cobro.estado IN ('PENDIENTE') THEN 1 ELSE 0 END), 0) AS pendientes",
        "COALESCE(SUM(CASE WHEN cobro.estado IN ('VENCIDA') THEN 1 ELSE 0 END), 0) AS enMora",
      ])
      .where('cobro.tenantId = :tenantId', { tenantId })
      .andWhere('EXTRACT(YEAR FROM cobro.periodoInicio) = :anio', { anio })
      .andWhere('EXTRACT(MONTH FROM cobro.periodoInicio) = :mes', { mes })
      .andWhere("cobro.estado IN ('PENDIENTE', 'VENCIDA')")
      .groupBy('EXTRACT(WEEK FROM cobro.periodoInicio)')
      .orderBy('semana', 'ASC')
      .getRawMany();
  }

  async findMasAntiguoConSaldo(residenteId: string): Promise<Cobro | null> {
    return this.repo.findOne({
      where: { residenteId, estado: In(['VENCIDA', 'PARCIAL', 'PENDIENTE']) },
      order: { fechaVencimiento: 'ASC' },
    });
  }

  /**
   * Finds the oldest cobro with pending balance, locking the row
   * with PESSIMISTIC_WRITE to prevent concurrent payment race conditions.
   * Must be called within an active database transaction.
   */
  async findMasAntiguoConSaldoLocked(
    entityManager: EntityManager,
    residenteId: string,
    tenantId: string,
  ): Promise<Cobro | null> {
    return entityManager
      .createQueryBuilder(Cobro, 'cobro')
      .where('cobro.residenteId = :residenteId', { residenteId })
      .andWhere('cobro.tenantId = :tenantId', { tenantId })
      .andWhere('cobro.estado IN (:...estados)', {
        estados: ['VENCIDA', 'PARCIAL', 'PENDIENTE'],
      })
      .orderBy('cobro.fechaVencimiento', 'ASC')
      .setLock('pessimistic_write', undefined, ['cobro'])
      .getOne();
  }

  async saveMany(cobros: Cobro[]): Promise<Cobro[]> {
    return this.repo.save(cobros);
  }

  async findVencidas(): Promise<Cobro[]> {
    const hoy = new Date().toISOString().split('T')[0];
    return this.repo.find({
      where: [
        { estado: 'PENDIENTE', fechaVencimiento: LessThan(hoy) },
        { estado: 'PARCIAL', fechaVencimiento: LessThan(hoy) },
      ],
    });
  }

  async findAllWithFilters(
    tenantId: string,
    filters: { etapaId?: string; manzanaId?: string; status?: string },
    allowedEtapaIds?: string[],
  ): Promise<Cobro[]> {
    const qb = this.repo.createQueryBuilder('cobro')
      .leftJoinAndSelect('cobro.residente', 'residente')
      .leftJoinAndSelect('residente.casaActual', 'casa')
      .leftJoinAndSelect('casa.manzana', 'manzana')
      .leftJoinAndSelect('manzana.etapa', 'etapa')
      .where('cobro.tenantId = :tenantId', { tenantId });

    if (allowedEtapaIds && allowedEtapaIds.length > 0) {
      qb.andWhere('manzana.etapaId IN (:...allowedEtapaIds)', { allowedEtapaIds });
    }

    if (filters.etapaId) {
      qb.andWhere('manzana.etapaId = :etapaId', { etapaId: filters.etapaId });
    }

    if (filters.manzanaId) {
      qb.andWhere('casa.manzanaId = :manzanaId', { manzanaId: filters.manzanaId });
    }

    if (filters.status) {
      const statusUpper = filters.status.toUpperCase();
      if (statusUpper === 'MORA' || statusUpper === 'VENCIDO' || statusUpper === 'VENCIDA') {
        qb.andWhere('cobro.estado = :status', { status: 'VENCIDA' });
      } else if (statusUpper === 'PENDIENTE') {
        qb.andWhere('cobro.estado = :status', { status: 'PENDIENTE' });
      } else if (statusUpper === 'PAGADO' || statusUpper === 'PAGADA') {
        qb.andWhere('cobro.estado = :status', { status: 'PAGADA' });
      } else {
        qb.andWhere('cobro.estado = :status', { status: statusUpper });
      }
    }

    qb.orderBy('cobro.fechaVencimiento', 'ASC');
    return qb.getMany();
  }
}
