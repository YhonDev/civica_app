import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { Etapa } from '../../domain/etapa.entity';
import { ConjuntoRepository } from '../../infrastructure/conjunto.repository';

@Injectable()
export class CrearEtapaUseCase {
  constructor(private readonly conjuntoRepository: ConjuntoRepository) {}

  async execute(nombre: string, conjuntoId: string): Promise<Etapa> {
    if (!nombre || nombre.trim().length < 2) {
      throw new BadRequestException('El nombre debe tener al menos 2 caracteres');
    }

    const conjunto = await this.conjuntoRepository.findById(conjuntoId);
    if (!conjunto) {
      throw new NotFoundException(`Conjunto con ID ${conjuntoId} no encontrado`);
    }

    const etapa = conjunto.agregarEtapa(nombre);
    await this.conjuntoRepository.save(conjunto);
    return etapa;
  }
}
