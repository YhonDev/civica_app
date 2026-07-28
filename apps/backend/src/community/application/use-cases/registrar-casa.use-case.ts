import { Injectable, NotFoundException, BadRequestException, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Manzana } from '../../domain/manzana.entity';
import { Casa } from '../../domain/casa.entity';

@Injectable()
export class RegistrarCasaUseCase {
  private readonly logger = new Logger(RegistrarCasaUseCase.name);

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
    });
    if (!manzana) {
      throw new NotFoundException(`Manzana con ID ${manzanaId} no encontrada`);
    }

    try {
      const casa = Casa.crear(direccionInterna, manzana);
      await this.casaRepository.insert(casa);
      this.logger.log(`Casa creada: ${casa.id} - ${direccionInterna}`);
      return casa;
    } catch (error) {
      this.logger.error(`Error al crear casa: ${(error as Error).message}`, (error as Error).stack);
      throw error;
    }
  }
}
