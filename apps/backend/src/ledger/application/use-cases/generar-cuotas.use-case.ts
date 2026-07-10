import { Injectable, Logger } from '@nestjs/common';
import { CuentaCarteraRepository } from '../../infrastructure/persistence/cuenta-cartera.repository';
import { CuotaRepository } from '../../infrastructure/persistence/cuota.repository';
import { TarifaRepository } from '../../infrastructure/persistence/tarifa.repository';
import { Cuota } from '../../domain/cuota.entity';
import { CuentaDeCartera } from '../../domain/cuenta-de-cartera.entity';
import { Periodo, Money } from '../../../shared/common/value-objects';

function parseLocalDate(dateStr: string): Date {
  const [y, m, d] = dateStr.split('-').map(Number);
  return new Date(y, m - 1, d);
}

function toLocalDate(year: number, month: number, day: number): Date {
  return new Date(year, month, day);
}

export interface GenerarCuotasResult {
  generated: number;
  detalles: string[];
}

/**
 * Genera cuotas mensuales para cuentas de cartera activas.
 *
 * Regla de negocio:
 * - El día 1 de cada mes se crea UN solo registro de cuota por propietario.
 * - El monto es la tarifa mensual completa ($40.000 por casa, editable por admin).
 * - SEMANAL / QUINCENAL / MENSUAL define cuántos abonos parciales se esperan (4, 2, 1)
 *   pero todos se acumulan en el mismo registro mensual (montoPagado, estado PARCIAL).
 */
@Injectable()
export class GenerarCuotasUseCase {
  private readonly logger = new Logger(GenerarCuotasUseCase.name);

  constructor(
    private readonly cuentaCarteraRepository: CuentaCarteraRepository,
    private readonly cuotaRepository: CuotaRepository,
    private readonly tarifaRepository: TarifaRepository,
  ) {}

  async execute(
    tenantId: string,
    conjuntoId?: string,
  ): Promise<GenerarCuotasResult> {
    const detalles: string[] = [];
    let generated = 0;

    let cuentas: CuentaDeCartera[];

    if (conjuntoId) {
      cuentas = await this.cuentaCarteraRepository.findByConjunto(conjuntoId);
    } else {
      const allAccounts =
        await this.cuentaCarteraRepository.findAllByTenant(tenantId);
      cuentas = allAccounts.filter((a) => a.activa);
    }

    this.logger.log(
      `Found ${cuentas.length} active cuentas${conjuntoId ? ` for conjunto ${conjuntoId}` : ` for tenant ${tenantId}`}`,
    );
    detalles.push(`Cuentas activas encontradas: ${cuentas.length}`);

    for (const cuenta of cuentas) {
      try {
        const result = await this.generarCuotaMensual(cuenta);
        if (result) {
          generated += result;
          detalles.push(
            `Cuenta ${cuenta.propietarioId}: cuota mensual generada`,
          );
        }
      } catch (error) {
        const message =
          error instanceof Error ? error.message : 'Error desconocido';
        this.logger.error(
          `Error generando cuota para cuenta ${cuenta.id}: ${message}`,
        );
        detalles.push(`Cuenta ${cuenta.propietarioId}: Error - ${message}`);
      }
    }

    return { generated, detalles };
  }

  private async generarCuotaMensual(cuenta: CuentaDeCartera): Promise<number> {
    const hoy = new Date();
    const ultimaCuota = await this.cuotaRepository.findUltimaPorPropietario(
      cuenta.propietarioId,
    );

    let cursor: Date;
    if (!ultimaCuota) {
      const activacion = parseLocalDate(cuenta.fechaActivacion);
      cursor = toLocalDate(activacion.getFullYear(), activacion.getMonth(), 1);
    } else {
      cursor = parseLocalDate(ultimaCuota.periodoFin);
    }

    const periodo = Periodo.calcularCuotaMensual(cursor);
    const limite = Periodo.limiteGeneracion(undefined, hoy);

    if (periodo.inicio > limite) {
      return 0;
    }

    const yaExiste = await this.cuotaRepository.existsForPropietarioAndPeriodo(
      cuenta.propietarioId,
      periodo.inicioStr,
    );
    if (yaExiste) {
      return 0;
    }

    const created = await this.crearCuotaMensual(cuenta, periodo);
    return created ? 1 : 0;
  }

  private async crearCuotaMensual(
    cuenta: CuentaDeCartera,
    periodo: Periodo,
  ): Promise<boolean> {
    const tarifaMensual = await this.tarifaRepository.findVigente(
      cuenta.conjuntoId,
      'MENSUAL',
      periodo.inicio,
    );

    if (!tarifaMensual) {
      this.logger.warn(
        `No se encontró tarifa mensual vigente para conjunto ${cuenta.conjuntoId} ` +
          `en fecha ${periodo.inicioStr}`,
      );
      return false;
    }

    const concepto = Periodo.formatConceptoCuotaMensual(periodo);

    const cuota = Cuota.crear(
      cuenta.propietarioId,
      cuenta.tenantId,
      concepto,
      Money.ofCOP(tarifaMensual.monto),
      periodo.inicioStr,
      periodo.finStr,
      periodo.vencimientoStr,
      tarifaMensual.id,
    );

    await this.cuotaRepository.save(cuota);
    return true;
  }
}
