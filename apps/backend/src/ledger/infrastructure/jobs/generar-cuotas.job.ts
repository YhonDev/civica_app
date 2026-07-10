import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { GenerarCuotasUseCase } from '../../application/use-cases/generar-cuotas.use-case';

/**
 * Cron job scheduled to generate cuotas for all active accounts daily at 5:00 AM.
 * For MVP, this needs to run for each tenant.
 *
 * Note: In a multi-tenant MVP setup, this iterates through known tenants.
 * For simplicity, the cron job logs the event and delegates to the use case.
 * Tenant-specific scheduling would require a tenant registry lookup.
 */
@Injectable()
export class GenerarCuotasJob {
  private readonly logger = new Logger(GenerarCuotasJob.name);

  constructor(
    private readonly generarCuotasUseCase: GenerarCuotasUseCase,
  ) {}

  /**
   * Execute daily at 5:00 AM.
   * For MVP, this generates cuotas without tenant context.
   * In production, this should be replaced with tenant-aware logic.
   */
  @Cron('0 5 * * *')
  async handleCron() {
    this.logger.log('⏰ Iniciando generación automática de cuotas...');

    try {
      // For MVP: generate for all conjuntos without tenant context.
      // In production, this should iterate over all tenants.
      const result = await this.generarCuotasUseCase.execute('');
      this.logger.log(
        `✅ Generación automática completada: ${result.generated} cuotas generadas`,
      );

      for (const detalle of result.detalles) {
        this.logger.log(`  ${detalle}`);
      }
    } catch (error) {
      const message =
        error instanceof Error ? error.message : 'Error desconocido';
      this.logger.error(`❌ Error en generación automática: ${message}`);
    }
  }
}
