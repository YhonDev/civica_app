import { Injectable, BadRequestException, NotFoundException, Logger } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { Pago, EstadoValidacionPago } from '../../domain/pago.entity';
import { PagoRepository } from '../../infrastructure/persistence/pago.repository';
import { CobroRepository } from '../../infrastructure/persistence/cobro.repository';

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
    private readonly cobroRepo: CobroRepository,
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
        // Revertir el abono de los cobros vinculados (LIFO inverso)
        let remainingToReverse = pago.monto;
        const cobros = await this.cobroRepo.findByResidente(pago.residenteId);

        // Sort: newest first
        cobros.sort(
          (a, b) => new Date(b.periodoInicio).getTime() - new Date(a.periodoInicio).getTime(),
        );

        for (const cobro of cobros) {
          if (remainingToReverse <= 0) break;

          if (cobro.montoPagado > 0) {
            const amountToSubtract = Math.min(cobro.montoPagado, remainingToReverse);
            cobro.montoPagado -= amountToSubtract;
            remainingToReverse -= amountToSubtract;

            // Recalcular estado del cobro
            if (cobro.montoPagado === 0) {
              if (new Date(cobro.fechaVencimiento).getTime() < new Date().getTime()) {
                cobro.estado = 'VENCIDA';
              } else {
                cobro.estado = 'PENDIENTE';
              }
            } else if (cobro.montoPagado < cobro.monto) {
              cobro.estado = 'PARCIAL';
            }

            await entityManager.save(cobro);
          }
        }

        pago.cobroId = null;
      }

      pago.estado = input.estado;
      await entityManager.save(pago);
    });

    this.logger.log(`Pago ${pago.id} validado con estado: ${input.estado}`);

    return pago;
  }
}
