import { Injectable } from '@nestjs/common';
import { Tarifa } from '../../domain/tarifa.entity';
import { TarifaRepository } from '../../infrastructure/persistence/tarifa.repository';
import {
  ModalidadRecaudo,
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
    proyectoId: string,
    tenantId: string,
    modalidadOrigen: ModalidadRecaudo,
    montoCentavos: number,
    fechaVigencia: string,
  ): Promise<Tarifa[]> {
    const montoMensual = montoMensualDesde(modalidadOrigen, montoCentavos);
    const derivadas = tarifasDerivadas(montoMensual);
    const creadas: Tarifa[] = [];

    for (const modalidad of ['SEMANAL', 'QUINCENAL', 'MENSUAL'] as ModalidadRecaudo[]) {
      await this.desactivarFuturas(proyectoId, tenantId, modalidad, fechaVigencia);
      const tarifa = Tarifa.crear(
        proyectoId,
        tenantId,
        modalidad,
        Money.ofCOP(derivadas[modalidad]),
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
    proyectoId: string,
    tenantId: string,
    modalidadOrigen: ModalidadRecaudo,
    montoCentavos: number,
  ): Promise<Tarifa[]> {
    const montoMensual = montoMensualDesde(modalidadOrigen, montoCentavos);
    const derivadas = tarifasDerivadas(montoMensual);
    const actualizadas: Tarifa[] = [];

    const todas = await this.tarifaRepository.findAll(tenantId, proyectoId);

    for (const modalidad of ['SEMANAL', 'QUINCENAL', 'MENSUAL'] as ModalidadRecaudo[]) {
      const activa = todas.find((t) => t.activa && t.modalidad === modalidad);
      if (activa) {
        activa.monto = derivadas[modalidad];
        actualizadas.push(await this.tarifaRepository.save(activa));
      }
    }

    return actualizadas;
  }

  private async desactivarFuturas(
    proyectoId: string,
    tenantId: string,
    modalidad: ModalidadRecaudo,
    fechaVigencia: string,
  ): Promise<void> {
    const existentes = await this.tarifaRepository.findAll(tenantId, proyectoId);
    for (const t of existentes) {
      if (
        t.activa &&
        t.modalidad === modalidad &&
        t.fechaVigencia >= fechaVigencia
      ) {
        t.desactivar();
        await this.tarifaRepository.save(t);
      }
    }
  }
}
