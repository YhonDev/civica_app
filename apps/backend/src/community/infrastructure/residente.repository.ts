import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Residente } from '../domain/residente.entity';
import { BaseTenantRepository } from '../../shared/common/infrastructure/base-tenant.repository';

interface BuscarPorFiltrosParams {
  etapaId?: string;
  casaId?: string;
  tenantId: string;
}

@Injectable()
export class ResidenteRepository extends BaseTenantRepository<Residente> {
  constructor(
    @InjectRepository(Residente)
    protected readonly repo: Repository<Residente>,
  ) {
    super(repo);
  }

  async findByTenant(tenantId: string): Promise<Residente[]> {
    return super.findByTenant(tenantId, {
      order: { nombre: 'ASC' },
    });
  }

  async countByTenant(tenantId: string): Promise<number> {
    return super.countByTenant(tenantId);
  }

  async findById(id: string, tenantId: string): Promise<Residente | null> {
    return this.repo.findOne({ where: { id, tenantId } });
  }

  /**
   * Busca residentes con filtros opcionales por etapa (a través de tenencias y casas)
   * y/o casa (a través de tenencias). tenantId es obligatorio.
   */
  async buscarPorFiltros(params: BuscarPorFiltrosParams): Promise<Residente[]> {
    const qb = this.repo.createQueryBuilder('residente');
    this.applyTenantFilter(qb, params.tenantId, 'residente');
    qb.leftJoinAndSelect('residente.tenencias', 'tenencia');
    qb.leftJoinAndSelect('tenencia.casa', 'casa');
    qb.leftJoinAndSelect('casa.manzana', 'manzana');
    qb.leftJoinAndSelect('manzana.etapa', 'etapa');
    qb.leftJoinAndSelect('residente.cobros', 'cobros');

    if (params.casaId) {
      qb.andWhere('tenencia.casaId = :casaId', { casaId: params.casaId });
    }

    if (params.etapaId) {
      const subQuery = qb
        .subQuery()
        .select('c.id')
        .from('casas', 'c')
        .where('c.etapaId = :etapaId')
        .getQuery();
      qb.andWhere(`tenencia.casaId IN ${subQuery}`, {
        etapaId: params.etapaId,
      });
    }

    return qb.getMany();
  }

  async findWithTenencia(
    residenteId: string,
    tenantId: string,
  ): Promise<Residente | null> {
    return this.repo.findOne({
      where: { id: residenteId, tenantId },
      relations: { tenencias: true },
    });
  }

  async findByIdWithRelations(
    id: string,
    tenantId: string,
  ): Promise<Residente | null> {
    return this.repo.findOne({
      where: { id, tenantId },
      relations: {
        tenencias: {
          casa: {
            manzana: {
              etapa: true,
            },
          },
        },
      },
    });
  }

  /**
   * Busca residentes cuyas casas estén en una o más etapas específicas.
   * Usado por COBRADORES que solo ven residentes de sus etapas asignadas.
   */
  async buscarPorEtapas(
    tenantId: string,
    etapaIds: string[],
  ): Promise<Residente[]> {
    if (!etapaIds || etapaIds.length === 0) {
      return [];
    }

    const qb = this.repo.createQueryBuilder('residente');
    this.applyTenantFilter(qb, tenantId, 'residente');
    qb.leftJoinAndSelect('residente.tenencias', 'tenencia');
    qb.leftJoinAndSelect('tenencia.casa', 'casa');
    qb.leftJoinAndSelect('casa.manzana', 'manzana');
    qb.leftJoinAndSelect('manzana.etapa', 'etapa');
    qb.leftJoinAndSelect('residente.cobros', 'cobros');

    const subQuery = qb
      .subQuery()
      .select('c.id')
      .from('casas', 'c')
      .where('c.etapaId IN (:...etapaIds)')
      .getQuery();

    qb.andWhere(`tenencia.casaId IN ${subQuery}`, { etapaIds });
    qb.orderBy('residente.nombre', 'ASC');

    return qb.getMany();
  }

  async countNuevosByWeek(tenantId: string): Promise<number> {
    const unaSemanaAtras = new Date();
    unaSemanaAtras.setDate(unaSemanaAtras.getDate() - 7);
    const qb = this.repo.createQueryBuilder('residente');
    this.applyTenantFilter(qb, tenantId, 'residente');

    const result = await qb
      .select('COUNT(*)', 'count')
      .andWhere('residente.createdAt >= :fecha', { fecha: unaSemanaAtras })
      .getRawOne();
    return Number(result?.count ?? 0);
  }
}
