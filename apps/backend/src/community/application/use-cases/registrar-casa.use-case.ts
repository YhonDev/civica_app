import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Manzana } from '../../domain/manzana.entity';
import { Casa } from '../../domain/casa.entity';

@Injectable()
export class RegistrarCasaUseCase {
  constructor(
    @InjectRepository(Manzana)
    private readonly manzanaRepository: Repository<Manzana>,
    @InjectRepository(Casa)
    private readonly casaRepository: Repository<Casa>,
  ) {}

  async execute(direccionInterna: string, manzanaId: string): Promise<Casa> {
    if (!direccionInterna || direccionInterna.trim().length === 0) {
      throw new BadRequestException('La dirección interna no puede estar vacía');
    }

    const manzana = await this.manzanaRepository.findOne({
      where: { id: manzanaId },
      relations: { casas: true },
    });
    if (!manzana) {
      throw new NotFoundException(`Manzana con ID ${manzanaId} no encontrada`);
    }

    const casa = manzana.crearCasa(direccionInterna);
    await this.casaRepository.save(casa);
    return casa;
  }
}
