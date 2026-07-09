import { Injectable, NotFoundException } from '@nestjs/common';
import { Tenencia } from '../../domain/tenencia.entity';
import { PropietarioRepository } from '../../infrastructure/propietario.repository';

@Injectable()
export class AgregarTenenciaUseCase {
  constructor(
    private readonly propietarioRepository: PropietarioRepository,
  ) {}

  async execute(params: {
    propietarioId: string;
    casaId: string;
    fechaInicio: Date;
  }): Promise<Tenencia> {
    const propietario = await this.propietarioRepository.findWithTenencia(
      params.propietarioId,
    );
    if (!propietario) {
      throw new NotFoundException(
        `Propietario con ID ${params.propietarioId} no encontrado`,
      );
    }

    const tenencia = propietario.agregarTenencia(params.casaId, params.fechaInicio);
    await this.propietarioRepository.save(propietario);
    return tenencia;
  }
}
