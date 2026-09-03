import { ChildEntity, Column } from 'typeorm';
import { Ticket } from './ticket.entity';
import { Money } from '../../shared/common/value-objects';

export type MetodoPago = 'EFECTIVO' | 'TRANSFERENCIA' | 'DIGITAL';

/**
 * Ticket emitted when a payment (Pago) is registered.
 *
 * Extends Ticket with payment-specific fields:
 * cobrador info, payment amount, cobro reference, and method.
 */
@ChildEntity('COBRO')
export class TicketCobro extends Ticket {
  @Column({ name: 'pago_id', type: 'uuid', nullable: true })
  pagoId: string | null;

  @Column({ name: 'cobro_id', type: 'uuid', nullable: true })
  cobroId: string | null;

  @Column({ name: 'cobrador_id', type: 'uuid', nullable: true })
  cobradorId: string | null;

  @Column({
    name: 'cobrador_nombre',
    type: 'varchar',
    length: 255,
    nullable: true,
  })
  cobradorNombre: string | null;

  @Column({ name: 'monto', type: 'integer', nullable: true })
  monto: number | null; // centavos COP

  @Column({
    name: 'metodo',
    type: 'varchar',
    length: 50,
    nullable: true,
    default: 'EFECTIVO',
  })
  metodo: MetodoPago;

  @Column({ name: 'concepto', type: 'varchar', length: 255, nullable: true })
  concepto: string | null;

  // ── Factory ────────────────────────────────────────────

  static crear(params: {
    numero: string;
    tenantId: string;
    residenteId: string;
    residenteNombre: string;
    residenteDocumento: string | null;
    casaDireccion: string;
    etapa: string;
    manzana: string;
    pagoId: string;
    cobroId: string | null;
    cobradorId: string;
    cobradorNombre: string;
    monto: Money;
    metodo?: MetodoPago;
    concepto: string;
  }): TicketCobro {
    const ticket = new TicketCobro();
    ticket.tipo = 'COBRO';
    ticket.numero = params.numero;
    ticket.fecha = new Date();
    ticket.tenantId = params.tenantId;
    ticket.residenteId = params.residenteId;
    ticket.residenteNombre = params.residenteNombre;
    ticket.residenteDocumento = params.residenteDocumento;
    ticket.casaDireccion = params.casaDireccion;
    ticket.etapa = params.etapa;
    ticket.manzana = params.manzana;
    ticket.estado = 'EMITIDO';
    ticket.pagoId = params.pagoId;
    ticket.cobroId = params.cobroId;
    ticket.cobradorId = params.cobradorId;
    ticket.cobradorNombre = params.cobradorNombre;
    ticket.monto = params.monto.amount;
    ticket.metodo = params.metodo ?? 'EFECTIVO';
    ticket.concepto = params.concepto;
    return ticket;
  }

  getMonto(): Money {
    return new Money(this.monto ?? 0, 'COP');
  }
}
