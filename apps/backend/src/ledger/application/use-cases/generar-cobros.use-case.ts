import { Injectable, Logger } from '@nestjs/common';
import { CobroRepository } from '../../infrastructure/persistence/cobro.repository';
import { PlanDeCobroRepository } from '../../infrastructure/persistence/plan-de-cobro.repository';
import { PeriodoCobroRepository } from '../../infrastructure/persistence/periodo-cobro.repository';
import { TarifaRepository } from '../../infrastructure/persistence/tarifa.repository';
import { Periodo, Money, pagosPorMes } from '../../../shared/common/value-objects';
import type { ModalidadRecaudo } from '../../../shared/common/value-objects';
import { Cobro } from '../../domain/cobro.entity';
import { PeriodoCobro } from '../../domain/periodo-cobro.entity';

@Injectable()
export class GenerarCobrosUseCase {
  private readonly logger = new Logger(GenerarCobrosUseCase.name);

  constructor(
    private readonly cobroRepository: CobroRepository,
    private readonly planDeCobroRepository: PlanDeCobroRepository,
    private readonly periodoCobroRepository: PeriodoCobroRepository,
    private readonly tarifaRepository: TarifaRepository,
  ) {}

  async execute(): Promise<{ generados: number }> {
    this.logger.log('Generando cobros para planes activos...');

    const hoy = new Date();
    const currentMes = hoy.getMonth() + 1; // 1-indexed
    const currentAnio = hoy.getFullYear();

    const planes = await this.planDeCobroRepository.findAllActivos();
    this.logger.log(`${planes.length} plan(es) activo(s) encontrado(s)`);

    let generados = 0;

    for (const plan of planes) {
      try {
        let actAnio = currentAnio;
        let actMes = currentMes;

        if (plan.fechaActivacion) {
          const parts = plan.fechaActivacion.split('-');
          if (parts.length >= 2) {
            actAnio = parseInt(parts[0], 10) || currentAnio;
            actMes = parseInt(parts[1], 10) || currentMes;
          }
        }

        // Limit catch-up to max 12 months ago to prevent runaway loops if date is ancient
        const minDate = new Date(currentAnio - 1, currentMes - 1, 1);
        const startIterDate = new Date(actAnio, actMes - 1, 1);
        let iterAnio = actAnio;
        let iterMes = actMes;
        if (startIterDate < minDate) {
          iterAnio = minDate.getFullYear();
          iterMes = minDate.getMonth() + 1;
        }

        while (
          iterAnio < currentAnio ||
          (iterAnio === currentAnio && iterMes <= currentMes)
        ) {
          const generado = await this.generarCobrosParaPlan(plan, iterMes, iterAnio, hoy);
          generados += generado;

          iterMes++;
          if (iterMes > 12) {
            iterMes = 1;
            iterAnio++;
          }
        }
      } catch (error) {
        const message = error instanceof Error ? error.message : 'Error desconocido';
        this.logger.error(`Error generando cobros para plan ${plan.id}: ${message}`);
      }
    }

    this.logger.log(`${generados} cobro(s) generado(s)`);
    return { generados };
  }

  async generarCobrosParaPlan(
    plan: import('../../domain/plan-de-cobro.entity').PlanDeCobro,
    mes: number,
    anio: number,
    hoy: Date,
  ): Promise<number> {
    // 1. Idempotencia: si ya existe PeriodoCobro para este mes, saltar
    const periodoExistente = await this.periodoCobroRepository.findByPlanAndMonth(
      plan.id,
      mes,
      anio,
    );
    if (periodoExistente) {
      this.logger.debug(`PeriodoCobro ya existe para plan ${plan.id} — ${anio}-${mes}`);
      return 0;
    }

    // 2. Obtener fechas de cobro según la modalidad (antes de la tarifa,
    //    porque la tarifa debe evaluarse en la fecha real del cobro).
    const modalidad: ModalidadRecaudo = plan.modalidad;
    const fechasCobro = Periodo.fechasCobroParciales(modalidad, anio, mes - 1);

    // Filtrar fechas de cobro anteriores a la fecha de activación del plan,
    // para evitar cobros retroactivos en el mes de ingreso.
    const fechasFiltradas = fechasCobro.filter(
      (fechaStr) => fechaStr >= plan.fechaActivacion,
    );

    // Sin cuota en este período → no crear período ni cobros.
    if (fechasFiltradas.length === 0) {
      return 0;
    }

    // 2b. Obtener tarifa vigente PARA LA FECHA DE VENCIMIENTO REAL del primer
    //    cobro del período (no una fecha arbitraria). Si el admin crea una
    //    tarifa el día 29 con vigencia 29, esa tarifa rige la cuota que vence
    //    el 29; antes (fecha fija día 15) se omitía todo el mes.
    const diaPrimerCobro = Number(fechasFiltradas[0].slice(8, 10));
    const fechaRefTarifa = new Date(anio, mes - 1, diaPrimerCobro);
    const tarifa = await this.tarifaRepository.findVigente(
      plan.proyectoId,
      modalidad,
      fechaRefTarifa,
    );

    // 3. Calcular valor total del mes
    //    Prioridad: plan.valorMensual > tarifa vigente
    let valorMensualCentavos: number;
    if (plan.valorMensual != null && plan.valorMensual > 0) {
      valorMensualCentavos = plan.valorMensual;
    } else if (tarifa) {
      valorMensualCentavos = tarifa.monto * pagosPorMes(modalidad);
    } else {
      this.logger.warn(
        `Sin tarifa vigente ni valorMensual para plan ${plan.id}. Se omite.`,
      );
      return 0;
    }

    // 4. Crear fechas del período
    const fechaInicio = `${anio}-${String(mes).padStart(2, '0')}-01`;
    const ultimoDia = new Date(anio, mes, 0).getDate();
    const fechaFin = `${anio}-${String(mes).padStart(2, '0')}-${String(ultimoDia).padStart(2, '0')}`;

    // 5. Persistir PeriodoCobro primero (para obtener su ID)
    const periodo = PeriodoCobro.crear(
      plan.id,
      mes,
      anio,
      fechaInicio,
      fechaFin,
      plan.tenantId,
    );
    const periodoGuardado = await this.periodoCobroRepository.save(periodo);

    // 6. Obtener fechas de cobro según la modalidad
    const totalPagos = pagosPorMes(modalidad);
    const montoPorCobro = Math.round(valorMensualCentavos / totalPagos);

    const hoyStr = hoy.toISOString().split('T')[0];

    // 7. Crear los cobros individuales con periodoId asignado
    const cobrosAGuardar: Cobro[] = fechasFiltradas.map((fechaStr) => {
      const cobro = Cobro.crear(
        plan.residenteId,
        plan.tenantId,
        'Cuota de Vigilancia',
        Money.ofCOP(montoPorCobro),
        fechaInicio,
        fechaFin,
        fechaStr, // fechaVencimiento = fecha de cobro parcial
        tarifa?.id,
        periodoGuardado.id, // periodoId del PeriodoCobro persistido
        plan.casaId ?? undefined,
      );

      // Si la fecha de vencimiento es anterior a la fecha actual, marcar como VENCIDA
      if (fechaStr < hoyStr) {
        cobro.marcarVencida();
      }

      return cobro;
    });

    // 8. Persistir cobros
    if (cobrosAGuardar.length > 0) {
      await this.cobroRepository.saveMany(cobrosAGuardar);
      this.logger.log(
        `Plan ${plan.id}: ${cobrosAGuardar.length} cobro(s) generado(s) para ${anio}-${mes} (${modalidad})`,
      );
    }

    return cobrosAGuardar.length;
  }
}
