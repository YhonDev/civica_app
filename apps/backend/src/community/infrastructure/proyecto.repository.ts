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

  async findById(id: string, tenantId: string): Promise<Proyecto | null> {
    return this.repo.findOne({
      where: { id, tenantId },
      relations: { etapas: { manzanas: { casas: true } } },
    });
  }

  async findByIdPlano(id: string, tenantId: string): Promise<Proyecto | null> {
    return this.repo.findOne({ where: { id, tenantId } });
  }

  async save(proyecto: Proyecto): Promise<Proyecto> {
    return this.repo.save(proyecto);
  }

  /**
   * Verifica si un proyecto está en modo mantenimiento.
   * Retorna true si el proyecto no existe (fail-closed: bloquea si no se puede determinar).
   */
  async estaEnMantenimiento(id: string, tenantId: string): Promise<boolean> {
    const proyecto = await this.repo.findOne({
      where: { id, tenantId },
      select: { modoMantenimiento: true },
    });
    return proyecto?.modoMantenimiento ?? true;
  }
}
