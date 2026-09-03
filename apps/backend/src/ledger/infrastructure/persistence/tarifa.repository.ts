import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, LessThanOrEqual } from 'typeorm';
import { Tarifa } from '../../domain/tarifa.entity';
import { ModalidadRecaudo } from '../../../shared/common/value-objects';

@Injectable()
export class TarifaRepository {
  constructor(
    @InjectRepository(Tarifa)
    private readonly repo: Repository<Tarifa>,
  ) {}

  async findAll(tenantId: string, proyectoId?: string): Promise<Tarifa[]> {
    const where: any = { tenantId };
    if (proyectoId) {
      where.proyectoId = proyectoId;
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
    proyectoId: string,
    modalidad: ModalidadRecaudo,
    fecha: Date,
  ): Promise<Tarifa | null> {
    const dateStr = fecha.toISOString().split('T')[0];
    const result = await this.repo
      .createQueryBuilder('tarifa')
      .where('tarifa.proyectoId = :proyectoId', { proyectoId })
      .andWhere('tarifa.modalidad = :modalidad', { modalidad })
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

  /**
   * Tarifas vigentes hoy para las 3 modalidades de un conjunto.
   * Siempre consultar BD — el admin puede editar los montos.
   */
  async findVigentesPorConjunto(
    proyectoId: string,
    fecha = new Date(),
  ): Promise<Record<ModalidadRecaudo, Tarifa | null>> {
    const modalidades: ModalidadRecaudo[] = ['SEMANAL', 'QUINCENAL', 'MENSUAL'];
    const result = {} as Record<ModalidadRecaudo, Tarifa | null>;

    await Promise.all(
      modalidades.map(async (modalidad) => {
        result[modalidad] = await this.findVigente(
          proyectoId,
          modalidad,
          fecha,
        );
      }),
    );

    return result;
  }

  async save(tarifa: Tarifa): Promise<Tarifa> {
    return this.repo.save(tarifa);
  }

  async countActivasByConjunto(proyectoId: string): Promise<number> {
    return this.repo.count({
      where: { proyectoId, activa: true },
    });
  }
}
