import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, LessThan } from 'typeorm';
import { Cuota } from '../../domain/cuota.entity';

@Injectable()
export class CuotaRepository {
  constructor(
    @InjectRepository(Cuota)
    private readonly repo: Repository<Cuota>,
  ) {}

  async findByPropietario(
    propietarioId: string,
    estado?: string,
  ): Promise<Cuota[]> {
    const where: any = { propietarioId };
    if (estado) {
      where.estado = estado;
    }
    return this.repo.find({
      where,
      order: { periodoInicio: 'DESC' },
    });
  }

  /** Cuotas in PENDIENTE or VENCIDA state */
  async findPendientesYVencidas(propietarioId: string): Promise<Cuota[]> {
    return this.repo.find({
      where: [
        { propietarioId, estado: 'PENDIENTE' },
        { propietarioId, estado: 'VENCIDA' },
      ],
      order: { periodoInicio: 'ASC' },
    });
  }

  /**
   * Find all cuotas where estado is PENDIENTE or PARCIAL
   * and fechaVencimiento < fechaHoy (for the cron job).
   */
  async findVencidas(fechaHoy: string): Promise<Cuota[]> {
    return this.repo
      .createQueryBuilder('cuota')
      .where('cuota.estado IN (:...estados)', {
        estados: ['PENDIENTE', 'PARCIAL'],
      })
      .andWhere('cuota.fechaVencimiento < :fechaHoy', { fechaHoy })
      .getMany();
  }

  /** Oldest cuota with saldo > 0 (for FIFO payment application) */
  async findMasAntiguaConSaldo(propietarioId: string): Promise<Cuota | null> {
    return this.repo
      .createQueryBuilder('cuota')
      .where('cuota.propietarioId = :propietarioId', { propietarioId })
      .andWhere('cuota.monto > cuota.montoPagado')
      .orderBy('cuota.periodoInicio', 'ASC')
      .limit(1)
      .getOne();
  }

  /** Latest cuota generated for a propietario (for period calculation) */
  async findUltimaPorPropietario(
    propietarioId: string,
  ): Promise<Cuota | null> {
    return this.repo
      .createQueryBuilder('cuota')
      .where('cuota.propietarioId = :propietarioId', { propietarioId })
      .orderBy('cuota.periodoFin', 'DESC')
      .limit(1)
      .getOne();
  }

  async save(cuota: Cuota): Promise<Cuota> {
    return this.repo.save(cuota);
  }

  async saveMany(cuotas: Cuota[]): Promise<Cuota[]> {
    return this.repo.save(cuotas);
  }
}
