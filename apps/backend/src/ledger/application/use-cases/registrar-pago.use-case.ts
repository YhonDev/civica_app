import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { Pago } from '../../domain/pago.entity';
import { Cobro } from '../../domain/cobro.entity';
import { PagoCobro } from '../../domain/pago-cobro.entity';
import { PagoRepository } from '../../infrastructure/persistence/pago.repository';
import { CobroRepository } from '../../infrastructure/persistence/cobro.repository';
import { PlanDeCobroRepository } from '../../infrastructure/persistence/plan-de-cobro.repository';
import { PagoCobroRepository } from '../../infrastructure/persistence/pago-cobro.repository';
import { Money } from '../../../shared/common/value-objects';
import { PagoRegistradoEvent } from '../../domain/events/pago-registrado.event';
import { GenerarTicketUseCase } from './generar-ticket.use-case';
import { TicketCobro } from '../../domain/ticket-cobro.entity';
import { TicketRepository } from '../../infrastructure/persistence/ticket.repository';

import { SolicitudRepository } from '../../infrastructure/persistence/solicitud.repository';
import { SolicitudEstado } from '../../domain/solicitud.entity';
import { EventsGateway } from '../../../notifications/events.gateway';
import { FcmPushService } from '../../../notifications/infrastructure/push/fcm-push.service';

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
    private readonly pagoCobroRepo: PagoCobroRepository,
    private readonly eventsGateway?: EventsGateway,
    private readonly fcmPushService?: FcmPushService,
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
        ? await this.cobroRepo.findByResidente(input.residenteId, input.tenantId)
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
        const vinculos: PagoCobro[] = [];

        while (remaining > 0) {
          // Usar PESSIMISTIC_WRITE para evitar race conditions
          // entre pagos concurrentes al mismo residente
          const cobro = await this.cobroRepo.findMasAntiguoConSaldoLocked(
            entityManager,
            input.residenteId,
            input.tenantId,
          );

          if (!cobro) {
            if (remaining > 0) {
              this.logger.warn(
                `Pago ${input.clientPaymentId}: excedente de ${remaining} centavos no aplicado — sin cobros pendientes.`,
              );
            }
            break;
          }

          const aplicado = Math.min(
            remaining,
            cobro.monto - cobro.montoPagado,
          );
          const excess = cobro.aplicarPago(Money.ofCOP(remaining));
          await entityManager.save(cobro);
          cobrosAfectados.push(cobro);
          // pagoId se completa al guardar el Pago (paso 5b), ya que aún no existe.
          vinculos.push(
            PagoCobro.crear('', cobro.id, aplicado, input.tenantId),
          );
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

        // 5b. Registrar los vínculos PagoCobro (pagoId se conoce tras el save)
        for (const vinculo of vinculos) {
          vinculo.pagoId = pago.id;
          await this.pagoCobroRepo.save(entityManager, vinculo);
        }

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

        // Auto-resolver cualquier solicitud pendiente activa del residente para actualizar la interfaz
        try {
          const queryRunner = (entityManager as any).query ? entityManager : (this.dataSource as any);
          if (queryRunner && typeof queryRunner.query === 'function') {
            const pendingSolicitudes = await queryRunner.query(
              `SELECT id FROM solicitudes 
               WHERE tenant_id = $1 
                 AND (residente_id = $2 OR cobro_id IN (${cobrosAfectados.map((_, i) => `$${i + 3}`).join(',') || 'NULL'}))
                 AND estado IN ('PENDIENTE', 'EN_REVISION')`,
              [input.tenantId, input.residenteId, ...cobrosAfectados.map((c) => c.id)],
            );
            if (Array.isArray(pendingSolicitudes)) {
              for (const sol of pendingSolicitudes) {
                await queryRunner.query(
                  `UPDATE solicitudes 
                   SET estado = 'RESUELTA', pago_id = $1, respuesta = 'Pago registrado exitosamente por el cobrador.', fecha_respuesta = NOW() 
                   WHERE id = $2`,
                  [pago.id, sol.id],
                );
              }
            }
          }
        } catch (e) {
          this.logger.warn(`Could not auto-resolve solicitudes: ${e}`);
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

    this.eventsGateway?.emitPagoRegistrado({
      tenantId: input.tenantId,
      residenteId: input.residenteId,
      cobroId: pago.cobroId ?? (cobrosAfectados[0]?.id ?? ''),
      monto: input.monto,
    });

    this.fcmPushService?.sendPagoRegistradoPush({
      residenteToken: undefined, // Dispatched to residente device token if registered
      monto: input.monto,
      pagoId: pago.id,
      casaNombre: 'Vivienda Residente',
    });

    return { pago, cobrosAfectados, event, ticket };
  }
}
