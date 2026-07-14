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
import { SolicitudRepository } from '../persistence/solicitud.repository';
import { TarifaRepository } from '../persistence/tarifa.repository';
import type { TimelineItemDto, TimelineResponse } from '../../application/dtos/dashboard.dto';
import { PropietarioRepository } from '../../../community/infrastructure/propietario.repository';
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
    private readonly solicitudRepository: SolicitudRepository,
    private readonly tarifaRepository: TarifaRepository,
    private readonly propietarioRepository: PropietarioRepository,
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

    // 2. Cuotas pendientes en esas etapas (ahora con relaciones cargadas: cuota→prop→tenencia→casa→manzana→etapa)
    const cuotas = etapaIds.length > 0
      ? await this.cuotaRepository.findPendientesConPropietarioByEtapas(tenantId, etapaIds)
      : [];

    // 3. Pagos del cobrador hoy
    const { pagos: pagosHoy, total: totalHoy, count: countHoy } =
      await this.pagoRepository.findByCobradorToday(user.id);

    // 4. Armar respuesta centrada en Viviendas (casas), no en Propietarios
    //    Una casa puede tener múltiples cuotas pendientes; las agrupamos bajo la misma casa.
    type AgrupacionVivienda = {
      casaId: string;
      casaDireccion: string;
      manzanaNombre: string;
      etapaNombre: string;
      propietarioId: string;
      propietarioNombre: string;
      propietarioTelefono: string;
      saldo: number;
      peorEstado: string;
      cuotas: Array<{ id: string; monto: number; estado: string; periodo: string }>;
    };

    const viviendasMap = new Map<string, AgrupacionVivienda>();

    for (const c of cuotas) {
      const prop = c.propietario;
      // Filtrar solo tenencias activas (sin fecha_fin)
      const tenencia = prop?.tenencias?.find((t) => t.fechaFin === null);
      if (!tenencia) continue; // sin ocupante actual, ignoramos

      const casa = tenencia.casa;
      const manzana = casa?.manzana;
      const etapa = manzana?.etapa;
      if (!casa) continue;

      const casaId = casa.id;
      const existing = viviendasMap.get(casaId);

      const montoSaldo = Math.round((c.monto - c.montoPagado) / 100);

      if (existing) {
        existing.saldo += montoSaldo;
        // El peor estado (VENCIDA > PARCIAL > PENDIENTE)
        if (c.estado === 'VENCIDA') existing.peorEstado = 'VENCIDA';
        else if (c.estado === 'PARCIAL' && existing.peorEstado !== 'VENCIDA') existing.peorEstado = 'PARCIAL';
        existing.cuotas.push({
          id: c.id,
          monto: Math.round(c.monto / 100),
          estado: c.estado,
          periodo: c.periodoInicio.slice(0, 7),
        });
      } else {
        viviendasMap.set(casaId, {
          casaId,
          casaDireccion: casa.direccionInterna,
          manzanaNombre: manzana?.nombre ?? '',
          etapaNombre: etapa?.nombre ?? '',
          propietarioId: prop?.id ?? '',
          propietarioNombre: prop?.nombre ?? 'Desconocido',
          propietarioTelefono: prop?.telefono ?? '',
          saldo: montoSaldo,
          peorEstado: c.estado,
          cuotas: [{
            id: c.id,
            monto: Math.round(c.monto / 100),
            estado: c.estado,
            periodo: c.periodoInicio.slice(0, 7),
          }],
        });
      }
    }

    const viviendas = Array.from(viviendasMap.values());

    // Stats
    const pendientes = viviendas.filter((v) => v.peorEstado !== 'VENCIDA').length;
    const vencidasViviendas = viviendas.filter((v) => v.peorEstado === 'VENCIDA').length;
    const montoEsperado = viviendas.reduce((sum, v) => sum + v.saldo, 0);

    // Próxima vivienda (la primera con peor estado, orden priorizando vencidas > pendientes)
    viviendas.sort((a, b) => {
      const order = { VENCIDA: 0, PARCIAL: 1, PENDIENTE: 2 };
      return (order[a.peorEstado as keyof typeof order] ?? 3) -
             (order[b.peorEstado as keyof typeof order] ?? 3);
    });
    const proximaVivienda = viviendas.length > 0
      ? {
          etapaNombre: viviendas[0].etapaNombre,
          manzanaNombre: viviendas[0].manzanaNombre,
          casaDireccion: viviendas[0].casaDireccion,
        }
      : null;

    // Últimos cobros: mapear a estructura legible con nombre del cobrador
    const cobrosHoy = pagosHoy.slice(0, 10);

    return {
      cobrador: { nombre: user.nombre },
      stats: {
        totalViviendas: viviendas.length,
        cobradosHoy: countHoy,
        montoCobradoHoy: Math.round(totalHoy / 100),
        pendientes,
        vencidas: vencidasViviendas,
        montoEsperado,
      },
      viviendas,
      proximaVivienda,
      ultimosCobros: cobrosHoy.map((p) => ({
        id: p.id,
        monto: Math.round(p.monto / 100),
        fecha: p.fechaPago,
      })),
    };
  }

  @Get('dashboard/cobrador/viviendas')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.COBRADOR)
  async getViviendasExplorer(
    @CurrentUser() user: Usuario,
    @CurrentTenant() tenantId: string,
  ) {
    // 1. Etapas asignadas al cobrador
    const asignaciones = await this.dataSource.query(
      'SELECT etapa_id FROM asignaciones_etapa WHERE usuario_id = $1',
      [user.id],
    );
    const etapaIds: string[] = asignaciones.map((a: any) => a.etapa_id);

    if (etapaIds.length === 0) {
      return { etapas: [] };
    }

    // 2. Obtener la jerarquía completa: etapas → manzanas → casas con sus propietarios
    const rows: any[] = await this.dataSource.query(
      `SELECT
        e.id AS etapa_id, e.nombre AS etapa_nombre,
        m.id AS manzana_id, m.nombre AS manzana_nombre,
        c.id AS casa_id, c.direccion_interna AS casa_direccion,
        p.id AS prop_id, p.nombre AS prop_nombre, p.telefono AS prop_telefono,
        t.id AS tenencia_id
      FROM etapas e
      JOIN manzanas m ON m.etapa_id = e.id
      JOIN casas c ON c.manzana_id = m.id
      LEFT JOIN tenencias t ON t.casa_id = c.id AND t.fecha_fin IS NULL
      LEFT JOIN propietarios p ON p.id = t.propietario_id
      WHERE e.id = ANY($1::uuid[])
      ORDER BY e.nombre, m.nombre, c.direccion_interna`,
      [etapaIds],
    );

    // 3. Obtener cuotas pendientes/vencidas para todas las casas en estas etapas
    const cuotasRaw: any[] = await this.dataSource.query(
      `SELECT
        cu.id, cu.propietario_id, cu.monto, cu.monto_pagado,
        cu.estado, cu.periodo_inicio
      FROM cuotas cu
      JOIN propietarios p ON p.id = cu.propietario_id
      JOIN tenencias t ON t.propietario_id = p.id AND t.fecha_fin IS NULL
      WHERE cu.tenant_id = $1
        AND cu.estado IN ('PENDIENTE', 'PARCIAL', 'VENCIDA')
        AND t.casa_id = ANY(
          SELECT c2.id FROM casas c2
          JOIN manzanas m2 ON m2.id = c2.manzana_id
          WHERE m2.etapa_id = ANY($2::uuid[])
        )`,
      [tenantId, etapaIds],
    );

    // Indexar cuotas por propietarioId para acceso rápido
    const cuotasPorProp = new Map<string, typeof cuotasRaw>();
    for (const cu of cuotasRaw) {
      const pid = cu.propietario_id;
      if (!cuotasPorProp.has(pid)) cuotasPorProp.set(pid, []);
      cuotasPorProp.get(pid)!.push(cu);
    }

    // 4. Calcular status de cada casa basado en cuotas
    const statusPorCasa = new Map<string, { estado: string; saldo: number }>();
    for (const [propId, cuotas] of cuotasPorProp) {
      let saldoTotal = 0;
      let peorEstado = 'PENDIENTE';
      for (const cu of cuotas) {
        const saldo = Math.round((cu.monto - cu.monto_pagado) / 100);
        saldoTotal += saldo;
        if (cu.estado === 'VENCIDA') peorEstado = 'VENCIDA';
        else if (cu.estado === 'PARCIAL' && peorEstado !== 'VENCIDA') peorEstado = 'PARCIAL';
      }
      // Asociar el status al propietario (luego al propietario de cada casa)
      statusPorCasa.set(propId, { estado: peorEstado, saldo: saldoTotal });
    }

    // 5. Armar árbol jerárquico: etapas → manzanas → casas
    const etapasMap = new Map<string, any>();

    for (const r of rows) {
      if (!etapasMap.has(r.etapa_id)) {
        etapasMap.set(r.etapa_id, {
          id: r.etapa_id,
          nombre: r.etapa_nombre,
          manzanas: new Map<string, any>(),
        });
      }
      const etapa = etapasMap.get(r.etapa_id);

      if (!etapa.manzanas.has(r.manzana_id)) {
        etapa.manzanas.set(r.manzana_id, {
          id: r.manzana_id,
          nombre: r.manzana_nombre,
          casas: [],
        });
      }
      const manzana = etapa.manzanas.get(r.manzana_id);

      // Buscar status para esta casa (a través del propietario)
      const propStatus = r.prop_id ? statusPorCasa.get(r.prop_id) : null;

      manzana.casas.push({
        id: r.casa_id,
        direccion: r.casa_direccion,
        propietarioNombre: r.prop_nombre ?? 'Sin propietario',
        propietarioTelefono: r.prop_telefono ?? '',
        estado: propStatus?.estado ?? 'AL_DIA',
        saldo: propStatus?.saldo ?? 0,
      });
    }

    // Convertir Maps a arrays
    const etapas = Array.from(etapasMap.values()).map((e) => ({
      id: e.id,
      nombre: e.nombre,
      manzanas: Array.from(e.manzanas.values()),
    }));

    return { etapas };
  }

  @Get('dashboard/propietario')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.PROPIETARIO)
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
        propietarioInfo: { nombre: '', casaDireccion: '', etapaNombre: '' },
      };
    }

    const [cuotasRaw, pagos, cuenta, propietario] = await Promise.all([
      this.cuotaRepository.findByPropietario(user.propietarioId),
      this.pagoRepository.findByPropietario(user.propietarioId),
      this.cuentaCarteraRepository.findByPropietario(user.propietarioId),
      this.propietarioRepository.findByIdWithRelations(user.propietarioId),
    ]);

    // Build propietarioInfo from relations
    const tenencia = propietario?.tenencias?.[0];
    const casa = tenencia?.casa;
    const manzana = casa?.manzana;
    const etapa = manzana?.etapa;

    const propietarioInfo = {
      nombre: propietario?.nombre ?? '',
      casaDireccion: casa
        ? `${casa.direccionInterna}${manzana ? `, Mz. ${manzana.nombre}` : ''}`
        : '',
      etapaNombre: etapa?.nombre ?? '',
    };

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
      propietarioInfo,
    };
  }

  @Get('dashboard/propietario/timeline')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.PROPIETARIO)
  async getPropietarioTimeline(
    @CurrentUser() user: Usuario,
    @Query('offset', new DefaultValuePipe(0), ParseIntPipe) offset: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
  ): Promise<TimelineResponse> {
    if (!user.propietarioId) {
      return {
        items: [],
        hasMore: false,
      };
    }

    const [pagos, solicitudes] = await Promise.all([
      this.pagoRepository.findByPropietario(user.propietarioId),
      this.solicitudRepository.findByUsuario(user.id),
    ]);

    const items: TimelineItemDto[] = [
      ...pagos.map((p) => ({
        id: p.id,
        type: 'PAGO' as const,
        date: p.fechaPago,
        monto: Math.round(p.monto / 100),
        description: 'Pago de cuota',
        estado: 'PAGADO',
      })),
      ...solicitudes.map((s) => ({
        id: s.id,
        type: 'SOLICITUD' as const,
        date: s.fecha instanceof Date ? s.fecha.toISOString() : String(s.fecha),
        monto: null,
        description: s.descripcion,
        estado: s.estado,
      })),
    ];

    // Sort by date descending (most recent first)
    items.sort((a, b) => b.date.localeCompare(a.date));

    const sliced = items.slice(offset, offset + limit);

    return {
      items: sliced,
      hasMore: offset + limit < items.length,
    };
  }
}
