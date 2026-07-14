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
    const mes = hoy.getMonth() + 1; // 1-indexed
    const anio = hoy.getFullYear();

    const planes = await this.planDeCobroRepository.findAllActivos();
    this.logger.log(`${planes.length} plan(es) activo(s) encontrado(s)`);

    let generados = 0;

    for (const plan of planes) {
      try {
        const generado = await this.generarCobrosParaPlan(plan, mes, anio, hoy);
        generados += generado;
      } catch (error) {
        const message = error instanceof Error ? error.message : 'Error desconocido';
        this.logger.error(`Error generando cobros para plan ${plan.id}: ${message}`);
      }
    }

    this.logger.log(`${generados} cobro(s) generado(s)`);
    return { generados };
  }

  private async generarCobrosParaPlan(
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

    // 2. Obtener tarifa vigente
    const modalidad: ModalidadRecaudo = plan.modalidad;
    const tarifa = await this.tarifaRepository.findVigente(
      plan.proyectoId,
      modalidad,
      hoy,
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
    const fechasCobro = Periodo.fechasCobroParciales(modalidad, anio, mes - 1);
    const totalPagos = pagosPorMes(modalidad);
    const montoPorCobro = Math.round(valorMensualCentavos / totalPagos);

    // 7. Crear los cobros individuales con periodoId asignado
    const cobrosAGuardar: Cobro[] = fechasCobro.map((fechaStr) =>
      Cobro.crear(
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
      ),
    );

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
