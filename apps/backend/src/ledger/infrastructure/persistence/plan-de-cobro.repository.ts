import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { BaseTenantRepository } from '../../../shared/common/infrastructure/base-tenant.repository';
import { PlanDeCobro } from '../../domain/plan-de-cobro.entity';

@Injectable()
export class PlanDeCobroRepository extends BaseTenantRepository<PlanDeCobro> {
  constructor(
    @InjectRepository(PlanDeCobro)
    protected readonly repo: Repository<PlanDeCobro>,
  ) {
    super(repo);
  }

  async findByResidente(residenteId: string): Promise<PlanDeCobro | null> {
    return this.repo.findOne({
      where: { residenteId, activa: true },
    });
  }

  async findByCasa(casaId: string): Promise<PlanDeCobro | null> {
    return this.repo.findOne({
      where: { casaId, activa: true },
    });
  }

  async findActivosByTenant(tenantId: string): Promise<PlanDeCobro[]> {
    return this.repo.find({
      where: { tenantId, activa: true },
    });
  }
}
