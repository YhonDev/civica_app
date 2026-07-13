import {
  Controller,
  Get,
  Query,
  UseGuards,
  ParseIntPipe,
  DefaultValuePipe,
} from '@nestjs/common';
import { DashboardQuery } from '../../application/queries/dashboard.query';
import { CuotaRepository } from '../persistence/cuota.repository';
import { PagoRepository } from '../persistence/pago.repository';
import { CuentaCarteraRepository } from '../persistence/cuenta-cartera.repository';
import { TarifaRepository } from '../persistence/tarifa.repository';
import { Periodo, type Frecuencia, pagosPorMes, calcularMontoParcial } from '../../../shared/common/value-objects';
import { JwtAuthGuard } from '../../../shared/auth/jwt-auth.guard';
import { RolesGuard } from '../../../shared/auth/guards/roles.guard';
import { Roles } from '../../../shared/auth/decorators/roles.decorator';
import { CurrentTenant } from '../../../shared/tenant/current-tenant.decorator';
import { CurrentUser } from '../../../shared/tenant/current-user.decorator';
import { RolUsuario, Usuario } from '../../../iam/domain/usuario.entity';
import { DataSource } from 'typeorm';

@Controller()
@UseGuards(JwtAuthGuard)
export class DashboardController {
  constructor(
    private readonly dashboardQuery: DashboardQuery,
    private readonly cuotaRepository: CuotaRepository,
    private readonly pagoRepository: PagoRepository,
    private readonly cuentaCarteraRepository: CuentaCarteraRepository,
    private readonly tarifaRepository: TarifaRepository,
    private readonly dataSource: DataSource,
  ) {}

  @Get('dashboard/administrador')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async getDashboard(
    @Query('mes', new DefaultValuePipe(new Date().getMonth() + 1), ParseIntPipe)
    mes: number,
    @Query('anio', new DefaultValuePipe(new Date().getFullYear()), ParseIntPipe)
    anio: number,
    @CurrentTenant() tenantId: string,
  ) {
    return this.dashboardQuery.execute(mes, anio, tenantId);
  }

