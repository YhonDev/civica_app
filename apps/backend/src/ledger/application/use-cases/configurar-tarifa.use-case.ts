import { Injectable, BadRequestException } from '@nestjs/common';
import { Tarifa } from '../../domain/tarifa.entity';
import { TarifaRepository } from '../../infrastructure/persistence/tarifa.repository';
import { Frecuencia, Money } from '../../../shared/common/value-objects';

interface ConfigurarTarifaParams {
  conjuntoId: string;
  tenantId: string;
  frecuencia: Frecuencia;
  montoPesos: number; // in COP pesos, will convert to centavos
  fechaVigencia: string; // ISO date string YYYY-MM-DD
}

@Injectable()
export class ConfigurarTarifaUseCase {
  constructor(private readonly tarifaRepository: TarifaRepository) {}

  async execute(params: ConfigurarTarifaParams): Promise<Tarifa> {
    const { conjuntoId, tenantId, frecuencia, montoPesos, fechaVigencia } =
      params;

    if (montoPesos <= 0) {
      throw new BadRequestException('El monto debe ser mayor a cero');
    }

    // Validate fechaVigencia format
    const fechaDate = new Date(fechaVigencia);
    if (isNaN(fechaDate.getTime())) {
      throw new BadRequestException('fechaVigencia no es una fecha válida');
    }

    // Convert pesos to centavos
    const montoCentavos = Math.round(montoPesos * 100);
    const monto = Money.ofCOP(montoCentavos);

    // Deactivate any existing active future tarifa for the same conjunto+frecuencia
    // (only one active future tarifa per combo is allowed)
    const existingTarifas = await this.tarifaRepository.findAll(tenantId, conjuntoId);
    const activeFutureTarifa = existingTarifas.find(
      (t) =>
        t.activa &&
        t.frecuencia === frecuencia &&
        t.fechaVigencia >= fechaVigencia,
    );

    if (activeFutureTarifa) {
      activeFutureTarifa.desactivar();
      await this.tarifaRepository.save(activeFutureTarifa);
    }

    // Create new tarifa via domain entity
    const tarifa = Tarifa.crear(conjuntoId, tenantId, frecuencia, monto, fechaVigencia);
    return this.tarifaRepository.save(tarifa);
  }
}
