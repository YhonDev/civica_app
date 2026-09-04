import { Injectable, Logger } from '@nestjs/common';
import { CobroRepository } from '../../infrastructure/persistence/cobro.repository';

/**
 * Marks overdue cobros as VENCIDA.
 *
 * Uses a single atomic SQL UPDATE to transition all PENDIENTE/PARCIAL cobros
 * whose fechaVencimiento has passed to VENCIDA. This avoids the lost-update
 * race condition that a read-modify-write approach would have with concurrent
 * payments modifying the same cobros.
 *
 * Called by the daily cron job MarcarVencidasJob.
 */
@Injectable()
export class MarcarVencidasUseCase {
  private readonly logger = new Logger(MarcarVencidasUseCase.name);

  constructor(private readonly cobroRepo: CobroRepository) {}

  async execute(): Promise<{ marcadas: number }> {
    const marcadas = await this.cobroRepo.markVencidasAtomic();

    if (marcadas > 0) {
      this.logger.log(`${marcadas} cobro(s) marcado(s) como VENCIDO(s)`);
    }

    return { marcadas };
  }
}
