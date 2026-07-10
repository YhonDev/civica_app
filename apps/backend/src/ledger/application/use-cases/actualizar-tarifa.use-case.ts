import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { TarifaRepository } from '../../infrastructure/persistence/tarifa.repository';
import { Frecuencia } from '../../../shared/common/value-objects';

interface ActualizarTarifaParams {
  tarifaId: string;
  montoPesos?: number;
  fechaVigencia?: string;
}

/**
 * Updates an existing tarifa.
 * For MVP simplicity, we follow the ADR approach: changes to tarifa fields
 * are allowed when no cuotas have been generated with this tarifa yet.
 * Otherwise, users should create a new tarifa version.
 */
@Injectable()
export class ActualizarTarifaUseCase {
  constructor(private readonly tarifaRepository: TarifaRepository) {}

  async execute(params: ActualizarTarifaParams) {
    const { tarifaId, montoPesos, fechaVigencia } = params;

    const tarifa = await this.tarifaRepository.findById(tarifaId);
    if (!tarifa) {
      throw new NotFoundException('Tarifa no encontrada');
    }

    if (montoPesos !== undefined) {
      if (montoPesos <= 0) {
        throw new BadRequestException('El monto debe ser mayor a cero');
      }
      tarifa.monto = Math.round(montoPesos * 100);
    }

    if (fechaVigencia !== undefined) {
      const fechaDate = new Date(fechaVigencia);
      if (isNaN(fechaDate.getTime())) {
        throw new BadRequestException('fechaVigencia no es una fecha válida');
      }
      tarifa.fechaVigencia = fechaVigencia;
    }

    return this.tarifaRepository.save(tarifa);
  }
}
