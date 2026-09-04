import {
  Injectable,
  BadRequestException,
  NotFoundException,
  Logger,
  Optional,
} from '@nestjs/common';
import { DataSource } from 'typeorm';
import { Pago, EstadoValidacionPago } from '../../domain/pago.entity';
import { PagoEdicion } from '../../domain/pago-edicion.entity';
import { Cobro } from '../../domain/cobro.entity';
import { PagoCobro } from '../../domain/pago-cobro.entity';
import { Ticket } from '../../domain/ticket.entity';
import { PagoRepository } from '../../infrastructure/persistence/pago.repository';
import { CobroRepository } from '../../infrastructure/persistence/cobro.repository';
import { PagoCobroRepository } from '../../infrastructure/persistence/pago-cobro.repository';
import { GenerarTicketUseCase } from './generar-ticket.use-case';
import { Money } from '../../../shared/common/value-objects';
import { revertirAbonos } from './revertir-abonos';

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
    private readonly pagoCobroRepo: PagoCobroRepository,
    @Optional() private readonly generarTicketUC?: GenerarTicketUseCase,
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
      // 1. Revertir EXACTAMENTE los cobros que el pago afectó (vía pago_cobros),
      //    con fallback LIFO para pagos legacy sin vínculos.
      await revertirAbonos(entityManager, pago, this.pagoCobroRepo);

      // 2. Aplicar el nuevo monto en los cobros (FIFO distribución)
      let remainingToApply = input.nuevoMonto;
      const cobrosAfectados: Cobro[] = [];
      const vinculosNuevos: PagoCobro[] = [];

      while (remainingToApply > 0) {
        // Encontrar el cobro más antiguo con saldo pendiente para el residente
        const cobroPendiente =
          await this.cobroRepo.findMasAntiguoConSaldoLocked(
            entityManager,
            pago.residenteId,
            pago.tenantId,
          );

        if (!cobroPendiente) {
          this.logger.warn(
            `Corrección de Pago ${pago.id}: excedente de ${remainingToApply} centavos no aplicado — sin cobros pendientes.`,
          );
          break;
        }

        const aplicado = Math.min(
          remainingToApply,
          cobroPendiente.monto - cobroPendiente.montoPagado,
        );
        const excess = cobroPendiente.aplicarPago(
          Money.ofCOP(remainingToApply),
        );
        await entityManager.save(cobroPendiente);
        cobrosAfectados.push(cobroPendiente);
        vinculosNuevos.push(
          PagoCobro.crear(pago.id, cobroPendiente.id, aplicado, pago.tenantId),
        );
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

      // 4. Registrar los vínculos del nuevo abono en la misma transacción
      for (const vinculo of vinculosNuevos) {
        await this.pagoCobroRepo.save(entityManager, vinculo);
      }

      // 5. Actualizar el pago
      pago.monto = input.nuevoMonto;
      pago.cobroId = cobrosAfectados[0]?.id ?? null;
      await entityManager.save(pago);

      // 6. Anular ticket anterior si existe
      if (typeof (entityManager as any).update === 'function') {
        try {
          await entityManager.update(
            Ticket,
            { pagoId: pago.id, tenantId: input.tenantId },
            { estado: 'ANULADO' },
          );
        } catch (err) {
          this.logger.warn(
            `No se pudo anular ticket previo para pago ${pago.id}: ${err}`,
          );
        }
      }

      // 7. Generar nuevo ticket para el pago corregido si use case está disponible
      if (this.generarTicketUC) {
        try {
          await this.generarTicketUC.execute({
            pago,
            cobrosAfectados,
            cobradorNombre: pago.cobrador?.nombre ?? 'Administrador',
          });
        } catch (err) {
          this.logger.warn(
            `No se pudo generar nuevo ticket tras corrección de pago ${pago.id}: ${err}`,
          );
        }
      }
    });

    this.logger.log(
      `Pago corregido: ${pago.id} | Monto anterior: ${montoAnterior} -> Nuevo monto: ${input.nuevoMonto}`,
    );

    return pago;
  }
}

