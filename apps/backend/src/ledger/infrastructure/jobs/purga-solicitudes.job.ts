import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { DataSource } from 'typeorm';
import { ActividadRepository } from '../../../notifications/domain/actividad.repository';

@Injectable()
export class PurgaSolicitudesJob {
  private readonly logger = new Logger(PurgaSolicitudesJob.name);

  constructor(
    private readonly dataSource: DataSource,
    private readonly actividadRepo?: ActividadRepository,
  ) {}

  /// Runs automatically at 00:00 midnight every day
  @Cron('0 54 * * * *')
  async handleMidnightCron() {
    this.logger.log('🕛 Ejecutando PurgaSolicitudesJob de medianoche...');
    await this.executePurga();
  }

  /// Executes purge of expired solicitudes (>24h or prior to current date 00:00)
  async executePurga(): Promise<{ purgadas: number }> {
    try {
      const queryRunner = this.dataSource.createQueryRunner();
      await queryRunner.connect();
      await queryRunner.startTransaction();

      try {
        const result = await queryRunner.query(
          `UPDATE solicitudes 
           SET estado = 'EXPIRADA', 
               respuesta = 'Solicitud expirada automáticamente por ventana de vigencia (24h/00:00).', 
               fecha_respuesta = NOW(),
               updated_at = NOW()
           WHERE estado IN ('PENDIENTE', 'EN_REVISION') 
             AND (created_at < NOW() - INTERVAL '24 hours' OR fecha < CURRENT_DATE)
           RETURNING id, tenant_id, residente_id, casa_id`,
        );

        await queryRunner.commitTransaction();

        const count = Array.isArray(result)
          ? (result[0]?.length ?? result.length)
          : 0;
        this.logger.log(
          `✅ Purga de solicitudes completada: ${count} solicitud(es) marcadas como EXPIRADA.`,
        );

        if (count > 0 && Array.isArray(result)) {
          for (const row of result[0] ?? result) {
            try {
              if (this.actividadRepo && row.tenant_id) {
                await (this.actividadRepo as any).registrar?.(
                  row.tenant_id,
                  'SOLICITUD_EXPIRADA',
                  `Solicitud ${row.id} expiró automáticamente al vencer el ciclo de 24h.`,
                  row.residente_id ?? undefined,
                );
              }
            } catch (e) {
              this.logger.warn(
                `Could not log audit activity for expired solicitud ${row.id}: ${e}`,
              );
            }
          }
        }

        return { purgadas: count };
      } catch (err) {
        await queryRunner.rollbackTransaction();
        throw err;
      } finally {
        await queryRunner.release();
      }
    } catch (e) {
      this.logger.error(`❌ Error en PurgaSolicitudesJob: ${e}`);
      return { purgadas: 0 };
    }
  }
}
