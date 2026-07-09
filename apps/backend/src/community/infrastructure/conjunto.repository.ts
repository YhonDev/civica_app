import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Conjunto } from '../domain/conjunto.entity';

@Injectable()
export class ConjuntoRepository {
  constructor(
    @InjectRepository(Conjunto)
    private readonly repo: Repository<Conjunto>,
  ) {}

  async findByTenant(tenantId: string): Promise<Conjunto[]> {
    return this.repo.find({
      where: { tenantId },
      relations: { etapas: { casas: true } },
      order: { nombre: 'ASC' },
    });
  }

  async findById(id: string): Promise<Conjunto | null> {
    return this.repo.findOne({
      where: { id },
      relations: { etapas: { casas: true } },
    });
  }

  async save(conjunto: Conjunto): Promise<Conjunto> {
    return this.repo.save(conjunto);
  }
}
