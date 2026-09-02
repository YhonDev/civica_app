import {
  Controller,
  Get,
  Query,
  UseGuards,
  ParseIntPipe,
  DefaultValuePipe,
  Optional,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { DashboardQuery } from '../../application/queries/dashboard.query';
import { CobroRepository } from '../persistence/cobro.repository';
import { PagoRepository } from '../persistence/pago.repository';
import { PlanDeCobroRepository } from '../persistence/plan-de-cobro.repository';
import { SolicitudRepository } from '../persistence/solicitud.repository';
import { TarifaRepository } from '../persistence/tarifa.repository';
import { GenerarCobrosUseCase } from '../../application/use-cases/generar-cobros.use-case';
import { MarcarVencidasUseCase } from '../../application/use-cases/marcar-vencidas.use-case';
import { Cobro } from '../../domain/cobro.entity';
import type { TimelineItemDto, TimelineResponse } from '../../application/dtos/dashboard.dto';
import { ResidenteRepository } from '../../../community/infrastructure/residente.repository';
import { Periodo, type ModalidadRecaudo, pagosPorMes, calcularMontoParcial } from '../../../shared/common/value-objects';
import { JwtAuthGuard } from '../../../shared/auth/jwt-auth.guard';
import { RolesGuard } from '../../../shared/auth/guards/roles.guard';
import { Roles } from '../../../shared/auth/decorators/roles.decorator';
import { CurrentTenant } from '../../../shared/tenant/current-tenant.decorator';
import { CurrentUser } from '../../../shared/tenant/current-user.decorator';
import { RolUsuario, Usuario } from '../../../iam/domain/usuario.entity';
import { DataSource } from 'typeorm';

@ApiTags('Dashboard')
@ApiBearerAuth('jwt-auth')
@Controller()
@UseGuards(JwtAuthGuard)
export class DashboardController {
  constructor(
    private readonly dashboardQuery: DashboardQuery,
    private readonly cobroRepository: CobroRepository,
    private readonly pagoRepository: PagoRepository,
    private readonly planDeCobroRepository: PlanDeCobroRepository,
    private readonly solicitudRepository: SolicitudRepository,
    private readonly tarifaRepository: TarifaRepository,
    private readonly residenteRepository: ResidenteRepository,
    private readonly dataSource: DataSource,
    @Optional() private readonly generarCobrosUC?: GenerarCobrosUseCase,
    @Optional() private readonly marcarVencidasUC?: MarcarVencidasUseCase,
  ) {}

  @Get('dashboard/administrador')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async getDashboard(
    @CurrentTenant() tenantId: string,
    @Query('mes') mesQuery?: string,
    @Query('anio') anioQuery?: string,
  ) {
    const hoy = new Date();
    const mes = mesQuery ? parseInt(mesQuery, 10) : hoy.getMonth() + 1;
    const anio = anioQuery ? parseInt(anioQuery, 10) : hoy.getFullYear();
    return this.dashboardQuery.execute(mes, anio, tenantId);
  }

  @Get('dashboard/cartera-consolidada')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN, RolUsuario.COBRADOR)
  async getCarteraConsolidada(
    @CurrentTenant() tenantId: string,
    @CurrentUser() user: Usuario,
    @Query('etapaId') etapaId?: string,
    @Query('manzanaId') manzanaId?: string,
    @Query('estado') estado?: string,
  ) {
    let allowedEtapaIds: string[] | undefined;

    if (user.rol === RolUsuario.COBRADOR) {
      const asignaciones = await this.dataSource.query(
        'SELECT etapa_id FROM asignaciones_etapa WHERE usuario_id = $1',
        [user.id],
      );
      const stageIds: string[] = asignaciones.map((a: any) => a.etapa_id);
      if (stageIds.length === 0) {
        return [];
      }
      allowedEtapaIds = stageIds;
    }

    // Buscamos residentes con tenencias cargadas
    const residentes = await this.residenteRepository.buscarPorFiltros({
      tenantId,
    });

    // Bulk query for cobros to prevent N+1 query
    const residenteIds = residentes.map((r) => r.id);
    const todosLosCobros = await this.cobroRepository.findByResidentes(residenteIds);

    // Group cobros by residenteId in memory
    const cobrosMap = new Map<string, Cobro[]>();
    for (const c of todosLosCobros) {
      const list = cobrosMap.get(c.residenteId) || [];
      list.push(c);
      cobrosMap.set(c.residenteId, list);
    }

    const resultado = [];

    for (const r of residentes) {
      const tenenciaActiva = r.tenencias?.find((t) => !t.fechaFin) ?? r.tenencias?.[0];
      const casa = tenenciaActiva?.casa;
      const manzana = casa?.manzana;
      const etapa = manzana?.etapa;

      if (etapaId && etapa?.id !== etapaId) {
        continue;
      }

      if (manzanaId && manzana?.id !== manzanaId) {
        continue;
      }

      if (allowedEtapaIds && (!etapa?.id || !allowedEtapaIds.includes(etapa.id))) {
        continue;
      }

      const cobros = cobrosMap.get(r.id) || [];
      let saldoPendiente = 0;
      let saldoVencido = 0;
      let tieneVencida = false;
      let tienePendiente = false;

      for (const c of cobros) {
        if (c.estado === 'PENDIENTE') {
          saldoPendiente += c.monto;
          tienePendiente = true;
        } else if (c.estado === 'VENCIDA') {
          saldoVencido += c.monto;
          tieneVencida = true;
        }
      }

      let estadoCalculado = 'AL_DIA';
      if (tieneVencida) {
        estadoCalculado = 'EN_MORA';
      } else if (tienePendiente) {
        estadoCalculado = 'PENDIENTE';
      }

      if (estado && estado !== 'TODOS' && estadoCalculado !== estado) {
        continue;
      }

      resultado.push({
        residenteId: r.id,
        nombre: r.nombre,
        telefono: r.telefono,
        email: r.email,
        estado: estadoCalculado,
        saldoPendiente: Math.round(saldoPendiente / 100),
        saldoVencido: Math.round(saldoVencido / 100),
        totalAdeudado: Math.round((saldoPendiente + saldoVencido) / 100),
      });
    }

    return resultado;
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

    // 2. Cobros pendientes en esas etapas
    const cobros = etapaIds.length > 0
      ? await this.cobroRepository.findPendientesByTenant(tenantId)
      : [];

    // 3. Pagos del cobrador hoy
    const { pagos: pagosHoy, total: totalHoy, count: countHoy } =
      await this.pagoRepository.findByCobradorToday(user.id);

    // 3.5. Buscar solicitudes activas del tenant para el cobrador (orden cronológico ascendente: FIFO)
    const listaSolicitudes = await this.getSolicitudesActivasCobrador(tenantId, etapaIds);

    const casaSolicitudMap = new Map<string, { id: string; descripcion: string }>();
    const cobroSolicitudSet = new Set<string>();
    for (const sol of listaSolicitudes) {
      const targetCasaId = sol.casaId;
      const desc = sol.descripcion || 'Solicitud de cobro enviada por el residente';
      if (targetCasaId) casaSolicitudMap.set(targetCasaId, { id: sol.id, descripcion: desc });
      if (sol.cobroId) cobroSolicitudSet.add(sol.cobroId);
    }

    // 4. Armar respuesta centrada en Viviendas (casas), no en Residentes
    type AgrupacionVivienda = {
      casaId: string;
      casaDireccion: string;
      manzanaNombre: string;
      etapaNombre: string;
      residenteId: string;
      residenteNombre: string;
      residenteTelefono: string;
      modalidadPago: string;
      tieneSolicitud: boolean;
      solicitudId?: string;
      solicitudDescripcion?: string;
      proximoVencimiento: string;
      saldo: number;
      peorEstado: string;
      cuotas: Array<{ id: string; monto: number; estado: string; periodo: string; fechaVencimiento: string }>;
    };

    const viviendasMap = new Map<string, AgrupacionVivienda>();

    for (const c of cobros) {
      const res = c.residente;
      const tenencia = res?.tenencias?.find((t) => t.fechaFin === null);
      const casa = c.casa ?? tenencia?.casa ?? res?.casaActual;
      if (!casa) continue;

      const manzana = casa?.manzana;
      const etapa = manzana?.etapa;
      if (etapaIds.length > 0 && etapa?.id && !etapaIds.includes(etapa.id)) continue;

      const casaId = casa.id;
      const existing = viviendasMap.get(casaId);

      const montoSaldo = Math.round((c.monto - c.montoPagado) / 100);
      const solObj = casaSolicitudMap.get(casaId);
      const tieneSol = Boolean(solObj) || cobroSolicitudSet.has(c.id);
      const fVencStr = c.fechaVencimiento ? new Date(c.fechaVencimiento).toISOString() : new Date().toISOString();

      if (existing) {
        existing.saldo += montoSaldo;
        if (tieneSol) {
          existing.tieneSolicitud = true;
          if (solObj) {
            existing.solicitudId = solObj.id;
            existing.solicitudDescripcion = solObj.descripcion;
          }
        }
        // Actualizar proximoVencimiento si esta cuota vence antes
        if (new Date(fVencStr) < new Date(existing.proximoVencimiento)) {
          existing.proximoVencimiento = fVencStr;
        }
        // El peor estado (VENCIDA > PARCIAL > PENDIENTE)
        if (c.estado === 'VENCIDA') existing.peorEstado = 'VENCIDA';
        else if (c.estado === 'PARCIAL' && existing.peorEstado !== 'VENCIDA') existing.peorEstado = 'PARCIAL';
        existing.cuotas.push({
          id: c.id,
          monto: Math.round(c.monto / 100),
          estado: c.estado,
          periodo: c.periodoInicio.slice(0, 7),
          fechaVencimiento: fVencStr,
        });
      } else {
        viviendasMap.set(casaId, {
          casaId,
          casaDireccion: casa.direccionInterna,
          manzanaNombre: manzana?.nombre ?? '',
          etapaNombre: etapa?.nombre ?? '',
          residenteId: res?.id ?? '',
          residenteNombre: res?.nombre ?? 'Desconocido',
          residenteTelefono: res?.telefono ?? '',
          modalidadPago: res?.modalidadPago ?? 'MENSUAL',
          tieneSolicitud: tieneSol,
          solicitudId: solObj?.id,
          solicitudDescripcion: solObj?.descripcion,
          proximoVencimiento: fVencStr,
          saldo: montoSaldo,
          peorEstado: c.estado,
          cuotas: [{
            id: c.id,
            monto: Math.round(c.monto / 100),
            estado: c.estado,
            periodo: c.periodoInicio.slice(0, 7),
            fechaVencimiento: fVencStr,
          }],
        });
      }
    }

    const viviendas = Array.from(viviendasMap.values());

    // Stats
    const pendientes = viviendas.filter((v) => v.peorEstado !== 'VENCIDA').length;
    const vencidasViviendas = viviendas.filter((v) => v.peorEstado === 'VENCIDA').length;
    const montoEsperado = viviendas.reduce((sum, v) => sum + v.saldo, 0);

    // Próxima vivienda (prioriza casas con solicitud presencial > orden cronológico por fecha de vencimiento más cercana)
    viviendas.sort((a, b) => {
      if (a.tieneSolicitud && !b.tieneSolicitud) return -1;
      if (!a.tieneSolicitud && b.tieneSolicitud) return 1;

      const dateA = new Date(a.proximoVencimiento).getTime();
      const dateB = new Date(b.proximoVencimiento).getTime();
      if (dateA !== dateB) return dateA - dateB;

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
      solicitudes: listaSolicitudes,
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
      return { etapas: [], solicitudes: [] };
    }

    // 2. Obtener la jerarquía completa: etapas → manzanas → casas con sus residentes
    const rows: any[] = await this.dataSource.query(
      `SELECT
        e.id AS etapa_id, e.nombre AS etapa_nombre,
        m.id AS manzana_id, m.nombre AS manzana_nombre,
        c.id AS casa_id, c.direccion_interna AS casa_direccion,
        p.id AS prop_id, p.nombre AS prop_nombre, p.telefono AS prop_telefono,
        t.id AS tenencia_id
      FROM etapas e
      LEFT JOIN manzanas m ON m.etapa_id = e.id
      LEFT JOIN casas c ON c.manzana_id = m.id
      LEFT JOIN tenencias t ON t.casa_id = c.id AND t.fecha_fin IS NULL
      LEFT JOIN residentes p ON p.id = t.residente_id
      WHERE e.id = ANY($1::uuid[])
      ORDER BY e.nombre, m.nombre, c.direccion_interna`,
      [etapaIds],
    );

    // 3. Obtener cuotas pendientes/vencidas para todas las casas en estas etapas
    const cuotasRaw: any[] = await this.dataSource.query(
      `SELECT
        cu.id, cu.residente_id, cu.monto, cu.monto_pagado,
        cu.estado, cu.periodo_inicio
      FROM cobros cu
      JOIN residentes p ON p.id = cu.residente_id
      JOIN tenencias t ON t.residente_id = p.id AND t.fecha_fin IS NULL
      WHERE cu.tenant_id = $1
        AND cu.estado IN ('PENDIENTE', 'PARCIAL', 'VENCIDA')
        AND t.casa_id = ANY(
          SELECT c2.id FROM casas c2
          JOIN manzanas m2 ON m2.id = c2.manzana_id
          WHERE m2.etapa_id = ANY($2::uuid[])
        )`,
      [tenantId, etapaIds],
    );

    // Indexar cuotas por residenteId para acceso rápido
    const cuotasPorRes = new Map<string, typeof cuotasRaw>();
    for (const cu of cuotasRaw) {
      const pid = cu.residente_id;
      if (!cuotasPorRes.has(pid)) cuotasPorRes.set(pid, []);
      cuotasPorRes.get(pid)!.push(cu);
    }

    // 4. Calcular status de cada casa basado en cuotas
    const statusPorCasa = new Map<string, { estado: string; saldo: number }>();
    for (const [resId, cuotas] of cuotasPorRes) {
      let saldoTotal = 0;
      let peorEstado = 'PENDIENTE';
      for (const cu of cuotas) {
        const saldo = Math.round((cu.monto - cu.monto_pagado) / 100);
        saldoTotal += saldo;
        if (cu.estado === 'VENCIDA') peorEstado = 'VENCIDA';
        else if (cu.estado === 'PARCIAL' && peorEstado !== 'VENCIDA') peorEstado = 'PARCIAL';
      }
      // Asociar el status al residente (luego al residente de cada casa)
      statusPorCasa.set(resId, { estado: peorEstado, saldo: saldoTotal });
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

      if (r.manzana_id) {
        if (!etapa.manzanas.has(r.manzana_id)) {
          etapa.manzanas.set(r.manzana_id, {
            id: r.manzana_id,
            nombre: r.manzana_nombre,
            casas: [],
          });
        }
        const manzana = etapa.manzanas.get(r.manzana_id);

        if (r.casa_id) {
          // Buscar status para esta casa (a través del residente)
          const resStatus = r.prop_id ? statusPorCasa.get(r.prop_id) : null;

          manzana.casas.push({
            id: r.casa_id,
            direccion: r.casa_direccion,
            residenteNombre: r.prop_nombre ?? 'Sin residente',
            residenteTelefono: r.prop_telefono ?? '',
            estado: resStatus?.estado ?? 'AL_DIA',
            saldo: resStatus?.saldo ?? 0,
          });
        }
      }
    }

    // Convertir Maps a arrays
    const etapas = Array.from(etapasMap.values()).map((e) => ({
      id: e.id,
      nombre: e.nombre,
      manzanas: Array.from(e.manzanas.values()),
    }));

    // 6. Obtener solicitudes activas de la ruta
    const solicitudes = await this.getSolicitudesActivasCobrador(tenantId, etapaIds);

    return { etapas, solicitudes };
  }

  private async getSolicitudesActivasCobrador(tenantId: string, etapaIds: string[]) {
    const rawSolicitudes = await this.dataSource.query(
      `SELECT 
        s.id,
        s.cobro_id AS "cobroId",
        s.nro_recibo AS "nroRecibo",
        s.tipo,
        s.descripcion,
        s.estado,
        s.fecha,
        s.created_at AS "createdAt",
        s.residente_id AS "residenteId",
        COALESCE(r.nombre, u.nombre, 'Residente') AS "residenteNombre",
        COALESCE(r.telefono, '') AS "residenteTelefono",
        COALESCE(r.modalidad_pago, 'MENSUAL') AS "modalidadPago",
        c.id AS "casaId",
        COALESCE(c.direccion_interna, '') AS "casaDireccion",
        COALESCE(m.nombre, '') AS "manzanaNombre",
        COALESCE(e.nombre, '') AS "etapaNombre",
        COALESCE(cb.monto, 2000000) AS "monto",
        COALESCE(cb.monto_pagado, 0) AS "montoPagado",
        COALESCE(cb.estado, 'PENDIENTE') AS "cobroEstado"
      FROM solicitudes s
      LEFT JOIN usuarios u ON u.id = s.usuario_id
      LEFT JOIN cobros cb ON cb.id = s.cobro_id
      LEFT JOIN residentes r ON (r.id = s.residente_id OR r.id = cb.residente_id OR r.id = u.residente_id)
      LEFT JOIN tenencias t ON (t.residente_id = r.id AND t.fecha_fin IS NULL)
      LEFT JOIN casas c ON (c.id = s.casa_id OR c.id = cb.casa_id OR c.id = t.casa_id OR c.id = r.casa_actual_id)
      LEFT JOIN manzanas m ON m.id = c.manzana_id
      LEFT JOIN etapas e ON e.id = m.etapa_id
      WHERE s.tenant_id = $1
        AND s.estado IN ('EN_ESPERA', 'PENDIENTE', 'EN_CAMINO', 'EN_REVISION')
        ${etapaIds.length > 0 ? 'AND (e.id IS NULL OR e.id = ANY($2::uuid[]))' : ''}
      ORDER BY s.created_at ASC`,
      etapaIds.length > 0 ? [tenantId, etapaIds] : [tenantId],
    );

    return rawSolicitudes.map((s: any) => ({
      id: s.id,
      cobroId: s.cobroId,
      cuotaId: s.cobroId,
      nroRecibo: s.nroRecibo,
      tipo: s.tipo,
      descripcion: s.descripcion,
      estado: s.estado,
      fecha: s.fecha ? new Date(s.fecha).toISOString() : new Date().toISOString(),
      residenteId: s.residenteId || '',
      residenteNombre: s.residenteNombre || 'Residente',
      residenteTelefono: s.residenteTelefono || '',
      modalidadPago: s.modalidadPago || 'MENSUAL',
      casaId: s.casaId || '',
      casaDireccion: s.casaDireccion || '',
      manzanaNombre: s.manzanaNombre || '',
      etapaNombre: s.etapaNombre || '',
      monto: Math.round((Number(s.monto) || 0) / 100),
      saldo: Math.round(((Number(s.monto) || 0) - (Number(s.montoPagado) || 0)) / 100),
      cobroEstado: s.cobroEstado,
    }));
  }

  @Get(['dashboard/residente', 'dashboard/propietario'])
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.RESIDENTE)
  async getDashboardResidente(
    @CurrentUser() user: Usuario,
    @CurrentTenant() tenantId: string,
  ) {
    if (!user.residenteId) {
      return {
        saldo: 0,
        status: 'AL_DIA',
        proximoCobro: null,
        ultimoPago: null,
        movimientos: [],
        residenteInfo: { nombre: '', casaDireccion: '', etapaNombre: '' },
      };
    }

    if (this.generarCobrosUC) {
      await this.generarCobrosUC.execute().catch(() => {});
    }
    if (this.marcarVencidasUC) {
      await this.marcarVencidasUC.execute().catch(() => {});
    }

    const [cobrosRaw, pagos, cuenta, residente, solicitudesResidente] = await Promise.all([
      this.cobroRepository.findByResidente(user.residenteId, tenantId),
      this.pagoRepository.findByPropietario(user.residenteId, tenantId),
      this.planDeCobroRepository.findByResidente(user.residenteId),
      this.residenteRepository.findByIdWithRelations(user.residenteId),
      this.solicitudRepository.findByUsuario(user.id),
    ]);

    // Build residenteInfo from relations
    const tenencia = residente?.tenencias?.[0];
    const casa = tenencia?.casa;
    const manzana = casa?.manzana;
    const etapa = manzana?.etapa;

    const modStr = cuenta?.modalidad ?? residente?.modalidadPago ?? 'MENSUAL';
    const modalidadPagoFormatted = modStr === 'SEMANAL' ? 'Semanal' : modStr === 'QUINCENAL' ? 'Quincenal' : 'Mensual';

    const residenteInfo = {
      nombre: residente?.nombre ?? '',
      casaDireccion: casa?.direccionInterna ?? '',
      manzanaNombre: manzana?.nombre ?? '',
      etapaNombre: etapa?.nombre ?? '',
      modalidadPago: modalidadPagoFormatted,
    };

    const modalidad: ModalidadRecaudo = (cuenta?.modalidad as ModalidadRecaudo) ?? 'MENSUAL';
    const hoy = new Date();

    let tarifaMensual: any = null;
    let tarifaPropia: any = null;
    if (cuenta) {
      const vigentes = await this.tarifaRepository.findVigentesPorConjunto(
        cuenta.proyectoId,
        hoy,
      );
      tarifaMensual = vigentes.MENSUAL;
      tarifaPropia = vigentes[modalidad];
    }

    const hoyStr = hoy.toISOString().split('T')[0];

    const cobros = cobrosRaw.filter((c) =>
      Periodo.esVisible(c.periodoInicio, modalidad, hoy),
    );

    let saldoMora = 0;
    let hasVencida = false;
    for (const cobro of cobrosRaw) {
      if (cobro.monto > cobro.montoPagado) {
        if (cobro.estado === 'VENCIDA' || cobro.fechaVencimiento < hoyStr) {
          saldoMora += (cobro.monto - cobro.montoPagado);
          hasVencida = true;
        }
      }
    }

    // Convert from cents (backend) to COP standard units (frontend)
    // Mobile UI expects raw values (e.g. 40000 COP, backend stores 4000000 cents)
    const saldoFrontend = Math.round(saldoMora / 100);

    const status = hasVencida ? 'MORA' : 'AL_DIA';

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

    const pendingCobros = cobros.filter((c) => c.monto > c.montoPagado);
    if (pendingCobros.length > 0) {
      pendingCobros.sort((a, b) =>
        a.fechaVencimiento.localeCompare(b.fechaVencimiento),
      );
      const next = pendingCobros[0];
      const pagosEsperados = pagosPorMes(modalidad);
      const pagosRegistrados = pagos.filter((p) => p.cobroId === next.id).length;
      const cuotaMontoCentavos = next.monto;
      const montoParcial = cuotaMontoCentavos;

      const desglose: any[] = [];
      const mesesEsp = [
        'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
      ];

      // 1. Encolar los cobros pendientes REALES de la base de datos (FIFO)
      for (const cobro of pendingCobros) {
        if (desglose.length >= pagosEsperados) break;

        let mesNombre = 'Mes';
        let numPago = 1;
        const match = cobro.concepto?.match(/^(.*?)\s*—\s*Cuota\s*(\d+)/i);
        if (match) {
          mesNombre = match[1].trim();
          numPago = parseInt(match[2], 10);
        } else {
          const d = new Date(cobro.fechaVencimiento);
          mesNombre = mesesEsp[d.getMonth()] ?? 'Mes';
        }

        desglose.push({
          id: cobro.id,
          cobroId: cobro.id,
          cuotaId: cobro.id,
          fecha: cobro.fechaVencimiento,
          monto: Math.round((cobro.monto - cobro.montoPagado) / 100),
          numeroPago: numPago,
          mes: mesNombre,
        });
      }

      // 2. Si faltan para completar pagosEsperados (ej. cuotas ya pagadas este mes),
      // proyectar cuotas del próximo mes encoladas abajo
      if (desglose.length < pagosEsperados) {
        const ultimaFechaStr = desglose.length > 0 ? desglose[desglose.length - 1].fecha : next.fechaVencimiento;
        const ultD = new Date(ultimaFechaStr);
        let projYear = ultD.getFullYear();
        let projMonth = ultD.getMonth() + 1; // siguiente mes
        if (projMonth > 11) {
          projMonth = 0;
          projYear++;
        }

        const montoCuotaEst = tarifaMensual
          ? Math.round(tarifaMensual.monto / pagosEsperados / 100)
          : Math.round(next.monto / 100);

        while (desglose.length < pagosEsperados) {
          const periodStr = `${projYear}-${String(projMonth + 1).padStart(2, '0')}-01`;
          const fechas = Periodo.fechasCobroParciales(modalidad, projYear, projMonth);
          const mesNombre = mesesEsp[projMonth];

          for (let i = 0; i < fechas.length; i++) {
            if (desglose.length >= pagosEsperados) break;
            desglose.push({
              id: `future-${periodStr}-${i + 1}`,
              cobroId: null,
              cuotaId: null,
              fecha: fechas[i],
              monto: montoCuotaEst,
              numeroPago: i + 1,
              mes: mesNombre,
            });
          }

          projMonth++;
          if (projMonth > 11) {
            projMonth = 0;
            projYear++;
          }
        }
      }

      proximoCobro = next.fechaVencimiento;
      const cuotaMontoPendiente = next.monto - next.montoPagado;
      proximoPago = {
        concepto: next.concepto,
        fechaVencimiento: next.fechaVencimiento,
        monto: Math.round(cuotaMontoPendiente / 100),
        montoTotal: Math.round(next.monto / 100),
        montoPagado: Math.round(next.montoPagado / 100),
        pagosEsperados,
        pagosRegistrados,
        montoParcial: Math.round(cuotaMontoPendiente / 100),
        desglose,
      };
    } else {
      // ── Projected fallback when there are 0 active pending cobros in DB ──
      // (e.g. resident registered late in current month or has paid all current cuotas)
      const pagosEsperados = pagosPorMes(modalidad);
      const montoTotalCentavos = tarifaMensual ? tarifaMensual.monto : (cuenta?.valorMensual ?? 4000000);
      const montoParcialCentavos = Math.round(montoTotalCentavos / pagosEsperados);

      const desglose: any[] = [];
      let currentYear = hoy.getFullYear();
      let currentMonth = hoy.getMonth(); // 0-indexed

      const mesesEsp = [
        'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
      ];

      while (desglose.length < pagosEsperados) {
        const periodStr = `${currentYear}-${String(currentMonth + 1).padStart(2, '0')}-01`;
        const fechas = Periodo.fechasCobroParciales(modalidad, currentYear, currentMonth);
        const mesNombre = mesesEsp[currentMonth];

        for (let i = 0; i < fechas.length; i++) {
          if (desglose.length >= pagosEsperados) break;
          if (fechas[i] >= hoyStr) {
            desglose.push({
              id: `future-${periodStr}-${i + 1}`,
              cobroId: null,
              fecha: fechas[i],
              monto: Math.round(montoParcialCentavos / 100),
              numeroPago: i + 1,
              mes: mesNombre,
            });
          }
        }

        currentMonth++;
        if (currentMonth > 11) {
          currentMonth = 0;
          currentYear++;
        }
      }

      if (desglose.length > 0) {
        proximoCobro = desglose[0].fecha;
        proximoPago = {
          concepto: `${desglose[0].mes} — Cuota 1`,
          fechaVencimiento: proximoCobro ?? hoyStr,
          monto: Math.round(montoParcialCentavos / 100),
          montoTotal: Math.round(montoTotalCentavos / 100),
          montoPagado: 0,
          pagosEsperados,
          pagosRegistrados: 0,
          montoParcial: Math.round(montoParcialCentavos / 100),
          desglose,
        };
      }
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
    for (const cobro of cobros) {
      movimientos.push({
        id: cobro.id,
        tipo: 'cargo',
        monto: Math.round(cobro.monto / 100),
        fecha: cobro.periodoInicio,
        descripcion: `Generación de cobro ${cobro.concepto}`,
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

    const montoTarifaBase = tarifaMensual
      ? Math.round(tarifaMensual.monto / 100)
      : (cuenta?.valorMensual ? Math.round(cuenta.valorMensual / 100) : 40000);

    const tarifaActual = {
      cobroMensual: montoTarifaBase,
      cuotaMensual: montoTarifaBase,
      montoSegunModalidad: tarifaPropia
        ? Math.round(tarifaPropia.monto / 100)
        : Math.round(montoTarifaBase / (modalidad === 'SEMANAL' ? 4 : modalidad === 'QUINCENAL' ? 2 : 1)),
      modalidad: modalidad,
    };

    return {
      saldo: saldoFrontend,
      status,
      proximoCobro,
      proximoPago,
      tarifaActual,
      ultimoPago,
      movimientos: movimientos.slice(0, 2),
      residenteInfo,
    };
  }

  @Get(['dashboard/residente/timeline', 'dashboard/propietario/timeline'])
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.RESIDENTE)
  async getResidenteTimeline(
    @CurrentUser() user: Usuario,
    @CurrentTenant() tenantId: string,
    @Query('offset', new DefaultValuePipe(0), ParseIntPipe) offset: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
  ): Promise<TimelineResponse> {
    if (!user.residenteId) {
      return {
        items: [],
        hasMore: false,
      };
    }

    const [pagos, solicitudes] = await Promise.all([
      this.pagoRepository.findByPropietario(user.residenteId, tenantId),
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
