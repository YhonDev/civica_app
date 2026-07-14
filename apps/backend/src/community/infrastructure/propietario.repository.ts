import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Propietario } from '../domain/propietario.entity';
import { BaseTenantRepository } from '../../shared/common/infrastructure/base-tenant.repository';

interface BuscarPorFiltrosParams {
  etapaId?: string;
  casaId?: string;
  tenantId: string;
}

@Injectable()
export class PropietarioRepository extends BaseTenantRepository<Propietario> {
  constructor(
    @InjectRepository(Propietario)
    protected readonly repo: Repository<Propietario>,
  ) {
    super(repo);
  }

  async findByTenant(tenantId: string): Promise<Propietario[]> {
    return super.findByTenant(tenantId, {
      order: { nombre: 'ASC' },
    });
  }

  async countByTenant(tenantId: string): Promise<number> {
    return super.countByTenant(tenantId);
  }

  async findById(id: string): Promise<Propietario | null> {
    return this.repo.findOne({ where: { id } });
  }

  /**
   * Busca propietarios con filtros opcionales por etapa (a través de tenencias y casas)
   * y/o casa (a través de tenencias). tenantId es obligatorio.
   */
  async buscarPorFiltros(params: BuscarPorFiltrosParams): Promise<Propietario[]> {
    const qb = this.repo.createQueryBuilder('propietario');
    this.applyTenantFilter(qb, params.tenantId, 'propietario');
    qb.leftJoinAndSelect('propietario.tenencias', 'tenencia');
    qb.leftJoinAndSelect('tenencia.casa', 'casa');
    qb.leftJoinAndSelect('casa.manzana', 'manzana');
    qb.leftJoinAndSelect('manzana.etapa', 'etapa');
    qb.leftJoinAndSelect('propietario.cuotas', 'cuotas');

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
      qb.andWhere(`tenencia.casaId IN ${subQuery}`, { etapaId: params.etapaId });
    }

    return qb.getMany();
  }

  async findWithTenencia(propietarioId: string): Promise<Propietario | null> {
    return this.repo.findOne({
      where: { id: propietarioId },
      relations: { tenencias: true },
    });
  }

  async findByIdWithRelations(id: string): Promise<Propietario | null> {
    return this.repo.findOne({
      where: { id },
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
   * Busca propietarios cuyas casas estén en una o más etapas específicas.
   * Usado por COBRADORES que solo ven propietarios de sus etapas asignadas.
   */
  async buscarPorEtapas(tenantId: string, etapaIds: string[]): Promise<Propietario[]> {
    if (!etapaIds || etapaIds.length === 0) {
      return [];
    }

    const qb = this.repo.createQueryBuilder('propietario');
    this.applyTenantFilter(qb, tenantId, 'propietario');
    qb.leftJoinAndSelect('propietario.tenencias', 'tenencia');
    qb.leftJoinAndSelect('tenencia.casa', 'casa');
    qb.leftJoinAndSelect('casa.manzana', 'manzana');
    qb.leftJoinAndSelect('manzana.etapa', 'etapa');
    qb.leftJoinAndSelect('propietario.cuotas', 'cuotas');

    const subQuery = qb
      .subQuery()
      .select('c.id')
      .from('casas', 'c')
      .where('c.etapaId IN (:...etapaIds)')
      .getQuery();

    qb.andWhere(`tenencia.casaId IN ${subQuery}`, { etapaIds });
    qb.orderBy('propietario.nombre', 'ASC');

    return qb.getMany();
  }

  async countNuevosByWeek(tenantId: string): Promise<number> {
    const unaSemanaAtras = new Date();
    unaSemanaAtras.setDate(unaSemanaAtras.getDate() - 7);
    const qb = this.repo.createQueryBuilder('propietario');
    this.applyTenantFilter(qb, tenantId, 'propietario');
    
    const result = await qb
      .select('COUNT(*)', 'count')
      .andWhere('propietario.createdAt >= :fecha', { fecha: unaSemanaAtras })
      .getRawOne();
    return Number(result?.count ?? 0);
  }
}
