import { Injectable, NotFoundException, BadRequestException, Logger } from '@nestjs/common';
import { CuotaRepository } from '../../infrastructure/persistence/cuota.repository';
import { PagoRepository } from '../../infrastructure/persistence/pago.repository';

@Injectable()
export class EliminarCuotaUseCase {
  private readonly logger = new Logger(EliminarCuotaUseCase.name);

  constructor(
    private readonly cuotaRepo: CuotaRepository,
    private readonly pagoRepo: PagoRepository,
  ) {}

  async execute(id: string, tenantId: string): Promise<void> {
    const cuotas = await this.cuotaRepo.findByTenant(tenantId);
    const cuota = cuotas.find(c => c.id === id);

    if (!cuota) {
      throw new NotFoundException(`Cuota ${id} no encontrada en este tenant`);
    }

    const pagos = await this.pagoRepo.findByCuota(id);
    if (pagos.length > 0) {
      throw new BadRequestException('No se puede eliminar una cuota que tiene pagos registrados. Debe eliminar el pago primero.');
    }

    if (cuota.montoPagado > 0) {
      throw new BadRequestException('No se puede eliminar una cuota que tiene un monto pagado mayor a 0.');
    }

    await this.cuotaRepo.delete(id);
    this.logger.log(`Cuota eliminada: ${id}`);
  }
}
