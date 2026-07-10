import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Pago } from '../../domain/pago.entity';

@Injectable()
export class PagoRepository {
  constructor(
    @InjectRepository(Pago)
    private readonly repo: Repository<Pago>,
  ) {}

  async findById(id: string): Promise<Pago | null> {
    return this.repo.findOne({ where: { id } });
  }

  async findByIdempotentKey(
    tenantId: string,
    clientPaymentId: string,
  ): Promise<Pago | null> {
    return this.repo.findOne({ where: { tenantId, clientPaymentId } });
  }

  async findByPropietario(propietarioId: string): Promise<Pago[]> {
    return this.repo.find({
      where: { propietarioId },
      order: { createdAt: 'DESC' },
    });
  }

  async findByCuota(cuotaId: string): Promise<Pago[]> {
    return this.repo.find({
      where: { cuotaId },
      order: { createdAt: 'DESC' },
    });
  }

  async save(pago: Pago): Promise<Pago> {
    return this.repo.save(pago);
  }

  async saveMany(pagos: Pago[]): Promise<Pago[]> {
    return this.repo.save(pagos);
  }
}
