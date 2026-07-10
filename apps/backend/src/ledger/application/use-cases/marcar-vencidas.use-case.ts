import { Injectable, Logger } from '@nestjs/common';
import { CuotaRepository } from '../../infrastructure/persistence/cuota.repository';

/**
 * Marks overdue cuotas as VENCIDA.
 *
 * Finds all cuotas in PENDIENTE or PARCIAL state whose fechaVencimiento
 * has passed, and transitions them to VENCIDA.
 *
 * Called by the daily cron job MarcarVencidasJob.
 */
@Injectable()
export class MarcarVencidasUseCase {
  private readonly logger = new Logger(MarcarVencidasUseCase.name);

  constructor(private readonly cuotaRepo: CuotaRepository) {}

  async execute(fechaHoy?: string): Promise<{ marcadas: number }> {
    const hoy = fechaHoy ?? new Date().toISOString().split('T')[0];
    const vencidas = await this.cuotaRepo.findVencidas(hoy);

    for (const cuota of vencidas) {
      cuota.marcarVencida();
    }

    if (vencidas.length > 0) {
      await this.cuotaRepo.saveMany(vencidas);
      this.logger.log(`${vencidas.length} cuota(s) marcada(s) como VENCIDA(s)`);
    }

    return { marcadas: vencidas.length };
  }
}
