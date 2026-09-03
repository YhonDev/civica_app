import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { CobroRepository } from '../../infrastructure/persistence/cobro.repository';
import { PagoRepository } from '../../infrastructure/persistence/pago.repository';

@Injectable()
export class EliminarCobroUseCase {
  constructor(
    private readonly cobroRepository: CobroRepository,
    private readonly pagoRepository: PagoRepository,
  ) {}

  async execute(id: string): Promise<void> {
    const cobro = await this.cobroRepository.findById(id);
    if (!cobro) {
      throw new NotFoundException('Cobro no encontrado');
    }

    const pagosCount = await this.pagoRepository.countByCobro(id);
    if (pagosCount > 0) {
      throw new BadRequestException(
        'No se puede eliminar un cobro que tiene pagos registrados',
      );
    }

    await this.cobroRepository.delete(id);
  }
}
