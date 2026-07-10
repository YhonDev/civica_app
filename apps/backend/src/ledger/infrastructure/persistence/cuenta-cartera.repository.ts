import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CuentaDeCartera } from '../../domain/cuenta-de-cartera.entity';

@Injectable()
export class CuentaCarteraRepository {
  constructor(
    @InjectRepository(CuentaDeCartera)
    private readonly repo: Repository<CuentaDeCartera>,
  ) {}

  async findByPropietario(propietarioId: string): Promise<CuentaDeCartera | null> {
    return this.repo.findOne({ where: { propietarioId } });
  }

  async findById(id: string): Promise<CuentaDeCartera | null> {
    return this.repo.findOne({ where: { id } });
  }

  async findAllByTenant(tenantId: string): Promise<CuentaDeCartera[]> {
    return this.repo.find({
      where: { tenantId },
      order: { fechaActivacion: 'DESC' },
    });
  }

  /** All active accounts in a conjunto (for generating cuotas) */
  async findByConjunto(conjuntoId: string): Promise<CuentaDeCartera[]> {
    return this.repo.find({
      where: { conjuntoId, activa: true },
    });
  }

  async save(cuenta: CuentaDeCartera): Promise<CuentaDeCartera> {
    return this.repo.save(cuenta);
  }
}
