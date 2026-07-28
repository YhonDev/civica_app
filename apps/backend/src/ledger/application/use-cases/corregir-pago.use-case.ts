import { Injectable, BadRequestException, NotFoundException, Logger } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { Pago, EstadoValidacionPago } from '../../domain/pago.entity';
import { PagoEdicion } from '../../domain/pago-edicion.entity';
import { Cobro } from '../../domain/cobro.entity';
import { PagoRepository } from '../../infrastructure/persistence/pago.repository';
import { CobroRepository } from '../../infrastructure/persistence/cobro.repository';
import { Money } from '../../../shared/common/value-objects';

export interface CorregirPagoInput {
  pagoId: string;
  nuevoMonto: number; // en centavos COP
  motivo: string;
  usuarioId: string;
  tenantId: string;
}

@Injectable()
export class CorregirPagoUseCase {
  private readonly logger = new Logger(CorregirPagoUseCase.name);

  constructor(
    private readonly dataSource: DataSource,
    private readonly pagoRepo: PagoRepository,
    private readonly cobroRepo: CobroRepository,
  ) {}

  async execute(input: CorregirPagoInput): Promise<Pago> {
    const pago = await this.pagoRepo.findById(input.pagoId);

    if (!pago || pago.tenantId !== input.tenantId) {
      throw new NotFoundException(`Pago ${input.pagoId} no encontrado`);
    }

    if (pago.estado !== EstadoValidacionPago.PENDIENTE_REVISION) {
      throw new BadRequestException(
        `No se puede corregir un pago en estado ${pago.estado}. Solo se permiten modificaciones en PENDIENTE_REVISION.`,
      );
    }

    if (input.nuevoMonto <= 0) {
      throw new BadRequestException('El nuevo monto debe ser mayor a cero.');
    }

    const montoAnterior = pago.monto;

    await this.dataSource.transaction(async (entityManager) => {
      // 1. Revertir el abono anterior en los cobros (LIFO inverso)
      let remainingToReverse = pago.monto;
      const cobros = await this.cobroRepo.findByResidente(pago.residenteId);
      
      // Sort cobros: newest first for LIFO reversal
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

      // 2. Aplicar el nuevo monto en los cobros (FIFO distribución)
      let remainingToApply = input.nuevoMonto;
      const cobrosAfectados: Cobro[] = [];

      while (remainingToApply > 0) {
        // Encontrar el cobro más antiguo con saldo pendiente para el residente
        // Usamos la lógica de buscar entre los cobros del residente cargados en la transacción
        const cobroPendiente = await this.cobroRepo.findMasAntiguoConSaldoLocked(
          entityManager,
          pago.residenteId,
        );

        if (!cobroPendiente) {
          this.logger.warn(
            `Corrección de Pago ${pago.id}: excedente de ${remainingToApply} centavos no aplicado — sin cobros pendientes.`,
          );
          break;
        }

        const excess = cobroPendiente.aplicarPago(Money.ofCOP(remainingToApply));
        await entityManager.save(cobroPendiente);
        cobrosAfectados.push(cobroPendiente);
        remainingToApply = excess.amount;
      }

      if (cobrosAfectados.length === 0) {
        throw new BadRequestException(
          `No se puede aplicar el nuevo monto. No hay cobros pendientes para el residente.`,
        );
      }

      // 3. Crear el log de auditoría PagoEdicion
      const edicion = PagoEdicion.crear(
        pago.id,
        pago.tenantId,
        montoAnterior,
        input.nuevoMonto,
        input.motivo,
        input.usuarioId,
      );
      await entityManager.save(edicion);

      // 4. Actualizar el pago
      pago.monto = input.nuevoMonto;
      pago.cobroId = cobrosAfectados[0]?.id ?? null;
      await entityManager.save(pago);
    });

    this.logger.log(
      `Pago corregido: ${pago.id} | Monto anterior: ${montoAnterior} -> Nuevo monto: ${input.nuevoMonto}`,
    );

    return pago;
  }
}
