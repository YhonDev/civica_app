import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { Etapa } from '../../domain/etapa.entity';
import { ProyectoRepository } from '../../infrastructure/proyecto.repository';

@Injectable()
export class CrearEtapaUseCase {
  constructor(private readonly proyectoRepository: ProyectoRepository) {}

  async execute(
    nombre: string,
    proyectoId: string,
    tenantId: string,
  ): Promise<Etapa> {
    if (!nombre || nombre.trim().length < 2) {
      throw new BadRequestException(
        'El nombre debe tener al menos 2 caracteres',
      );
    }

    const proyecto = await this.proyectoRepository.findById(
      proyectoId,
      tenantId,
    );
    if (!proyecto) {
      throw new NotFoundException(
        `Proyecto con ID ${proyectoId} no encontrado`,
      );
    }

    const etapa = proyecto.agregarEtapa(nombre);
    await this.proyectoRepository.save(proyecto);
    return etapa;
  }
}
