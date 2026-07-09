import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Etapa } from '../../domain/etapa.entity';
import { Casa } from '../../domain/casa.entity';

@Injectable()
export class RegistrarCasaUseCase {
  constructor(
    @InjectRepository(Etapa)
    private readonly etapaRepository: Repository<Etapa>,
    @InjectRepository(Casa)
    private readonly casaRepository: Repository<Casa>,
  ) {}

  async execute(direccionInterna: string, etapaId: string): Promise<Casa> {
    if (!direccionInterna || direccionInterna.trim().length === 0) {
      throw new BadRequestException('La dirección interna no puede estar vacía');
    }

    const etapa = await this.etapaRepository.findOne({
      where: { id: etapaId },
      relations: { casas: true },
    });
    if (!etapa) {
      throw new NotFoundException(`Etapa con ID ${etapaId} no encontrada`);
    }

    const casa = etapa.crearCasa(direccionInterna);
    await this.casaRepository.save(casa);
    return casa;
  }
}
