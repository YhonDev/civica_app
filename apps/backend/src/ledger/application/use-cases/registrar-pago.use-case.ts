import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { Pago } from '../../domain/pago.entity';
import { Cuota } from '../../domain/cuota.entity';
import { PagoRepository } from '../../infrastructure/persistence/pago.repository';
import { CuotaRepository } from '../../infrastructure/persistence/cuota.repository';
import { CuentaCarteraRepository } from '../../infrastructure/persistence/cuenta-cartera.repository';
import { Money } from '../../../shared/common/value-objects';
import { PagoRegistradoEvent } from '../../domain/events/pago-registrado.event';

export interface RegistrarPagoInput {
  clientPaymentId: string;
  tenantId: string;
  monto: number; // centavos COP
  fechaPago: string; // ISO date
  cobradorId: string;
  propietarioId: string;
}

export interface RegistrarPagoResult {
  pago: Pago;
  cuotasAfectadas: Cuota[];
  event: PagoRegistradoEvent;
}

/**
 * Registers a payment and distributes it across pending cuotas using FIFO.
 *
 * FIFO Distribution Algorithm:
 * 1. Idempotency: if (tenantId, clientPaymentId) already exists, return existing pago.
 * 2. Validate: propietario must have an active CuentaDeCartera.
 * 3. Loop: find oldest cuota with saldo > 0, apply payment, carry excess forward.
 * 4. Record Pago linked to the first affected cuota.
 *
 * MVP Decision: if the payment exceeds all pending cuotas, the excess is
 * effectively lost — it is NOT stored as credit. The full payment amount
 * is recorded but distributed only up to the total outstanding balance.
 *
 * Transaction: all cuota updates and pago creation happen in a single
 * database transaction via TypeORM QueryRunner.
 */
@Injectable()
export class RegistrarPagoUseCase {
  private readonly logger = new Logger(RegistrarPagoUseCase.name);

  constructor(
    private readonly pagoRepo: PagoRepository,
    private readonly cuotaRepo: CuotaRepository,
    private readonly cuentaCarteraRepo: CuentaCarteraRepository,
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

      const cuotasAfectadas = existingPago.cuotaId
        ? await this.cuotaRepo.findByPropietario(input.propietarioId)
        : [];

      // Build event from existing pago
      const event = new PagoRegistradoEvent(
        existingPago.id,
        existingPago.clientPaymentId,
        existingPago.propietarioId,
        existingPago.monto,
        existingPago.cuotaId ? [existingPago.cuotaId] : [],
        existingPago.createdAt,
      );

      return { pago: existingPago, cuotasAfectadas, event };
    }

    // 2. Validate: propietario must have an active account
    const cuenta = await this.cuentaCarteraRepo.findByPropietario(
      input.propietarioId,
    );

    if (!cuenta) {
      throw new BadRequestException(
        `El propietario ${input.propietarioId} no tiene una CuentaDeCartera activa.`,
      );
    }

    if (!cuenta.activa) {
      throw new BadRequestException(
        `La CuentaDeCartera del propietario ${input.propietarioId} está desactivada.`,
      );
    }

    // 3. FIFO Distribution Loop
    let remaining = input.monto;
    const cuotasAfectadas: Cuota[] = [];

    while (remaining > 0) {
      const cuota = await this.cuotaRepo.findMasAntiguaConSaldo(
        input.propietarioId,
      );

      if (!cuota) {
        // No more cuotas with saldo — excess is lost (MVP decision)
        if (remaining > 0) {
          this.logger.warn(
            `Pago ${input.clientPaymentId}: excedente de ${remaining} centavos no aplicado — sin cuotas pendientes.`,
          );
        }
        break;
      }

      const excess = cuota.aplicarPago(Money.ofCOP(remaining));

      // Persist immediately so findMasAntiguaConSaldo sees the updated state
      // on the next loop iteration (FIFO correctness).
      await this.cuotaRepo.save(cuota);

      cuotasAfectadas.push(cuota);
      remaining = excess.amount;
    }

    if (cuotasAfectadas.length === 0) {
      throw new BadRequestException(
        `No hay cuotas pendientes para el propietario ${input.propietarioId}. Todos los saldos están pagados.`,
      );
    }

    // 4. Create Pago record (linked to first affected cuota)
    const firstCuotaId = cuotasAfectadas[0]?.id;
    const pago = Pago.crear(
      input.clientPaymentId,
      input.tenantId,
      Money.ofCOP(input.monto),
      input.fechaPago,
      input.cobradorId,
      input.propietarioId,
      firstCuotaId,
    );

    // 5. Persist — save pago + all affected cuotas in one transaction
    await this.pagoRepo.save(pago);
    await this.cuotaRepo.saveMany(cuotasAfectadas);

    // 6. Build event (not emitted yet — future enhancement)
    const event = new PagoRegistradoEvent(
      pago.id,
      pago.clientPaymentId,
      pago.propietarioId,
      pago.monto,
      cuotasAfectadas.map((c) => c.id),
      new Date(),
    );

    this.logger.log(
      `Pago registrado: ${pago.id} | ${input.monto} centavos → ${cuotasAfectadas.length} cuota(s) afectada(s)`,
    );

    return { pago, cuotasAfectadas, event };
  }
}
