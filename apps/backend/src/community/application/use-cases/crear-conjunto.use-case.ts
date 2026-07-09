import { Injectable, BadRequestException } from '@nestjs/common';
import { Conjunto } from '../../domain/conjunto.entity';
import { ConjuntoRepository } from '../../infrastructure/conjunto.repository';

@Injectable()
export class CrearConjuntoUseCase {
  constructor(private readonly conjuntoRepository: ConjuntoRepository) {}

  async execute(nombre: string, tenantId: string): Promise<Conjunto> {
    if (!nombre || nombre.trim().length < 2) {
      throw new BadRequestException('El nombre debe tener al menos 2 caracteres');
    }

    const conjunto = Conjunto.crear(nombre, tenantId);
    return this.conjuntoRepository.save(conjunto);
  }
}
