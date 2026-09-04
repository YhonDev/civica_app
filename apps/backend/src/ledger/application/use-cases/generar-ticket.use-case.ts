import { Injectable, Logger } from '@nestjs/common';
import { TicketCobro } from '../../domain/ticket-cobro.entity';
import { TicketRepository } from '../../infrastructure/persistence/ticket.repository';
import { ResidenteRepository } from '../../../community/infrastructure/residente.repository';
import { Pago } from '../../domain/pago.entity';
import { Cobro } from '../../domain/cobro.entity';
import { Money } from '../../../shared/common/value-objects';

export interface GenerarTicketCobroInput {
  pago: Pago;
  cobrosAfectados: Cobro[];
  cobradorNombre: string;
}

/**
 * Generates and persists a TicketCobro after a payment is registered.
 *
 * Responsibilities:
 * 1. Fetches residente + casa + manzana + etapa for snapshot data
 * 2. Generates sequential ticket number (TKT-YYYY-NNNNNN)
 * 3. Creates TicketCobro entity with all snapshot data
 * 4. Persists the ticket
 */
@Injectable()
export class GenerarTicketUseCase {
  private readonly logger = new Logger(GenerarTicketUseCase.name);

  constructor(
    private readonly ticketRepo: TicketRepository,
    private readonly residenteRepo: ResidenteRepository,
  ) {}

  async execute(input: GenerarTicketCobroInput): Promise<TicketCobro> {
    // 1. Load residente with full location chain for snapshot
    const residente = await this.residenteRepo.findByIdWithRelations(
      input.pago.residenteId,
      input.pago.tenantId,
    );

    if (!residente) {
      this.logger.warn(
        `Residente ${input.pago.residenteId} not found — ticket will use fallback data`,
      );
    }

    // 2. Extract snapshot data from the relation chain
    const activeTenencia = residente?.tenencias?.find(
      (t) => t.fechaFin === null,
    );
    const casa = activeTenencia?.casa;
    const manzana = casa?.manzana;
    const etapa = manzana?.etapa;

    const residenteNombre = residente?.nombre ?? 'Residente desconocido';
    const residenteDocumento = residente?.documento ?? null;
    const casaDireccion = casa?.direccionInterna ?? 'Sin dirección';
    const etapaNombre = etapa?.nombre ?? 'Sin etapa';
    const manzanaNombre = manzana?.nombre ?? 'Sin manzana';

    // 3. Generate sequential number
    const numero = await this.ticketRepo.nextNumero(input.pago.tenantId);

    // 4. Build concepto from first affected cobro
    const primerCobro = input.cobrosAfectados[0];
    const concepto = primerCobro?.concepto ?? 'Pago registrado';

    // 5. Create and persist
    const ticket = TicketCobro.crear({
      numero,
      tenantId: input.pago.tenantId,
      residenteId: input.pago.residenteId,
      residenteNombre,
      residenteDocumento,
      casaDireccion,
      etapa: etapaNombre,
      manzana: manzanaNombre,
      pagoId: input.pago.id,
      cobroId: primerCobro?.id ?? null,
      cobradorId: input.pago.cobradorId,
      cobradorNombre: input.cobradorNombre,
      monto: Money.ofCOP(input.pago.monto),
      concepto,
    });

    const saved = await this.ticketRepo.save(ticket);

    this.logger.log(
      `Ticket generado: ${saved.numero} | Pago: ${input.pago.id} | Monto: ${input.pago.monto} centavos`,
    );

    return saved as TicketCobro;
  }
}
