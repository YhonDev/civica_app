import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { Pago } from '../../domain/pago.entity';
import { Cobro } from '../../domain/cobro.entity';
import { PagoRepository } from '../../infrastructure/persistence/pago.repository';
import { CobroRepository } from '../../infrastructure/persistence/cobro.repository';
import { PlanDeCobroRepository } from '../../infrastructure/persistence/plan-de-cobro.repository';
import { Money } from '../../../shared/common/value-objects';
import { PagoRegistradoEvent } from '../../domain/events/pago-registrado.event';
import { GenerarTicketUseCase } from './generar-ticket.use-case';
import { TicketCobro } from '../../domain/ticket-cobro.entity';
import { TicketRepository } from '../../infrastructure/persistence/ticket.repository';

import { SolicitudRepository } from '../../infrastructure/persistence/solicitud.repository';
import { SolicitudEstado } from '../../domain/solicitud.entity';

export interface RegistrarPagoInput {
  clientPaymentId: string;
  tenantId: string;
  monto: number; // centavos COP
  fechaPago: string; // ISO date
  cobradorId: string;
  cobradorNombre?: string;
  residenteId: string;
  solicitudId?: string; // Optional request ID to close when paying
}

export interface RegistrarPagoResult {
  pago: Pago;
  cobrosAfectados: Cobro[];
  event: PagoRegistradoEvent;
  ticket: TicketCobro;
}

/**
 * Registers a payment and distributes it across pending cobros using FIFO.
 */
@Injectable()
export class RegistrarPagoUseCase {
  private readonly logger = new Logger(RegistrarPagoUseCase.name);

  constructor(
    private readonly dataSource: DataSource,
    private readonly pagoRepo: PagoRepository,
    private readonly cobroRepo: CobroRepository,
    private readonly planDeCobroRepo: PlanDeCobroRepository,
    private readonly solicitudRepo: SolicitudRepository,
    private readonly generarTicketUC: GenerarTicketUseCase,
    private readonly ticketRepo: TicketRepository,
  ) {}

  async execute(input: RegistrarPagoInput): Promise<RegistrarPagoResult> {
    // 1. Idempotency check
    const existingPago = await this.pagoRepo.findByIdempotentKey(
      input.tenantId,
      input.clientPaymentId,
    );

    if (existingPago) {
      this.logger.warn(
        `Pago idempotente detectado: ${input.clientPaymentId} ya existe (${existingPago.id}). Retornando pago existente.`,
      );

      const cobrosAfectados = existingPago.cobroId
        ? await this.cobroRepo.findByResidente(input.residenteId)
        : [];

      // Build event from existing pago
      const event = new PagoRegistradoEvent(
        existingPago.id,
        existingPago.clientPaymentId,
        existingPago.residenteId,
        existingPago.monto,
        existingPago.cobroId ? [existingPago.cobroId] : [],
        existingPago.createdAt,
      );

      // Look up the ticket that was generated on the original payment
      const existingTicket = await this.ticketRepo.findByPago(existingPago.id);

      return { pago: existingPago, cobrosAfectados, event, ticket: existingTicket as TicketCobro };
    }

    // 2. Validate: residente must have an active plan
    const plan = await this.planDeCobroRepo.findByResidente(
      input.residenteId,
    );

    if (!plan) {
      throw new BadRequestException(
        `El residente ${input.residenteId} no tiene un PlanDeCobro activo.`,
      );
    }

    if (!plan.activa) {
      throw new BadRequestException(
        `El PlanDeCobro del residente ${input.residenteId} está desactivado.`,
      );
    }

    // 3. FIFO Distribution Loop — dentro de transacción con pessimistic locking
    const { pago, cobrosAfectados } = await this.dataSource.transaction(
      async (entityManager) => {
        let remaining = input.monto;
        const cobrosAfectados: Cobro[] = [];

        while (remaining > 0) {
          // Usar PESSIMISTIC_WRITE para evitar race conditions
          // entre pagos concurrentes al mismo residente
          const cobro = await this.cobroRepo.findMasAntiguoConSaldoLocked(
            entityManager,
            input.residenteId,
          );

          if (!cobro) {
            if (remaining > 0) {
              this.logger.warn(
                `Pago ${input.clientPaymentId}: excedente de ${remaining} centavos no aplicado — sin cobros pendientes.`,
              );
            }
            break;
          }

          const excess = cobro.aplicarPago(Money.ofCOP(remaining));
          await entityManager.save(cobro);
          cobrosAfectados.push(cobro);
          remaining = excess.amount;
        }

        if (cobrosAfectados.length === 0) {
          throw new BadRequestException(
            `No hay cobros pendientes para el residente ${input.residenteId}. Todos los saldos están pagados.`,
          );
        }

        // 4. Create Pago record (linked to first affected cobro)
        const firstCobroId = cobrosAfectados[0]?.id;
        const pago = Pago.crear(
          input.clientPaymentId,
          input.tenantId,
          Money.ofCOP(input.monto),
          input.fechaPago,
          input.cobradorId,
          input.residenteId,
          firstCobroId,
        );

        // 5. Persist dentro de la misma transacción
        await entityManager.save(pago);

        if (input.solicitudId) {
          const solicitud = await this.solicitudRepo.findById(input.solicitudId);
          if (solicitud) {
            solicitud.estado = SolicitudEstado.RESUELTA;
            solicitud.pagoId = pago.id;
            solicitud.respuesta = 'Pago registrado exitosamente.';
            solicitud.fechaRespuesta = new Date();
            await entityManager.save(solicitud);
          }
        }

        return { pago, cobrosAfectados };
      },
    );

    // 6. Build event
    const event = new PagoRegistradoEvent(
      pago.id,
      pago.clientPaymentId,
      pago.residenteId,
      pago.monto,
      cobrosAfectados.map((c) => c.id),
      new Date(),
    );

    // 7. Generate and persist ticket
    const ticket = await this.generarTicketUC.execute({
      pago,
      cobrosAfectados,
      cobradorNombre: input.cobradorNombre ?? 'Cobrador',
    });

    this.logger.log(
      `Pago registrado: ${pago.id} | ${input.monto} centavos → ${cobrosAfectados.length} cobro(s) afectado(s) | Ticket: ${ticket.numero}`,
    );

    return { pago, cobrosAfectados, event, ticket };
  }
}
