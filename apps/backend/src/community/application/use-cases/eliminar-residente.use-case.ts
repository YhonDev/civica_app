import { Injectable, NotFoundException } from '@nestjs/common';
import { ResidenteRepository } from '../../infrastructure/residente.repository';

@Injectable()
export class EliminarResidenteUseCase {
  constructor(private readonly residenteRepository: ResidenteRepository) {}

  async execute(id: string, tenantId: string): Promise<void> {
    const residente = await this.residenteRepository.findById(id);

    if (!residente) {
      throw new NotFoundException('Residente no encontrado');
    }

    if (residente.tenantId !== tenantId) {
      throw new NotFoundException('Residente no encontrado');
    }

    await this.residenteRepository.delete(id);
  }
}
