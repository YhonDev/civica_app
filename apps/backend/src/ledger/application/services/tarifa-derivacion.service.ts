import { Injectable } from '@nestjs/common';
import { Tarifa } from '../../domain/tarifa.entity';
import { TarifaRepository } from '../../infrastructure/persistence/tarifa.repository';
import {
  Frecuencia,
  Money,
  montoMensualDesde,
  tarifasDerivadas,
} from '../../../shared/common/value-objects';

/**
 * Mantiene las 3 tarifas (SEMANAL/QUINCENAL/MENSUAL) sincronizadas
 * a partir de la cuota cívica mensual.
 */
@Injectable()
export class TarifaDerivacionService {
  constructor(private readonly tarifaRepository: TarifaRepository) {}

  /**
   * Crea nuevas versiones de las 3 tarifas al configurar una tarifa.
   * Desactiva futuras activas con la misma fecha de vigencia o posterior.
   */
  async crearVersiones(
    conjuntoId: string,
    tenantId: string,
    frecuenciaOrigen: Frecuencia,
    montoCentavos: number,
    fechaVigencia: string,
  ): Promise<Tarifa[]> {
    const montoMensual = montoMensualDesde(frecuenciaOrigen, montoCentavos);
    const derivadas = tarifasDerivadas(montoMensual);
    const creadas: Tarifa[] = [];

    for (const frecuencia of ['SEMANAL', 'QUINCENAL', 'MENSUAL'] as Frecuencia[]) {
      await this.desactivarFuturas(conjuntoId, tenantId, frecuencia, fechaVigencia);
      const tarifa = Tarifa.crear(
        conjuntoId,
        tenantId,
        frecuencia,
        Money.ofCOP(derivadas[frecuencia]),
        fechaVigencia,
      );
      creadas.push(await this.tarifaRepository.save(tarifa));
    }

    return creadas;
  }

  /**
   * Actualiza los montos de las 3 tarifas activas vigentes en el conjunto.
   * Se usa cuando el admin modifica el valor de la cuota.
   */
  async actualizarActivas(
    conjuntoId: string,
    tenantId: string,
    frecuenciaOrigen: Frecuencia,
    montoCentavos: number,
  ): Promise<Tarifa[]> {
    const montoMensual = montoMensualDesde(frecuenciaOrigen, montoCentavos);
    const derivadas = tarifasDerivadas(montoMensual);
    const actualizadas: Tarifa[] = [];

    const todas = await this.tarifaRepository.findAll(tenantId, conjuntoId);

    for (const frecuencia of ['SEMANAL', 'QUINCENAL', 'MENSUAL'] as Frecuencia[]) {
      const activa = todas.find((t) => t.activa && t.frecuencia === frecuencia);
      if (activa) {
        activa.monto = derivadas[frecuencia];
        actualizadas.push(await this.tarifaRepository.save(activa));
      }
    }

    return actualizadas;
  }

  private async desactivarFuturas(
    conjuntoId: string,
    tenantId: string,
    frecuencia: Frecuencia,
    fechaVigencia: string,
  ): Promise<void> {
    const existentes = await this.tarifaRepository.findAll(tenantId, conjuntoId);
    for (const t of existentes) {
      if (
        t.activa &&
        t.frecuencia === frecuencia &&
        t.fechaVigencia >= fechaVigencia
      ) {
        t.desactivar();
        await this.tarifaRepository.save(t);
      }
    }
  }
}
