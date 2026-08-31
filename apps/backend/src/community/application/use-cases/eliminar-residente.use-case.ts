import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { ResidenteRepository } from '../../infrastructure/residente.repository';

@Injectable()
export class EliminarResidenteUseCase {
  private readonly logger = new Logger(EliminarResidenteUseCase.name);

  constructor(
    private readonly residenteRepository: ResidenteRepository,
    private readonly dataSource: DataSource,
  ) {}

  async execute(id: string, tenantId: string): Promise<void> {
    const residente = await this.residenteRepository.findById(id);

    if (!residente || residente.tenantId !== tenantId) {
      throw new NotFoundException('Residente no encontrado');
    }

    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      this.logger.log(`Iniciando eliminación en cascada para residente ${id}...`);

      // 1. Eliminar solicitudes asociadas
      await queryRunner.query(
        `DELETE FROM solicitudes WHERE residente_id = $1 OR usuario_id IN (SELECT id FROM usuarios WHERE residente_id = $1)`,
        [id],
      );

      // 2. Eliminar relaciones pago_cobros y pagos
      await queryRunner.query(
        `DELETE FROM pago_cobros WHERE pago_id IN (SELECT id FROM pagos WHERE residente_id = $1)`,
        [id],
      );
      await queryRunner.query(
        `DELETE FROM pagos WHERE residente_id = $1`,
        [id],
      );

      // 3. Eliminar cobros y periodos_cobro
      await queryRunner.query(
        `DELETE FROM cobros WHERE residente_id = $1 OR periodo_id IN (SELECT id FROM periodos_cobro WHERE plan_id IN (SELECT id FROM planes_de_cobro WHERE residente_id = $1))`,
        [id],
      );
      await queryRunner.query(
        `DELETE FROM periodos_cobro WHERE plan_id IN (SELECT id FROM planes_de_cobro WHERE residente_id = $1)`,
        [id],
      );

      // 4. Eliminar planes de cobro
      await queryRunner.query(
        `DELETE FROM planes_de_cobro WHERE residente_id = $1`,
        [id],
      );

      // 5. Eliminar tenencias
      await queryRunner.query(
        `DELETE FROM tenencias WHERE residente_id = $1`,
        [id],
      );

      // 6. Eliminar usuario y credenciales
      await queryRunner.query(
        `DELETE FROM usuarios WHERE residente_id = $1`,
        [id],
      );

      // 7. Eliminar la entidad residente
      await queryRunner.query(
        `DELETE FROM residentes WHERE id = $1 AND tenant_id = $2`,
        [id, tenantId],
      );

      await queryRunner.commitTransaction();
      this.logger.log(`Residente ${id} y todas sus relaciones eliminadas exitosamente.`);
    } catch (e) {
      await queryRunner.rollbackTransaction();
      this.logger.error(`Error eliminando residente en cascada: ${e}`);
      throw e;
    } finally {
      await queryRunner.release();
    }
  }
}
