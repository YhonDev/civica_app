import { Injectable, NotFoundException } from '@nestjs/common';
import { PropietarioRepository } from '../../infrastructure/propietario.repository';

@Injectable()
export class EliminarPropietarioUseCase {
  constructor(private readonly propietarioRepository: PropietarioRepository) {}

  async execute(id: string, tenantId: string): Promise<void> {
    const propietario = await this.propietarioRepository.findById(id);
    
    if (!propietario || propietario.tenantId !== tenantId) {
      throw new NotFoundException('Propietario no encontrado');
    }

    await this.propietarioRepository.delete(id);
  }
}
