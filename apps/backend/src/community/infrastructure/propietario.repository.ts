import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Propietario } from '../domain/propietario.entity';

interface BuscarPorFiltrosParams {
  etapaId?: string;
  casaId?: string;
  tenantId: string;
}

@Injectable()
export class PropietarioRepository {
  constructor(
    @InjectRepository(Propietario)
    private readonly repo: Repository<Propietario>,
  ) {}

  async findByTenant(tenantId: string): Promise<Propietario[]> {
    return this.repo.find({
      where: { tenantId },
      order: { nombre: 'ASC' },
    });
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
    qb.leftJoinAndSelect('propietario.tenencias', 'tenencia');
    qb.where('propietario.tenantId = :tenantId', { tenantId: params.tenantId });

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

  /**
   * Busca propietarios cuyas casas estén en una o más etapas específicas.
   * Usado por COBRADORES que solo ven propietarios de sus etapas asignadas.
   */
  async buscarPorEtapas(tenantId: string, etapaIds: string[]): Promise<Propietario[]> {
    if (!etapaIds || etapaIds.length === 0) {
      return [];
    }

    const qb = this.repo.createQueryBuilder('propietario');
    qb.leftJoinAndSelect('propietario.tenencias', 'tenencia');
    qb.where('propietario.tenantId = :tenantId', { tenantId });

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

  async save(propietario: Propietario): Promise<Propietario> {
    return this.repo.save(propietario);
  }
}
