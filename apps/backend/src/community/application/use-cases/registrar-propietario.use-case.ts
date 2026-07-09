import { Injectable, BadRequestException } from '@nestjs/common';
import { Propietario } from '../../domain/propietario.entity';
import { PropietarioRepository } from '../../infrastructure/propietario.repository';

@Injectable()
export class RegistrarPropietarioUseCase {
  constructor(
    private readonly propietarioRepository: PropietarioRepository,
  ) {}

  async execute(params: {
    nombre: string;
    telefono: string;
    email: string | null;
    tenantId: string;
    casaId?: string;
    fechaInicio?: Date;
  }): Promise<Propietario> {
    if (!params.nombre || params.nombre.trim().length < 2) {
      throw new BadRequestException('El nombre debe tener al menos 2 caracteres');
    }

    const propietario = Propietario.crear(
      params.nombre,
      params.telefono,
      params.email ?? null,
      params.tenantId,
    );

    // Si se proporciona casaId, crear también la tenencia inicial
    if (params.casaId) {
      const fechaInicio = params.fechaInicio ?? new Date();
      propietario.agregarTenencia(params.casaId, fechaInicio);
    }

    return this.propietarioRepository.save(propietario);
  }
}
