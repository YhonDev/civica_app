import { Injectable, NotFoundException } from '@nestjs/common';
import { Residente } from '../../domain/residente.entity';
import { ResidenteRepository } from '../../infrastructure/residente.repository';
import { type Frecuencia } from '../../../shared/common/value-objects';

interface ActualizarResidenteParams {
  id: string;
  tenantId: string;
  nombre?: string;
  telefono?: string;
  email?: string | null;
  casaId?: string;
  modalidadPago?: Frecuencia;
}

@Injectable()
export class ActualizarResidenteUseCase {
  constructor(private readonly residenteRepository: ResidenteRepository) {}

  async execute(params: ActualizarResidenteParams): Promise<void> {
    const residente = await this.residenteRepository.findById(params.id);

    if (!residente) {
      throw new NotFoundException('Residente no encontrado');
    }

    if (params.nombre !== undefined) residente.nombre = params.nombre;
    if (params.telefono !== undefined) residente.telefono = params.telefono;
    if (params.email !== undefined) residente.email = params.email;
    if (params.modalidadPago !== undefined) {
      residente.modalidadPago = params.modalidadPago;
    }
    if (params.casaId !== undefined) {
      residente.asignarCasa(params.casaId);
    }

    await this.residenteRepository.save(residente);
  }
}
