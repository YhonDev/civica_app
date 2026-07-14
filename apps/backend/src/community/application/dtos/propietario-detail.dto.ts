export interface PropietarioDetailResponse {
  id: string;
  nombre: string;
  casa: string;
  etapa: string;
  saldoPendiente: number;
  estadoFinanciero: string;
  modalidadPago: string;
  proximoVencimiento: string; // Formatted date: '15 de Julio'
  movimientos: MovimientoItem[];
}

export interface MovimientoItem {
  mes: string;
  pagado: boolean;
  monto: number;
  fecha: string;
}
