import { Injectable } from '@nestjs/common';
import { PropietarioRepository } from '../../infrastructure/propietario.repository';
import { CuotaRepository } from '../../../ledger/infrastructure/persistence/cuota.repository';
import { PagoRepository } from '../../../ledger/infrastructure/persistence/pago.repository';
import { TarifaRepository } from '../../../ledger/infrastructure/persistence/tarifa.repository';
import { PropietarioDetailResponse, MovimientoItem } from '../dtos/propietario-detail.dto';

@Injectable()
export class PropietarioDetailQuery {
  constructor(
    private readonly propietarioRepo: PropietarioRepository,
    private readonly cuotaRepo: CuotaRepository,
    private readonly pagoRepo: PagoRepository,
    private readonly tarifaRepo: TarifaRepository,
  ) {}

  async execute(
    propietarioId: string,
    tenantId: string,
  ): Promise<PropietarioDetailResponse> {
    const [propietario, cuotas, pagos] = await Promise.all([
      this.propietarioRepo.findWithTenencia(propietarioId),
      this.cuotaRepo.findByPropietario(propietarioId),
      this.pagoRepo.findByPropietario(propietarioId),
    ]);

    if (!propietario) {
      throw new Error('Propietario no encontrado');
    }

    const tenencia = propietario.tenencias?.[0];
    const casa = tenencia?.casa;
    const manzana = casa?.manzana;
    const etapa = manzana?.etapa;

    // 1. Calcular Saldo Pendiente
    const saldoPendiente = cuotas.reduce((sum: number, c: any) => sum + (c.monto - c.montoPagado), 0);
    const estadoFinanciero = saldoPendiente > 0 ? 'EN MORA' : 'AL DÍA';

    // 2. Determinar Modalidad (desde la primera cuota)
    let modalidad = 'MENSUAL';
    const primeraCuota = cuotas[0];
    if (primeraCuota?.tarifaId) {
      const tarifa = await this.tarifaRepo.findById(primeraCuota.tarifaId);
      modalidad = tarifa?.frecuencia || 'MENSUAL';
    }

    // 3. Calcular Próximo Vencimiento
    const proximoVencimiento = this.calcularProximoVencimiento(cuotas, modalidad);

    // 4. Construir Movimientos (Timeline)
    const movimientos = this.construirMovimientos(cuotas, pagos);

    return {
      id: propietario.id,
      nombre: propietario.nombre,
      casa: casa ? `${casa.direccionInterna}, Mz. ${manzana?.nombre}` : 'Sin dirección',
      etapa: etapa?.nombre || 'Sin etapa',
      saldoPendiente,
      estadoFinanciero,
      modalidadPago: modalidad,
      proximoVencimiento,
      movimientos,
    };
  }

  private calcularProximoVencimiento(cuotas: any[], modalidad: string): string {
    const sortedCuotas = [...cuotas].sort((a, b) => 
      new Date(b.periodoInicio).getTime() - new Date(a.periodoInicio).getTime()
    );
    
    const ultimaCuota = sortedCuotas[0];
    if (!ultimaCuota) return 'No definido';

    const fechaVencimiento = new Date(ultimaCuota.fechaVencimiento);
    
    if (ultimaCuota.estado === 'PAGADA') {
      const nextDate = new Date(fechaVencimiento);
      if (modalidad === 'MENSUAL') nextDate.setMonth(nextDate.getMonth() + 1);
      else if (modalidad === 'QUINCENAL') nextDate.setDate(nextDate.getDate() + 15);
      else if (modalidad === 'SEMANAL') nextDate.setDate(nextDate.getDate() + 7);
      
      return this.formatSpanishDate(nextDate);
    }

    return this.formatSpanishDate(fechaVencimiento);
  }

  private construirMovimientos(cuotas: any[], pagos: any[]): MovimientoItem[] {
    return cuotas
      .sort((a, b) => new Date(b.periodoInicio).getTime() - new Date(a.periodoInicio).getTime())
      .slice(0, 6)
      .map(c => ({
        mes: this.formatSpanishMonth(new Date(c.periodoInicio)),
        pagado: c.estado === 'PAGADA',
        monto: c.monto,
        fecha: c.fechaVencimiento,
      }));
  }

  private formatSpanishDate(date: Date): string {
    return new Intl.DateTimeFormat('es-ES', {
      day: 'numeric',
      month: 'long',
    }).format(date);
  }

  private formatSpanishMonth(date: Date): string {
    return new Intl.DateTimeFormat('es-ES', { month: 'long' }).format(date);
  }
}
