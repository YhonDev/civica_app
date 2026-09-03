import { Injectable, Logger } from '@nestjs/common';
import { PlanDeCobroRepository } from '../../infrastructure/persistence/plan-de-cobro.repository';
import { PeriodoCobroRepository } from '../../infrastructure/persistence/periodo-cobro.repository';
import { CobroRepository } from '../../infrastructure/persistence/cobro.repository';
import { TarifaRepository } from '../../infrastructure/persistence/tarifa.repository';
import {
  Periodo,
  Money,
  pagosPorMes,
} from '../../../shared/common/value-objects';
import type { ModalidadRecaudo } from '../../../shared/common/value-objects';
import { Cobro } from '../../domain/cobro.entity';
import { EventsGateway } from '../../../notifications/events.gateway';

@Injectable()
export class ReconciliarModalidadUseCase {
  private readonly logger = new Logger(ReconciliarModalidadUseCase.name);

  constructor(
    private readonly planDeCobroRepository: PlanDeCobroRepository,
    private readonly periodoCobroRepository: PeriodoCobroRepository,
    private readonly cobroRepository: CobroRepository,
    private readonly tarifaRepository: TarifaRepository,
    private readonly eventsGateway?: EventsGateway,
  ) {}

  async execute(
    residenteId: string,
    nuevaModalidad: ModalidadRecaudo,
  ): Promise<void> {
    this.logger.log(
      `Iniciando reconciliación de modalidad a ${nuevaModalidad} para residente ${residenteId}`,
    );

    const plan = await this.planDeCobroRepository.findByResidente(residenteId);
    if (!plan) {
      this.logger.warn(
        `No se encontró plan de cobro activo para residente ${residenteId}`,
      );
      return;
    }

    // 1. Actualizar modalidad del plan
    plan.modalidad = nuevaModalidad;
    await this.planDeCobroRepository.save(plan);

    // 2. Obtener mes y año actual
    const hoy = new Date();
    const currentMes = hoy.getMonth() + 1;
    const currentAnio = hoy.getFullYear();

    // 3. Buscar periodo de cobro del mes actual
    const periodo = await this.periodoCobroRepository.findByPlanAndMonth(
      plan.id,
      currentMes,
      currentAnio,
    );
    if (!periodo) {
      this.logger.log(
        `No hay periodo de cobro generado en el mes actual (${currentAnio}-${currentMes}) para plan ${plan.id}`,
      );
      return;
    }

    // 4. Obtener cobros existentes en este período
    const cobrosExistentes = await this.cobroRepository.findByResidente(
      residenteId,
      plan.tenantId,
    );
    const cobrosDelMes = cobrosExistentes.filter(
      (c) => c.periodoId === periodo.id && c.estado !== 'ANULADO',
    );

    if (cobrosDelMes.length === 0) {
      return;
    }

    // 5. Calcular el dinero acumulado total pagado por el residente en este período
    let totalPagadoCentavos = 0;
    for (const c of cobrosDelMes) {
      totalPagadoCentavos += c.montoPagado ?? 0;
    }

    // 6. Eliminar los cobros viejos del mes actual para reestructurarlos
    for (const c of cobrosDelMes) {
      await this.cobroRepository.delete(c.id);
    }

    // 7. Reestructurar nuevas fechas de cobro
    const fechasCobro = Periodo.fechasCobroParciales(
      nuevaModalidad,
      currentAnio,
      currentMes - 1,
    );
    const fechasFiltradas = fechasCobro.filter(
      (fechaStr) => fechaStr >= plan.fechaActivacion,
    );

    if (fechasFiltradas.length === 0) {
      return;
    }

    // 8. Tarifa vigente para la fecha del primer cobro
    const diaPrimerCobro = Number(fechasFiltradas[0].slice(8, 10));
    const fechaRefTarifa = new Date(
      currentAnio,
      currentMes - 1,
      diaPrimerCobro,
    );
    const tarifa = await this.tarifaRepository.findVigente(
      plan.proyectoId,
      nuevaModalidad,
      fechaRefTarifa,
    );

    let valorMensualCentavos: number;
    if (plan.valorMensual != null && plan.valorMensual > 0) {
      valorMensualCentavos = plan.valorMensual;
    } else if (tarifa) {
      valorMensualCentavos = tarifa.monto * pagosPorMes(nuevaModalidad);
    } else {
      valorMensualCentavos = 4000000; // $40.000 COP fallback
    }

    const totalPagos = pagosPorMes(nuevaModalidad);
    const montoPorCobro = Math.round(valorMensualCentavos / totalPagos);

    const fechaInicio = `${currentAnio}-${String(currentMes).padStart(2, '0')}-01`;
    const ultimoDia = new Date(currentAnio, currentMes, 0).getDate();
    const fechaFin = `${currentAnio}-${String(currentMes).padStart(2, '0')}-${String(ultimoDia).padStart(2, '0')}`;

    const mesesEsp = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    const nombreMes = mesesEsp[currentMes - 1] ?? '';

    const hoyStr = hoy.toISOString().split('T')[0];
    let remanentePago = Money.ofCOP(totalPagadoCentavos);

    const nuevosCobros: Cobro[] = fechasFiltradas.map((fechaStr, index) => {
      const numCuota = index + 1;
      const conceptoStr = `${nombreMes} — Cuota ${numCuota}`;

      const cobro = Cobro.crear(
        residenteId,
        plan.tenantId,
        conceptoStr,
        Money.ofCOP(montoPorCobro),
        fechaInicio,
        fechaFin,
        fechaStr,
        tarifa?.id,
        periodo.id,
        plan.casaId ?? undefined,
      );

      // Reconciliación en cascada del saldo acumulado
      if (remanentePago.amount > 0) {
        remanentePago = cobro.aplicarPago(remanentePago);
      } else {
        if (fechaStr < hoyStr) {
          cobro.marcarVencida();
        }
      }

      return cobro;
    });

    await this.cobroRepository.saveMany(nuevosCobros);
    this.logger.log(
      `Reconciliación exitosa: ${nuevosCobros.length} cuota(s) reestructurada(s) para ${nuevaModalidad} con $${totalPagadoCentavos / 100} abonados previa/mente.`,
    );

    this.eventsGateway?.emitModalidadCambiada({
      tenantId: plan.tenantId,
      residenteId,
      nuevaModalidad,
    });
  }
}
