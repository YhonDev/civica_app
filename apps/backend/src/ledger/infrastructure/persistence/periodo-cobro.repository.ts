import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PeriodoCobro } from '../../domain/periodo-cobro.entity';
import { BaseTenantRepository } from '../../../shared/common/infrastructure/base-tenant.repository';

@Injectable()
export class PeriodoCobroRepository extends BaseTenantRepository<PeriodoCobro> {
  constructor(
    @InjectRepository(PeriodoCobro)
    protected readonly repo: Repository<PeriodoCobro>,
  ) {
    super(repo);
  }

  async findActivosByPlan(planId: string): Promise<PeriodoCobro[]> {
    return this.repo.find({
      where: { planId, estado: 'ACTIVO' },
      order: { anio: 'DESC', mes: 'DESC' },
    });
  }

  async findByPlanAndMonth(
    planId: string,
    mes: number,
    anio: number,
  ): Promise<PeriodoCobro | null> {
    return this.repo.findOne({
      where: { planId, mes, anio },
    });
  }
}
