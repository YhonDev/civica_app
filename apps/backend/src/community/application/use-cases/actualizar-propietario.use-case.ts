import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PropietarioRepository } from '../../infrastructure/propietario.repository';
import { Tenencia } from '../../domain/tenencia.entity';

@Injectable()
export class ActualizarPropietarioUseCase {
  constructor(private readonly propietarioRepository: PropietarioRepository) {}

  async execute(params: {
    id: string;
    tenantId: string;
    nombre?: string;
    telefono?: string;
    email?: string | null;
    casaId?: string;
    modalidadPago?: string;
  }): Promise<void> {
    const propietario = await this.propietarioRepository.findWithTenencia(params.id);
    
    if (!propietario || propietario.tenantId !== params.tenantId) {
      throw new NotFoundException('Propietario no encontrado');
    }

    if (params.nombre && params.nombre.trim().length < 2) {
      throw new BadRequestException('El nombre debe tener al menos 2 caracteres');
    }

    if (params.nombre) propietario.nombre = params.nombre;
    if (params.telefono) propietario.telefono = params.telefono;
    if (params.email !== undefined) propietario.email = params.email;
    if (params.modalidadPago) propietario.modalidadPago = params.modalidadPago as any;

    // Manejar el cambio de casa si se provee
    if (params.casaId) {
      const tenenciaActiva = propietario.tenencias.find((t) => t.fechaFin === null);
      if (!tenenciaActiva || tenenciaActiva.casaId !== params.casaId) {
        // Finalizar la actual si existe
        if (tenenciaActiva) {
          tenenciaActiva.finalizar(new Date());
        }
        // Crear la nueva
        const nuevaTenencia = Tenencia.crear(propietario.id, params.casaId, new Date());
        nuevaTenencia.propietario = propietario;
        propietario.tenencias.push(nuevaTenencia);
      }
    }

    await this.propietarioRepository.save(propietario);
  }
}
