import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Proyecto } from '../domain/proyecto.entity';

@Injectable()
export class ProyectoRepository {
  constructor(
    @InjectRepository(Proyecto)
    private readonly repo: Repository<Proyecto>,
  ) {}

  async findByTenant(tenantId: string): Promise<Proyecto[]> {
    return this.repo.find({
      where: { tenantId },
      relations: { etapas: { manzanas: { casas: true } } },
      order: { nombre: 'ASC' },
    });
  }

  async findById(id: string): Promise<Proyecto | null> {
    return this.repo.findOne({
      where: { id },
      relations: { etapas: { manzanas: { casas: true } } },
    });
  }

  async save(proyecto: Proyecto): Promise<Proyecto> {
    return this.repo.save(proyecto);
  }
}
