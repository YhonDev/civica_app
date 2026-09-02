import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { MarcarVencidasUseCase } from '../../application/use-cases/marcar-vencidas.use-case';

/**
 * Cron job that marks overdue cobros as VENCIDA daily.
 *
 * Runs at 00:10 (10 minutes after cobro generation at 00:05)
 * to ensure new cobros are generated before checking for overdue ones.
 */
@Injectable()
export class MarcarVencidasJob {
  private readonly logger = new Logger(MarcarVencidasJob.name);

  constructor(private readonly marcarVencidasUC: MarcarVencidasUseCase) {}

  @Cron('0 48 * * * *')
  async handleCron() {
    this.logger.log('⏰ Iniciando marcado de cobros vencidos...');

    try {
      const result = await this.marcarVencidasUC.execute();
      this.logger.log(
        `[MarcarVencidasJob] ${result.marcadas} cobro(s) marcado(s) como vencido(s)`,
      );
    } catch (error) {
      const message =
        error instanceof Error ? error.message : 'Error desconocido';
      this.logger.error(`❌ Error en marcado de vencidas: ${message}`);
    }
  }
}
