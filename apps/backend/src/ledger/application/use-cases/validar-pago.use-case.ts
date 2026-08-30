import { Injectable, BadRequestException, NotFoundException, Logger } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { Pago, EstadoValidacionPago } from '../../domain/pago.entity';
import { PagoRepository } from '../../infrastructure/persistence/pago.repository';
import { PagoCobroRepository } from '../../infrastructure/persistence/pago-cobro.repository';
import { revertirAbonos } from './revertir-abonos';

export interface ValidarPagoInput {
  pagoId: string;
  estado: EstadoValidacionPago.VALIDADO | EstadoValidacionPago.RECHAZADO;
  tenantId: string;
}

@Injectable()
export class ValidarPagoUseCase {
  private readonly logger = new Logger(ValidarPagoUseCase.name);

  constructor(
    private readonly dataSource: DataSource,
    private readonly pagoRepo: PagoRepository,
    private readonly pagoCobroRepo: PagoCobroRepository,
  ) {}

  async execute(input: ValidarPagoInput): Promise<Pago> {
    const pago = await this.pagoRepo.findById(input.pagoId);

    if (!pago || pago.tenantId !== input.tenantId) {
      throw new NotFoundException(`Pago ${input.pagoId} no encontrado`);
    }

    if (pago.estado !== EstadoValidacionPago.PENDIENTE_REVISION) {
      throw new BadRequestException(
        `No se puede validar/rechazar un pago en estado ${pago.estado}. Solo se permiten cambios en PENDIENTE_REVISION.`,
      );
    }

    if (
      input.estado !== EstadoValidacionPago.VALIDADO &&
      input.estado !== EstadoValidacionPago.RECHAZADO
    ) {
      throw new BadRequestException('El nuevo estado debe ser VALIDADO o RECHAZADO.');
    }

    await this.dataSource.transaction(async (entityManager) => {
      if (input.estado === EstadoValidacionPago.RECHAZADO) {
        // Revertir EXACTAMENTE los cobros que el pago afectó (vía pago_cobros),
        // con fallback LIFO para pagos legacy sin vínculos.
        await revertirAbonos(entityManager, pago, this.pagoCobroRepo);

        pago.cobroId = null;
      }

      pago.estado = input.estado;
      await entityManager.save(pago);
    });

    this.logger.log(`Pago ${pago.id} validado con estado: ${input.estado}`);

    return pago;
  }
}