  @Get('dashboard/cobrador')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.COBRADOR)
  async getDashboardCobrador(
    @CurrentUser() user: Usuario,
    @CurrentTenant() tenantId: string,
  ) {
    // 1. Obtener etapas asignadas al cobrador
    const asignaciones = await this.dataSource.query(
      'SELECT etapa_id FROM asignaciones_etapa WHERE usuario_id = $1',
      [user.id],
    );
    const etapaIds: string[] = asignaciones.map((a: any) => a.etapa_id);

    // 2. Cuotas pendientes en esas etapas
    const cuotas = etapaIds.length > 0
      ? await this.cuotaRepository.findPendientesConPropietarioByEtapas(tenantId, etapaIds)
      : [];

    // 3. Pagos del cobrador hoy
    const { pagos: pagosHoy, total: totalHoy, count: countHoy } =
      await this.pagoRepository.findByCobradorToday(user.id);

    // 4. Armar respuesta
    const viviendas = cuotas.map((c) => {
      const prop = c.propietario;
      const tenencia = prop?.tenencias?.[0];
      const casa = tenencia?.casa;
      const manzana = casa?.manzana;
      const etapa = manzana?.etapa;

      return {
        id: c.id,
        propietarioId: prop?.id ?? '',
        propietarioNombre: prop?.nombre ?? 'Desconocido',
        casaDireccion: casa ? `${casa.direccionInterna}${manzana ? `, Mz. ${manzana.nombre}` : ''}` : 'Sin dirección',
        etapaNombre: etapa?.nombre ?? 'Sin etapa',
        monto: Math.round(c.monto / 100),
        montoPagado: Math.round(c.montoPagado / 100),
        saldo: Math.round((c.monto - c.montoPagado) / 100),
        estado: c.estado,
        cuotaId: c.id,
        fechaVencimiento: c.fechaVencimiento,
      };
    });

    // Agrupar por propietario: mostrar el saldo total por visita
    const viviendasAgrupadas = new Map<string, typeof viviendas[0] & { saldoTotal: number }>();
    for (const v of viviendas) {
      const existing = viviendasAgrupadas.get(v.propietarioId);
      if (existing) {
        existing.saldoTotal += v.saldo;
      } else {
        viviendasAgrupadas.set(v.propietarioId, { ...v, saldoTotal: v.saldo });
      }
    }

    const montoEsperado = Array.from(viviendasAgrupadas.values()).reduce(
      (sum, v) => sum + v.saldoTotal, 0,
    );

    const ultimosCobros = pagosHoy.slice(0, 10).map((p) => ({
      id: p.id,
      propietarioNombre: p.propietarioId,
      monto: Math.round(p.monto / 100),
      fecha: p.fechaPago,
    }));

    return {
      cobrador: { nombre: user.nombre },
      stats: {
        pendientes: viviendasAgrupadas.size,
        montoEsperado,
        cobradosHoy: countHoy,
        montoCobradoHoy: Math.round(totalHoy / 100),
      },
      viviendas: Array.from(viviendasAgrupadas.values()),
      ultimosCobros,
    };
  }

  @Get('dashboard/propietario')
  async getDashboardPropietario(
    @CurrentUser() user: Usuario,
    @CurrentTenant() tenantId: string,
  ) {
    if (!user.propietarioId) {
      return {
        saldo: 0,
        status: 'AL_DIA',
        proximoCobro: null,
        ultimoPago: null,
        movimientos: [],
      };
    }

    const [cuotasRaw, pagos, cuenta] = await Promise.all([
      this.cuotaRepository.findByPropietario(user.propietarioId),
      this.pagoRepository.findByPropietario(user.propietarioId),
      this.cuentaCarteraRepository.findByPropietario(user.propietarioId),
    ]);

    const frecuencia: Frecuencia = cuenta?.frecuencia ?? 'MENSUAL';
    const hoy = new Date();

    let tarifaMensual: any = null;
    let tarifaPropia: any = null;
    if (cuenta) {
      const vigentes = await this.tarifaRepository.findVigentesPorConjunto(
        cuenta.conjuntoId,
        hoy,
      );
      tarifaMensual = vigentes.MENSUAL;
      tarifaPropia = vigentes[frecuencia];
    }

    const cuotas = cuotasRaw.filter((c) =>
      Periodo.esVisible(c.periodoInicio, frecuencia, hoy),
    );

    let saldo = 0;
    let hasVencida = false;
    for (const cuota of cuotas) {
      if (cuota.monto > cuota.montoPagado) {
        saldo += (cuota.monto - cuota.montoPagado);
        if (cuota.estado === 'VENCIDA') {
          hasVencida = true;
        }
      }
    }

    // Convert from cents (backend) to COP standard units (frontend)
    // Mobile UI expects raw values (e.g. 40000 COP, backend stores 4000000 cents)
    const saldoFrontend = Math.round(saldo / 100);

    const status = hasVencida
      ? 'MORA'
      : saldo > 0
        ? 'PENDIENTE'
        : 'AL_DIA';

    let proximoCobro: string | null = null;
    let proximoPago: {
      concepto: string;
      fechaVencimiento: string;
      monto: number;
      montoTotal: number;
      montoPagado: number;
      pagosEsperados: number;
      pagosRegistrados: number;
      montoParcial: number;
      desglose: {
        id: string;
        cuotaId: string;
        fecha: string;
        monto: number;
        numeroPago: number;
      }[];
    } | null = null;

    const pendingCuotas = cuotas.filter((c) => c.monto > c.montoPagado);
    if (pendingCuotas.length > 0) {
      pendingCuotas.sort((a, b) =>
        a.fechaVencimiento.localeCompare(b.fechaVencimiento),
      );
      const next = pendingCuotas[0];
      const pagosEsperados = pagosPorMes(frecuencia);
      const pagosRegistrados = await this.pagoRepository.countByCuota(next.id);
      const montoParcial = calcularMontoParcial(next.monto, frecuencia).amount;

      const desglose: any[] = [];
      const [y, m] = next.periodoInicio.split('-').map(Number);
      let currentYear = y;
      let currentMonth = m - 1; // 0-indexed

      const mesesEsp = [
        'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
      ];

      while (desglose.length < pagosEsperados) {
        const periodStr = `${currentYear}-${String(currentMonth + 1).padStart(2, '0')}-01`;
        const quotaForMonth = cuotas.find(c => c.periodoInicio === periodStr);

        const quotaId = quotaForMonth ? quotaForMonth.id : null;
        const quotaMonto = quotaForMonth ? quotaForMonth.monto : (tarifaMensual ? tarifaMensual.monto : 0);
        const quotaMontoParcial = calcularMontoParcial(quotaMonto, frecuencia).amount;

        let pRegistrados = 0;
        if (quotaForMonth) {
          pRegistrados = await this.pagoRepository.countByCuota(quotaForMonth.id);
        }

        const fechas = Periodo.fechasCobroParciales(frecuencia, currentYear, currentMonth);
        const remainingFechas = fechas.slice(pRegistrados);
        const mesNombre = mesesEsp[currentMonth];

        for (let i = 0; i < remainingFechas.length; i++) {
          if (desglose.length >= pagosEsperados) break;
          desglose.push({
            id: quotaId ? `${quotaId}-${pRegistrados + i + 1}` : `future-${periodStr}-${pRegistrados + i + 1}`,
            cuotaId: quotaId,
            fecha: remainingFechas[i],
            monto: Math.round(quotaMontoParcial / 100),
            numeroPago: pRegistrados + i + 1,
            mes: mesNombre,
          });
        }

        currentMonth++;
        if (currentMonth > 11) {
          currentMonth = 0;
          currentYear++;
        }
      }

      proximoCobro = desglose.length > 0 ? desglose[0].fecha : next.fechaVencimiento;
      proximoPago = {
        concepto: next.concepto,
        fechaVencimiento: proximoCobro ?? next.fechaVencimiento,
        monto: Math.round(montoParcial / 100),
        montoTotal: Math.round(next.monto / 100),
        montoPagado: Math.round(next.montoPagado / 100),
        pagosEsperados,
        pagosRegistrados,
        montoParcial: Math.round(montoParcial / 100),
        desglose,
      };
    }

    let ultimoPago: any = null;
    if (pagos.length > 0) {
      pagos.sort((a, b) => b.fechaPago.localeCompare(a.fechaPago));
      const lastPago = pagos[0];
      ultimoPago = {
        monto: Math.round(lastPago.monto / 100),
        fecha: lastPago.fechaPago,
        cobrador: 'Administración',
      };
    }

    const movimientos: any[] = [];
    for (const cuota of cuotas) {
      movimientos.push({
        id: cuota.id,
        tipo: 'cargo',
        monto: Math.round(cuota.monto / 100),
        fecha: cuota.periodoInicio,
        descripcion: `Generación de cuota ${cuota.concepto}`,
      });
    }
    for (const pago of pagos) {
      movimientos.push({
        id: pago.id,
        tipo: 'pago',
        monto: Math.round(pago.monto / 100),
        fecha: pago.fechaPago,
        descripcion: 'Pago registrado',
      });
    }
    
    // Sort merged by date descending
    movimientos.sort((a, b) => b.fecha.localeCompare(a.fecha));

    let tarifaActual: {
      cuotaMensual: number;
      montoSegunFrecuencia: number;
      frecuencia: Frecuencia;
    } | null = null;

    if (tarifaMensual) {
      tarifaActual = {
        cuotaMensual: Math.round(tarifaMensual.monto / 100),
        montoSegunFrecuencia: tarifaPropia
          ? Math.round(tarifaPropia.monto / 100)
          : Math.round(tarifaMensual.monto / 100),
        frecuencia,
      };
    }

    return {
      saldo: saldoFrontend,
      status,
      proximoCobro,
      proximoPago,
      tarifaActual,
      ultimoPago,
      movimientos: movimientos.slice(0, 2),
    };
  }
}
