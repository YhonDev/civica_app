import { Injectable, Logger } from '@nestjs/common';
import { CuentaCarteraRepository } from '../../infrastructure/persistence/cuenta-cartera.repository';
import { CuotaRepository } from '../../infrastructure/persistence/cuota.repository';
import { TarifaRepository } from '../../infrastructure/persistence/tarifa.repository';
import { Cuota } from '../../domain/cuota.entity';
import { CuentaDeCartera } from '../../domain/cuenta-de-cartera.entity';
import { Periodo, Money } from '../../../shared/common/value-objects';

export interface GenerarCuotasResult {
  generated: number;
  detalles: string[];
}

/**
 * Genera cuotas para cuentas de cartera activas.
 *
 * Core business logic:
 * - For each active CuentaDeCartera (filtered by tenant and optionally conjuntoId)
 * - Find the latest cuota to know the last period
 * - If no cuotas exist, start from fechaActivacion
 * - Calculate the next period using Periodo.calcularSiguiente
 * - Find the vigente tarifa for this conjunto+frecuencia
 * - Create cuota with the tarifa's monto
 *
 * Key rule: changes to tarifa only affect future cuotas.
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

    // Step 1: Find all active CuentaDeCartera
    let cuentas: CuentaDeCartera[];

    if (conjuntoId) {
      cuentas = await this.cuentaCarteraRepository.findByConjunto(conjuntoId);
    } else {
      // Get all accounts for tenant, then filter active ones
      const allAccounts =
        await this.cuentaCarteraRepository.findAllByTenant(tenantId);
      cuentas = allAccounts.filter((a) => a.activa);
    }

    this.logger.log(
      `Found ${cuentas.length} active cuentas${conjuntoId ? ` for conjunto ${conjuntoId}` : ` for tenant ${tenantId}`}`,
    );
    detalles.push(`Cuentas activas encontradas: ${cuentas.length}`);

    // Step 2: For each account, generate the next cuota
    for (const cuenta of cuentas) {
      try {
        const result = await this.generarCuotaParaCuenta(cuenta);
        if (result) {
          generated += result;
          detalles.push(
            `Cuenta ${cuenta.propietarioId}: ${result} cuota(s) generada(s)`,
          );
        }
      } catch (error) {
        const message =
          error instanceof Error ? error.message : 'Error desconocido';
        this.logger.error(
          `Error generando cuotas para cuenta ${cuenta.id}: ${message}`,
        );
        detalles.push(`Cuenta ${cuenta.propietarioId}: Error - ${message}`);
      }
    }

    return { generated, detalles };
  }

  private async generarCuotaParaCuenta(
    cuenta: CuentaDeCartera,
  ): Promise<number> {
    // Step 2a: Find the latest cuota for this propietario
    const ultimaCuota =
      await this.cuotaRepository.findUltimaPorPropietario(
        cuenta.propietarioId,
      );

    // Step 2b-2c: Determine the period
    let periodoInicio: Date;

    if (!ultimaCuota) {
      // No cuotas exist yet — start from fechaActivacion
      periodoInicio = new Date(cuenta.fechaActivacion);
    } else {
      // Start from the end of the last period
      periodoInicio = new Date(ultimaCuota.periodoFin);
    }

    // Step 2c: Calculate the next period
    const periodo = Periodo.calcularSiguiente(
      cuenta.frecuencia,
      periodoInicio,
    );

    // Step 2d: Find the vigente tarifa for this conjunto+frecuencia
    const tarifa = await this.tarifaRepository.findVigente(
      cuenta.conjuntoId,
      cuenta.frecuencia,
      periodo.inicio,
    );

    if (!tarifa) {
      this.logger.warn(
        `No se encontró tarifa vigente para conjunto ${cuenta.conjuntoId}, ` +
          `frecuencia ${cuenta.frecuencia} en fecha ${periodo.inicio.toISOString().split('T')[0]}`,
      );
      return 0;
    }

    // Build concepto
    const fechaInicioStr = periodo.inicio.toISOString().split('T')[0];
    const fechaFinStr = periodo.fin.toISOString().split('T')[0];
    const vencimientoStr = periodo.vencimiento.toISOString().split('T')[0];
    const concepto = `Cuota ${cuenta.frecuencia.toLowerCase()} ${fechaInicioStr} al ${fechaFinStr}`;

    // Step 2e: Create Cuota
    const cuota = Cuota.crear(
      cuenta.propietarioId,
      cuenta.tenantId,
      concepto,
      tarifa.getMonto(),
      fechaInicioStr,
      fechaFinStr,
      vencimientoStr,
      tarifa.id,
    );

    await this.cuotaRepository.save(cuota);
    return 1;
  }
}
