import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Etapa } from '../../domain/etapa.entity';
import { Manzana } from '../../domain/manzana.entity';

@Injectable()
export class CrearManzanaUseCase {
  constructor(
    @InjectRepository(Etapa)
    private readonly etapaRepository: Repository<Etapa>,
    @InjectRepository(Manzana)
    private readonly manzanaRepository: Repository<Manzana>,
  ) {}

  async execute(
    nombre: string,
    etapaId: string,
    tenantId: string,
  ): Promise<Manzana> {
    if (!nombre || nombre.trim().length === 0) {
      throw new BadRequestException(
        'El nombre de la manzana no puede estar vacío',
      );
    }

    const etapa = await this.etapaRepository.findOne({
      where: { id: etapaId },
      relations: { proyecto: true },
    });
    if (!etapa || etapa.proyecto?.tenantId !== tenantId) {
      throw new NotFoundException(`Etapa con ID ${etapaId} no encontrada`);
    }

    const manzana = Manzana.crear(nombre, etapa);
    await this.manzanaRepository.save(manzana);
    return manzana;
  }
}
