import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, LessThanOrEqual } from 'typeorm';
import { Tarifa } from '../../domain/tarifa.entity';
import { Frecuencia } from '../../../shared/common/value-objects';

@Injectable()
export class TarifaRepository {
  constructor(
    @InjectRepository(Tarifa)
    private readonly repo: Repository<Tarifa>,
  ) {}

  async findAll(tenantId: string, conjuntoId?: string): Promise<Tarifa[]> {
    const where: any = { tenantId };
    if (conjuntoId) {
      where.conjuntoId = conjuntoId;
    }
    return this.repo.find({
      where,
      order: { fechaVigencia: 'DESC' },
    });
  }

  /**
   * Find the active tarifa whose fechaVigencia <= fecha,
   * ordered by fechaVigencia DESC, limit 1.
   */
  async findVigente(
    conjuntoId: string,
    frecuencia: Frecuencia,
    fecha: Date,
  ): Promise<Tarifa | null> {
    const dateStr = fecha.toISOString().split('T')[0];
    const result = await this.repo
      .createQueryBuilder('tarifa')
      .where('tarifa.conjuntoId = :conjuntoId', { conjuntoId })
      .andWhere('tarifa.frecuencia = :frecuencia', { frecuencia })
      .andWhere('tarifa.fechaVigencia <= :fecha', { fecha: dateStr })
      .andWhere('tarifa.activa = :activa', { activa: true })
      .orderBy('tarifa.fechaVigencia', 'DESC')
      .limit(1)
      .getOne();

    return result ?? null;
  }

  async findById(id: string): Promise<Tarifa | null> {
    return this.repo.findOne({ where: { id } });
  }

  async save(tarifa: Tarifa): Promise<Tarifa> {
    return this.repo.save(tarifa);
  }

  async countActivasByConjunto(conjuntoId: string): Promise<number> {
    return this.repo.count({
      where: { conjuntoId, activa: true },
    });
  }
}
