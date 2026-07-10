import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { GenerarCuotasUseCase } from '../../application/use-cases/generar-cuotas.use-case';

/**
 * Cron job: genera cuotas mensuales el día 1 de cada mes a las 5:00 AM.
 * Un registro por propietario; los abonos parciales (4/2/1) se acumulan en montoPagado.
 */
@Injectable()
export class GenerarCuotasJob {
  private readonly logger = new Logger(GenerarCuotasJob.name);

  constructor(
    private readonly generarCuotasUseCase: GenerarCuotasUseCase,
  ) {}

  /** Día 1 de cada mes a las 5:00 AM */
  @Cron('0 5 1 * *')
  async handleCron() {
    this.logger.log('⏰ Iniciando generación mensual de cuotas (día 1)...');

    try {
      const result = await this.generarCuotasUseCase.execute('');
      this.logger.log(
        `✅ Generación mensual completada: ${result.generated} cuota(s) generada(s)`,
      );

      for (const detalle of result.detalles) {
        this.logger.log(`  ${detalle}`);
      }
    } catch (error) {
      const message =
        error instanceof Error ? error.message : 'Error desconocido';
      this.logger.error(`❌ Error en generación mensual: ${message}`);
    }
  }
}
