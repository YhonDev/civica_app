import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { MontoPagoPredefinido } from '../../domain/monto-pago-predefinido.entity';

@Injectable()
export class MontoPagoPredefinidoRepository {
  constructor(
    @InjectRepository(MontoPagoPredefinido)
    private readonly repo: Repository<MontoPagoPredefinido>,
  ) {}

  async findAllByConjunto(conjuntoId: string): Promise<MontoPagoPredefinido[]> {
    return this.repo.find({
      where: { conjuntoId, activo: true },
      order: { orden: 'ASC' },
    });
  }

  async findById(id: string): Promise<MontoPagoPredefinido | null> {
    return this.repo.findOne({ where: { id } });
  }

  async save(monto: MontoPagoPredefinido): Promise<MontoPagoPredefinido> {
    return this.repo.save(monto);
  }

  async countActivosByConjunto(conjuntoId: string): Promise<number> {
    return this.repo.count({
      where: { conjuntoId, activo: true },
    });
  }

  /** Soft delete: set activo = false */
  async remove(id: string): Promise<void> {
    await this.repo.update(id, { activo: false });
  }
}
