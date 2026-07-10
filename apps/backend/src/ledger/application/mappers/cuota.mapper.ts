import { Cuota } from '../../domain/cuota.entity';
import {
  Frecuencia,
  pagosPorMes,
  calcularMontoParcial,
} from '../../../shared/common/value-objects';

export interface CuotaConParciales {
  id: string;
  propietarioId: string;
  tenantId: string;
  tarifaId: string | null;
  concepto: string;
  monto: number;
  montoPagado: number;
  periodoInicio: string;
  periodoFin: string;
  fechaVencimiento: string;
  estado: string;
  notificacionEnviada: boolean;
  createdAt: Date;
  updatedAt: Date;
  pagosEsperados: number;
  montoParcial: number;
  montoParcialPesos: number;
  pagosRegistrados: number;
  saldoPendiente: number;
  saldoPendientePesos: number;
}

export function mapCuotaConParciales(
  cuota: Cuota,
  frecuencia: Frecuencia,
  pagosRegistrados: number,
): CuotaConParciales {
  const pagosEsperados = pagosPorMes(frecuencia);
  const montoParcial = calcularMontoParcial(cuota.monto, frecuencia).amount;
  const saldoPendiente = cuota.monto - cuota.montoPagado;

  return {
    id: cuota.id,
    propietarioId: cuota.propietarioId,
    tenantId: cuota.tenantId,
    tarifaId: cuota.tarifaId,
    concepto: cuota.concepto,
    monto: cuota.monto,
    montoPagado: cuota.montoPagado,
    periodoInicio: cuota.periodoInicio,
    periodoFin: cuota.periodoFin,
    fechaVencimiento: cuota.fechaVencimiento,
    estado: cuota.estado,
    notificacionEnviada: cuota.notificacionEnviada,
    createdAt: cuota.createdAt,
    updatedAt: cuota.updatedAt,
    pagosEsperados,
    montoParcial,
    montoParcialPesos: Math.round(montoParcial / 100),
    pagosRegistrados,
    saldoPendiente,
    saldoPendientePesos: Math.round(saldoPendiente / 100),
  };
}
