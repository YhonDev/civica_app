import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { PagoRepository } from '../../infrastructure/persistence/pago.repository';
import { PagoCobroRepository } from '../../infrastructure/persistence/pago-cobro.repository';
import { TicketCobro } from '../../domain/ticket-cobro.entity';
import { revertirAbonos } from './revertir-abonos';

@Injectable()
export class EliminarPagoUseCase {
  private readonly logger = new Logger(EliminarPagoUseCase.name);

  constructor(
    private readonly dataSource: DataSource,
    private readonly pagoRepo: PagoRepository,
    private readonly pagoCobroRepo: PagoCobroRepository,
  ) {}

  async execute(id: string, tenantId: string): Promise<void> {
    const pago = await this.pagoRepo.findById(id, tenantId);

    if (!pago) {
      throw new NotFoundException(`Pago ${id} no encontrado`);
    }

    await this.dataSource.transaction(async (entityManager) => {
      // Revertir EXACTAMENTE los cobros que el pago afectó (vía pago_cobros),
      // con fallback LIFO para pagos legacy sin vínculos.
      const cobrosRevertidos = await revertirAbonos(
        entityManager,
        pago,
        this.pagoCobroRepo,
      );

      // Anular tickets emitidos para este pago si entityManager lo soporta
      if (typeof (entityManager as any).update === 'function') {
        try {
          await entityManager.update(
            TicketCobro,
            { pagoId: id, tenantId },
            { estado: 'ANULADO' },
          );
        } catch (err) {
          // Anulación de tickets es best-effort: si falla, el pago se elimina igual
          this.logger.warn(
            `No se pudieron anular tickets del pago ${id}: ${err}`,
          );
        }
      }

      // Eliminar el pago
      await entityManager.remove(pago);

      this.logger.log(
        `Pago eliminado: ${id} | ${cobrosRevertidos.length} cobro(s) revertido(s)`,
      );
    });
  }
}
