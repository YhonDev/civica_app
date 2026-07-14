import { Injectable, NotFoundException } from '@nestjs/common';
import { Tenencia } from '../../domain/tenencia.entity';
import { ResidenteRepository } from '../../infrastructure/residente.repository';

@Injectable()
export class AgregarTenenciaUseCase {
  constructor(
    private readonly residenteRepository: ResidenteRepository,
  ) {}

  async execute(params: {
    residenteId: string;
    casaId: string;
    fechaInicio: Date;
  }): Promise<Tenencia> {
    const residente = await this.residenteRepository.findWithTenencia(
      params.residenteId,
    );
    if (!residente) {
      throw new NotFoundException(
        `Residente con ID ${params.residenteId} no encontrado`,
      );
    }

    const tenencia = residente.agregarTenencia(params.casaId, params.fechaInicio);
    await this.residenteRepository.save(residente);
    return tenencia;
  }
}
