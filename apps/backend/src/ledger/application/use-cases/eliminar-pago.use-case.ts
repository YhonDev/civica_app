import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { PagoRepository } from '../../infrastructure/persistence/pago.repository';
import { CobroRepository } from '../../infrastructure/persistence/cobro.repository';

@Injectable()
export class EliminarPagoUseCase {
  private readonly logger = new Logger(EliminarPagoUseCase.name);

  constructor(
    private readonly pagoRepo: PagoRepository,
    private readonly cobroRepo: CobroRepository,
  ) {}

  async execute(id: string, tenantId: string): Promise<void> {
    const pago = await this.pagoRepo.findById(id);

    if (!pago || pago.tenantId !== tenantId) {
      throw new NotFoundException(`Pago ${id} no encontrado`);
    }

    // Revertir el pago aplicando LIFO inverso
    let remainingToReverse = pago.monto;
    const cobros = await this.cobroRepo.findByResidente(pago.residenteId);
    
    // Sort cobros by periodoInicio DESC (newest first)
    cobros.sort((a, b) => new Date(b.periodoInicio).getTime() - new Date(a.periodoInicio).getTime());

    const cobrosActualizados = [];

    for (const cobro of cobros) {
      if (remainingToReverse <= 0) break;
      
      if (cobro.montoPagado > 0) {
        const amountToSubtract = Math.min(cobro.montoPagado, remainingToReverse);
        cobro.montoPagado -= amountToSubtract;
        remainingToReverse -= amountToSubtract;
        
        // Recalcular estado
        if (cobro.montoPagado === 0) {
          if (new Date(cobro.fechaVencimiento).getTime() < new Date().getTime()) {
            cobro.estado = 'VENCIDA';
          } else {
            cobro.estado = 'PENDIENTE';
          }
        } else if (cobro.montoPagado < cobro.monto) {
          cobro.estado = 'PARCIAL';
        }
        
        cobrosActualizados.push(cobro);
      }
    }

    // Guardar cobros revertidos
    if (cobrosActualizados.length > 0) {
      await this.cobroRepo.saveMany(cobrosActualizados);
    }

    // Eliminar el pago
    await this.pagoRepo.delete(id);
    
    this.logger.log(`Pago eliminado: ${id} | Monto revertido: ${pago.monto - remainingToReverse} centavos`);
  }
}
