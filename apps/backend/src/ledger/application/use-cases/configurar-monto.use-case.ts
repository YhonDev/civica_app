import { Injectable, BadRequestException } from '@nestjs/common';
import { MontoPagoPredefinido } from '../../domain/monto-pago-predefinido.entity';
import { MontoPagoPredefinidoRepository } from '../../infrastructure/persistence/monto-pago-predefinido.repository';
import { Money } from '../../../shared/common/value-objects';

interface ConfigurarMontoParams {
  tenantId: string;
  proyectoId: string;
  montoPesos: number;
  descripcion: string;
}

@Injectable()
export class ConfigurarMontoUseCase {
  constructor(
    private readonly montoRepository: MontoPagoPredefinidoRepository,
  ) {}

  async execute(params: ConfigurarMontoParams): Promise<MontoPagoPredefinido> {
    const { tenantId, proyectoId, montoPesos, descripcion } = params;

    if (montoPesos <= 0) {
      throw new BadRequestException('El monto debe ser mayor a cero');
    }

    if (!descripcion || descripcion.trim().length < 2) {
      throw new BadRequestException(
        'La descripción debe tener al menos 2 caracteres',
      );
    }

    // Validate max 5 active montos per conjunto
    const countActivos =
      await this.montoRepository.countActivosByConjunto(proyectoId);
    if (countActivos >= 5) {
      throw new BadRequestException(
        'Máximo 5 montos predefinidos activos por conjunto',
      );
    }

    // Auto-assign orden: next number
    const existingMontos = await this.montoRepository.findAllByConjunto(
      proyectoId,
      tenantId,
    );
    const nextOrden =
      existingMontos.length > 0
        ? Math.max(...existingMontos.map((m) => m.orden)) + 1
        : 1;

    const montoCentavos = Math.round(montoPesos * 100);
    const monto = Money.ofCOP(montoCentavos);

    const montoPredefinido = MontoPagoPredefinido.crear(
      tenantId,
      proyectoId,
      monto,
      descripcion,
      nextOrden,
    );

    return this.montoRepository.save(montoPredefinido);
  }
}
