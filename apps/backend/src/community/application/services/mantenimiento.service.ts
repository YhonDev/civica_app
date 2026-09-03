import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { DataSource } from 'typeorm';

/**
 * Verifica el modo mantenimiento por-proyecto.
 * Un recurso operado por residente/cobrador se bloquea (503)
 * si el proyecto del residente propietario está en mantenimiento.
 * El ADMIN nunca se bloquea.
 */
@Injectable()
export class MantenimientoService {
  constructor(private readonly dataSource: DataSource) {}

  /**
   * Lanza 503 si el proyecto asociado al residente está en mantenimiento.
   * @param residenteId UUID del residente Dueño del recurso (cobro/pago/solicitud)
   */
  async verificarResidenteNoBloqueado(residenteId: string): Promise<void> {
    if (!residenteId) return;

    const rows: Array<{ modo_mantenimiento: boolean }> =
      await this.dataSource.query(
        `SELECT p.modo_mantenimiento
       FROM planes_de_cobro pc
       JOIN proyectos p ON p.id = pc.proyecto_id
       WHERE pc.residente_id = $1 AND pc.activa = true
       LIMIT 1`,
        [residenteId],
      );

    if (rows.length > 0 && rows[0].modo_mantenimiento) {
      throw new ServiceUnavailableException(
        'El proyecto se encuentra en mantenimiento. Intente nuevamente más tarde.',
      );
    }
  }
}
