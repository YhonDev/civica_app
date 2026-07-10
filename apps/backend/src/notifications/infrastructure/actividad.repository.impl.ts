import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Actividad } from '../domain/actividad.entity';
import { ActividadRepository } from '../domain/actividad.repository';

@Injectable()
export class ActividadRepositoryImpl extends ActividadRepository {
  constructor(
    @InjectRepository(Actividad)
    private readonly repo: Repository<Actividad>,
  ) {
    super();
  }

  async save(actividad: Actividad): Promise<Actividad> {
    return this.repo.save(actividad);
  }

  async findByTenant(tenantId: string, limit: number): Promise<Actividad[]> {
    return this.repo.find({
      where: { tenantId },
      order: { createdAt: 'DESC' },
      take: limit,
    });
  }
}
