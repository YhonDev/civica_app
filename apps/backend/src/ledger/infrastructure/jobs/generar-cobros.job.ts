import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { GenerarCobrosUseCase } from '../../application/use-cases/generar-cobros.use-case';

/**
 * Cron job that generates cobros for active planes_de_cobro.
 * Runs daily at 00:05.
 */
@Injectable()
export class GenerarCobrosJob {
  private readonly logger = new Logger(GenerarCobrosJob.name);

  constructor(private readonly generarCobrosUC: GenerarCobrosUseCase) {}

  @Cron('0 5 0 * * *', { timeZone: 'America/Bogota' })
  async handleCron() {
    this.logger.log('⏰ Iniciando generación automática de cobros...');

    try {
      const result = await this.generarCobrosUC.execute();
      this.logger.log(
        `[GenerarCobrosJob] ${result.generados} cobro(s) generado(s)`,
      );
    } catch (error) {
      const message =
        error instanceof Error ? error.message : 'Error desconocido';
      this.logger.error(`❌ Error generando cobros: ${message}`);
    }
  }
}
