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

  async findAllByConjunto(
    proyectoId: string,
    tenantId: string,
  ): Promise<MontoPagoPredefinido[]> {
    return this.repo.find({
      where: { proyectoId, tenantId, activo: true },
      order: { orden: 'ASC' },
    });
  }

  async findById(
    id: string,
    tenantId: string,
  ): Promise<MontoPagoPredefinido | null> {
    return this.repo.findOne({ where: { id, tenantId } });
  }

  async save(monto: MontoPagoPredefinido): Promise<MontoPagoPredefinido> {
    return this.repo.save(monto);
  }

  async countActivosByConjunto(proyectoId: string): Promise<number> {
    return this.repo.count({
      where: { proyectoId, activo: true },
    });
  }

  /** Soft delete: set activo = false */
  async remove(id: string): Promise<void> {
    await this.repo.update(id, { activo: false });
  }
}
