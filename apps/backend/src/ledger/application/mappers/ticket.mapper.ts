import { Ticket } from '../../domain/ticket.entity';
import { TicketCobro } from '../../domain/ticket-cobro.entity';

/**
 * Base ticket response — visible to ALL roles.
 */
export interface TicketResponseDto {
  id: string;
  tipo: string;
  numero: string;
  fecha: string;
  residenteNombre: string;
  casaDireccion: string;
  etapa: string;
  manzana: string;
  estado: string;
  // TicketCobro-specific (present when tipo === 'COBRO')
  monto?: number;
  metodo?: string;
  concepto?: string;
}

/**
 * Extended ticket response — visible to COBRADOR and ADMIN.
 * Adds cobrador info and IDs for traceability.
 */
export interface TicketCobradorResponseDto extends TicketResponseDto {
  residenteId: string;
  cobradorNombre: string | null;
  pagoId: string | null;
  cobroId: string | null;
}

/**
 * Full ticket response — visible to ADMIN only.
 * Adds every field for complete traceability.
 */
export interface TicketAdminResponseDto extends TicketCobradorResponseDto {
  tenantId: string;
  cobradorId: string | null;
  residenteDocumento: string | null;
  createdAt: string;
  updatedAt: string;
}

type RolProjection = 'RESIDENTE' | 'COBRADOR' | 'ADMIN';

/**
 * Maps a Ticket entity to a role-appropriate DTO.
 *
 * - RESIDENTE: minimal info (what they paid, when, where)
 * - COBRADOR:  + cobrador name, residente ID, pago/cobro IDs
 * - ADMIN:     + tenant, cobrador ID, documento, timestamps
 */
export function mapTicketToResponse(
  ticket: Ticket,
  rol: RolProjection,
): TicketResponseDto | TicketCobradorResponseDto | TicketAdminResponseDto {
  const isTicketCobro = ticket.tipo === 'COBRO';
  const ticketCobro = isTicketCobro ? (ticket as TicketCobro) : null;

  // Base — everyone sees this
  const base: TicketResponseDto = {
    id: ticket.id,
    tipo: ticket.tipo,
    numero: ticket.numero,
    fecha: ticket.fecha.toISOString(),
    residenteNombre: ticket.residenteNombre,
    casaDireccion: ticket.casaDireccion,
    etapa: ticket.etapa,
    manzana: ticket.manzana,
    estado: ticket.estado,
    ...(ticketCobro && {
      monto: ticketCobro.monto ?? undefined,
      metodo: ticketCobro.metodo ?? undefined,
      concepto: ticketCobro.concepto ?? undefined,
    }),
  };

  if (rol === 'RESIDENTE') {
    return base;
  }

  // Cobrador — adds traceability IDs and cobrador name
  const cobradorDto: TicketCobradorResponseDto = {
    ...base,
    residenteId: ticket.residenteId,
    cobradorNombre: ticketCobro?.cobradorNombre ?? null,
    pagoId: ticketCobro?.pagoId ?? null,
    cobroId: ticketCobro?.cobroId ?? null,
  };

  if (rol === 'COBRADOR') {
    return cobradorDto;
  }

  // Admin — full info
  return {
    ...cobradorDto,
    tenantId: ticket.tenantId,
    cobradorId: ticketCobro?.cobradorId ?? null,
    residenteDocumento: ticket.residenteDocumento,
    createdAt: ticket.createdAt.toISOString(),
    updatedAt: ticket.updatedAt.toISOString(),
  };
}
