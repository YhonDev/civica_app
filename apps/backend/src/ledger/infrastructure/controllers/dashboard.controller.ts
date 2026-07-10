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

@Controller()
@UseGuards(JwtAuthGuard)
export class DashboardController {
  constructor(
    private readonly dashboardQuery: DashboardQuery,
    private readonly cuotaRepository: CuotaRepository,
    private readonly pagoRepository: PagoRepository,
    private readonly cuentaCarteraRepository: CuentaCarteraRepository,
    private readonly tarifaRepository: TarifaRepository,
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

      proximoCobro = next.fechaVencimiento;
      proximoPago = {
        concepto: next.concepto,
        fechaVencimiento: next.fechaVencimiento,
        monto: Math.round(montoParcial / 100),
        montoTotal: Math.round(next.monto / 100),
        montoPagado: Math.round(next.montoPagado / 100),
        pagosEsperados,
        pagosRegistrados,
        montoParcial: Math.round(montoParcial / 100),
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

    if (cuenta) {
      const vigentes = await this.tarifaRepository.findVigentesPorConjunto(
        cuenta.conjuntoId,
        hoy,
      );
      const tarifaMensual = vigentes.MENSUAL;
      const tarifaPropia = vigentes[frecuencia];

      if (tarifaMensual) {
        tarifaActual = {
          cuotaMensual: Math.round(tarifaMensual.monto / 100),
          montoSegunFrecuencia: tarifaPropia
            ? Math.round(tarifaPropia.monto / 100)
            : Math.round(tarifaMensual.monto / 100),
          frecuencia,
        };
      }
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
