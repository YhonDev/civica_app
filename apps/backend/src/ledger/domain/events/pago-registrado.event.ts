/**
 * Event emitted when a Pago is registered and distributed via FIFO.
 *
 * This event is currently created but not emitted to a bus — it is
 * returned as part of the RegistrarPagoResult for future EventBus integration.
 */
export class PagoRegistradoEvent {
  constructor(
    public readonly pagoId: string,
    public readonly clientPaymentId: string,
    public readonly residenteId: string,
    public readonly monto: number, // centavos COP
    public readonly cuotasAfectadas: string[], // cuota IDs
    public readonly fechaRegistro: Date,
  ) {}
}
