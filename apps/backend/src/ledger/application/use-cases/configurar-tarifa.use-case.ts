import { Injectable, BadRequestException } from '@nestjs/common';
import { Tarifa } from '../../domain/tarifa.entity';
import { TarifaDerivacionService } from '../services/tarifa-derivacion.service';
import { Frecuencia } from '../../../shared/common/value-objects';

interface ConfigurarTarifaParams {
  proyectoId: string;
  tenantId: string;
  frecuencia: Frecuencia;
  montoPesos: number;
  fechaVigencia: string;
}

@Injectable()
export class ConfigurarTarifaUseCase {
  constructor(
    private readonly tarifaDerivacionService: TarifaDerivacionService,
  ) {}

  async execute(params: ConfigurarTarifaParams): Promise<Tarifa> {
    const { proyectoId, tenantId, frecuencia, montoPesos, fechaVigencia } =
      params;

    if (montoPesos <= 0) {
      throw new BadRequestException('El monto debe ser mayor a cero');
    }

    const fechaDate = new Date(fechaVigencia);
    if (isNaN(fechaDate.getTime())) {
      throw new BadRequestException('fechaVigencia no es una fecha válida');
    }

    const montoCentavos = Math.round(montoPesos * 100);

    const creadas = await this.tarifaDerivacionService.crearVersiones(
      proyectoId,
      tenantId,
      frecuencia,
      montoCentavos,
      fechaVigencia,
    );

    const tarifaSolicitada = creadas.find((t) => t.frecuencia === frecuencia);
    if (!tarifaSolicitada) {
      throw new BadRequestException('Error al crear tarifas derivadas');
    }

    return tarifaSolicitada;
  }
}
