import { Injectable, NotFoundException } from '@nestjs/common';
import { CobroRepository } from '../../infrastructure/persistence/cobro.repository';

@Injectable()
export class EliminarCobroUseCase {
  constructor(private readonly cobroRepository: CobroRepository) {}

  async execute(id: string): Promise<void> {
    const cobro = await this.cobroRepository.findById(id);
    if (!cobro) {
      throw new NotFoundException('Cobro no encontrado');
    }

    // TODO: Validar que el cobro no tenga pagos asociados
    await this.cobroRepository.delete(id);
  }
}
