import { Cobro } from '../../domain/cobro.entity';

export interface CobroResponseDto {
  id: string;
  residenteId: string;
  concepto: string;
  monto: number;
  montoPagado: number;
  saldo: number;
  periodoInicio: string;
  periodoFin: string;
  fechaVencimiento: string;
  estado: string;
}

export function mapCobroToResponse(cobro: Cobro): CobroResponseDto {
  return {
    id: cobro.id,
    residenteId: cobro.residenteId,
    concepto: cobro.concepto,
    monto: cobro.monto,
    montoPagado: cobro.montoPagado,
    saldo: cobro.monto - cobro.montoPagado,
    periodoInicio: cobro.periodoInicio,
    periodoFin: cobro.periodoFin,
    fechaVencimiento: cobro.fechaVencimiento,
    estado: cobro.estado,
  };
}
