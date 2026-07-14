import { Injectable, ConflictException } from '@nestjs/common';
import { Residente } from '../../domain/residente.entity';
import { ResidenteRepository } from '../../infrastructure/residente.repository';
import { type ModalidadRecaudo } from '../../../shared/common/value-objects';

interface RegistrarResidenteParams {
  nombre: string;
  telefono: string;
  email: string | null;
  tenantId: string;
  casaId?: string;
  fechaInicio?: Date;
  modalidadPago?: ModalidadRecaudo;
}

@Injectable()
export class RegistrarResidenteUseCase {
  constructor(private readonly residenteRepository: ResidenteRepository) {}

  async execute(params: RegistrarResidenteParams): Promise<Residente> {
    const residente = Residente.crear(
      params.nombre,
      params.telefono,
      params.email,
      params.tenantId,
      params.modalidadPago,
    );

    const saved = await this.residenteRepository.save(residente);

    // Si se proporcionó una casa, crear tenencia
    if (params.casaId) {
      const fechaInicio = params.fechaInicio ?? new Date();
      const tenencia = saved.agregarTenencia(params.casaId, fechaInicio);
      await this.residenteRepository.save(saved);
    }

    return saved;
  }
}
