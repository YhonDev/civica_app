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
  monto: number;
}

export interface ModalidadFrecuencia {
  frecuencia: string;
  totalCuotas: number;
  pagadas: number;
  porcentaje: number;
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

export interface DashboardResponse {
  mes: number;
  anio: number;
  resumen: DashboardResumen;
  evolucion: EvolucionDia[];
  modalidades: ModalidadFrecuencia[];
  estadoCobros: EstadoCobros;
  actividad: ActividadItem[];
}
