import { Injectable, Logger } from '@nestjs/common';
import { CobroRepository } from '../../infrastructure/persistence/cobro.repository';

/**
 * Marks overdue cobros as VENCIDA.
 *
 * Finds all cobros in PENDIENTE or PARCIAL state whose fechaVencimiento
 * has passed, and transitions them to VENCIDA.
 *
 * Called by the daily cron job MarcarVencidasJob.
 */
@Injectable()
export class MarcarVencidasUseCase {
  private readonly logger = new Logger(MarcarVencidasUseCase.name);

  constructor(private readonly cobroRepo: CobroRepository) {}

  async execute(fechaHoy?: string): Promise<{ marcadas: number }> {
    const vencidas = await this.cobroRepo.findVencidas();

    for (const cobro of vencidas) {
      cobro.marcarVencida();
    }

    if (vencidas.length > 0) {
      await this.cobroRepo.saveMany(vencidas);
      this.logger.log(`${vencidas.length} cobro(s) marcado(s) como VENCIDO(s)`);
    }

    return { marcadas: vencidas.length };
  }
}
