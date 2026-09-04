import {
  Injectable,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { Tarifa } from '../../domain/tarifa.entity';
import { TarifaRepository } from '../../infrastructure/persistence/tarifa.repository';
import { TarifaDerivacionService } from '../services/tarifa-derivacion.service';

interface ActualizarTarifaParams {
  tarifaId: string;
  montoPesos?: number;
  fechaVigencia?: string;
  tenantId: string;
}

@Injectable()
export class ActualizarTarifaUseCase {
  constructor(
    private readonly tarifaRepository: TarifaRepository,
    private readonly tarifaDerivacionService: TarifaDerivacionService,
  ) {}

  async execute(params: ActualizarTarifaParams): Promise<Tarifa> {
    const { tarifaId, montoPesos, fechaVigencia, tenantId } = params;

    const tarifa = await this.tarifaRepository.findById(tarifaId, tenantId);
    if (!tarifa) {
      throw new NotFoundException('Tarifa no encontrada');
    }

    if (fechaVigencia !== undefined) {
      const fechaDate = new Date(fechaVigencia);
      if (isNaN(fechaDate.getTime())) {
        throw new BadRequestException('fechaVigencia no es una fecha válida');
      }
      tarifa.fechaVigencia = fechaVigencia;
    }

    if (montoPesos !== undefined) {
      if (montoPesos <= 0) {
        throw new BadRequestException('El monto debe ser mayor a cero');
      }

      const montoCentavos = Math.round(montoPesos * 100);
      const actualizadas = await this.tarifaDerivacionService.actualizarActivas(
        tarifa.proyectoId,
        tarifa.tenantId,
        tarifa.modalidad,
        montoCentavos,
      );

      const actualizada = actualizadas.find(
        (t) => t.modalidad === tarifa.modalidad,
      );
      if (!actualizada) {
        throw new BadRequestException(
          'No se encontraron tarifas activas para actualizar',
        );
      }

      if (fechaVigencia !== undefined) {
        actualizada.fechaVigencia = fechaVigencia;
        return this.tarifaRepository.save(actualizada);
      }

      return actualizada;
    }

    return this.tarifaRepository.save(tarifa);
  }
}
