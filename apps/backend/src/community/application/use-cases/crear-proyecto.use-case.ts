import { Injectable } from '@nestjs/common';
import { Proyecto } from '../../domain/proyecto.entity';
import { ProyectoRepository } from '../../infrastructure/proyecto.repository';

@Injectable()
export class CrearProyectoUseCase {
  constructor(private readonly proyectoRepository: ProyectoRepository) {}

  async execute(nombre: string, tenantId: string): Promise<Proyecto> {
    const proyecto = Proyecto.crear(nombre, tenantId);
    return this.proyectoRepository.save(proyecto);
  }
}
