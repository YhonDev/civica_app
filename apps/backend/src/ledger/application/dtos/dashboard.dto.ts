export interface DashboardResumen {
  recaudoTotal: number;
  metaMensual: number;
  porcentajeMeta: number;
  pagaron: number;
  pendientes: number;
  moraTotal: number;
}

export interface EvolucionDia {
  dia: number;
  valor: number;
}

export interface ModalidadFrecuencia {
  frecuencia: string;
  totalCuotas: number;
  pagadas: number;
  porcentaje: number;
  montoRecaudo: number;
}

export interface EstadoCobros {
  pagados: number;
  pendientes: number;
  revision: number;
}

export interface ActividadItem {
  id: string;
  tipo: string;
  descripcion: string;
  usuario: string;
  timestamp: string;
  hace: string;
}

export interface MesHistorico {
  mes: number;
  anio: number;
  recaudo: number;
  pendientes: number;
  mora: number;
}

export interface CobroSemanaItem {
  semana: number;
  pagados: number;
  pendientes: number;
  mora: number;
}

export interface DashboardResponse {
  mes: number;
  anio: number;
  resumen: DashboardResumen;
  evolucion: EvolucionDia[];
  modalidades: ModalidadFrecuencia[];
  estadoCobros: EstadoCobros;
  actividad: ActividadItem[];
  solicitudesPendientes: number;
  nuevosPropietariosSemana: number;
  propietariosMora: number;
  acumuladoAnual: number;
  metaAnual: number;
  historialMeses: MesHistorico[];
  cobrosPorSemana: CobroSemanaItem[];
}
