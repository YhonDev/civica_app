import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { PagoRepository } from '../../infrastructure/persistence/pago.repository';
import { CuotaRepository } from '../../infrastructure/persistence/cuota.repository';

@Injectable()
export class EliminarPagoUseCase {
  private readonly logger = new Logger(EliminarPagoUseCase.name);

  constructor(
    private readonly pagoRepo: PagoRepository,
    private readonly cuotaRepo: CuotaRepository,
  ) {}

  async execute(id: string, tenantId: string): Promise<void> {
    const pago = await this.pagoRepo.findById(id);

    if (!pago || pago.tenantId !== tenantId) {
      throw new NotFoundException(`Pago ${id} no encontrado`);
    }

    // Revertir el pago: restamos el monto pagado de las cuotas del propietario
    // en orden LIFO (las más recientes primero, ya que el pago se aplicó FIFO a las más antiguas).
    let remainingToReverse = pago.monto;
    const cuotas = await this.cuotaRepo.findByPropietario(pago.propietarioId);
    
    // Sort cuotas by periodoInicio DESC (newest first)
    cuotas.sort((a, b) => new Date(b.periodoInicio).getTime() - new Date(a.periodoInicio).getTime());

    const cuotasActualizadas = [];

    for (const cuota of cuotas) {
      if (remainingToReverse <= 0) break;
      
      if (cuota.montoPagado > 0) {
        const amountToSubtract = Math.min(cuota.montoPagado, remainingToReverse);
        cuota.montoPagado -= amountToSubtract;
        remainingToReverse -= amountToSubtract;
        
        // Recalcular estado
        if (cuota.montoPagado === 0) {
          // Evaluar si está vencida
          if (new Date(cuota.fechaVencimiento).getTime() < new Date().getTime()) {
            cuota.estado = 'VENCIDA';
          } else {
            cuota.estado = 'PENDIENTE';
          }
        } else if (cuota.montoPagado < cuota.monto) {
          cuota.estado = 'PARCIAL';
        }
        
        cuotasActualizadas.push(cuota);
      }
    }

    // Guardar cuotas revertidas
    if (cuotasActualizadas.length > 0) {
      await this.cuotaRepo.saveMany(cuotasActualizadas);
    }

    // Eliminar el pago
    await this.pagoRepo.delete(id);
    
    this.logger.log(`Pago eliminado: ${id} | Monto revertido: ${pago.monto - remainingToReverse} centavos`);
  }
}
