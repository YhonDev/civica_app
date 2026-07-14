import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe, ClassSerializerInterceptor } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import request from 'supertest';
import { DataSource } from 'typeorm';
import { hashSync as bcryptHashSync } from 'bcrypt';
import { randomUUID } from 'node:crypto';

import { AppModule } from '../src/app.module';

jest.setTimeout(30000);

/**
 * Integration tests for Dashboard endpoints (Sprint 5).
 *
 * Covers:
 * - GET /dashboard/administrador (admin dashboard with KPIs, evolution, modalidades, etc.)
 * - GET /dashboard/cobrador (collector dashboard with assigned viviendas)
 * - GET /dashboard/propietario (property owner dashboard)
 * - Auth validation (no JWT, wrong role)
 * - Edge cases (no data, empty tenant, cross-tenant isolation)
 */
describe('Dashboard API Integration — Sprint 5 (Admin Dashboard)', () => {
  let app: INestApplication;
  let dataSource: DataSource;

  // ── Shared IDs ───────────────────────────────────────────
  let tenantA: string;
  let tenantB: string;
  let conjuntoA: string;
  let etapaA: string;
  let etapaB: string;
  let manzanaA: string;
  let manzanaB: string;
  let casaA: string;
  let casaB: string;
  let propietarioAlDia: string;
  let propietarioMora: string;
  let propietarioSinCuenta: string;
  let tenenciaAlDia: string;
  let tenenciaMora: string;
  let adminUserId: string;
  let cobradorUserId: string;
  let propietarioUserId: string;

  // ── Quota IDs (referenced by pagos and solicitudes) ──────
  let cuotaPendienteId: string;
  let cuotaPagadaId: string;
  let cuotaVencidaId: string;

  // ── Auth tokens ──────────────────────────────────────────
  let adminToken: string;
  let cobradorToken: string;
  let propietarioToken: string;

  // ── Date helpers ─────────────────────────────────────────
  const now = new Date();
  const currentMonth = now.getMonth() + 1; // 1-indexed
  const currentYear = now.getFullYear();
  const thisMonthStart = `${currentYear}-${String(currentMonth).padStart(2, '0')}-01`;

  // Helper: date → YYYY-MM-DD string
  const fmtYMD = (d: Date): string =>
    `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;

  // Helper: add N days to a date string
  const addDaysStr = (dateStr: string, days: number): string => {
    const d = new Date(dateStr);
    d.setDate(d.getDate() + days);
    return fmtYMD(d);
  };

  // Helper: subtract N days from a Date
  const subDaysDate = (d: Date, days: number): Date => {
    const copy = new Date(d);
    copy.setDate(copy.getDate() - days);
    return copy;
  };

  // Helper: short month name in Spanish
  const mesNombre = (date: Date): string => {
    const nombres = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return nombres[date.getMonth()];
  };

  // Last month (handles January → December wrapping)
  const lastMonth = currentMonth === 1 ? 12 : currentMonth - 1;
  const lastMonthYear = currentMonth === 1 ? currentYear - 1 : currentYear;
  const lastMonthStart = `${lastMonthYear}-${String(lastMonth).padStart(2, '0')}-01`;



  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    app.useGlobalInterceptors(new ClassSerializerInterceptor(app.get(Reflector)));
    await app.init();

    dataSource = app.get(DataSource);

    // ── Generate all IDs ─────────────────────────────────
    tenantA = randomUUID();
    tenantB = randomUUID();
    conjuntoA = randomUUID();
    const conjuntoB = randomUUID();
    etapaA = randomUUID();
    etapaB = randomUUID();
    manzanaA = randomUUID();
    manzanaB = randomUUID();
    casaA = randomUUID();
    casaB = randomUUID();
    const casaC = randomUUID();
    propietarioAlDia = randomUUID();
    propietarioMora = randomUUID();
    propietarioSinCuenta = randomUUID();
    tenenciaAlDia = randomUUID();
    tenenciaMora = randomUUID();
    adminUserId = randomUUID();
    cobradorUserId = randomUUID();
    propietarioUserId = randomUUID();
    cuotaPendienteId = randomUUID();
    cuotaPagadaId = randomUUID();
    cuotaVencidaId = randomUUID();

    // ════════════════════════════════════════════════════════════
    // 1. Seed Community Data (Tenant A)
    // ════════════════════════════════════════════════════════════
    await dataSource.query(
      `INSERT INTO conjuntos (id, nombre, tenant_id) VALUES ($1, $2, $3)`,
      [conjuntoA, 'Residencial Dashboard Test', tenantA],
    );
    await dataSource.query(
      `INSERT INTO conjuntos (id, nombre, tenant_id) VALUES ($1, $2, $3)`,
      [conjuntoB, 'Otro Conjunto', tenantA],
    );
    await dataSource.query(
      `INSERT INTO etapas (id, nombre, conjunto_id) VALUES ($1, $2, $3)`,
      [etapaA, 'Etapa Alfa', conjuntoA],
    );
    await dataSource.query(
      `INSERT INTO etapas (id, nombre, conjunto_id) VALUES ($1, $2, $3)`,
      [etapaB, 'Etapa Beta', conjuntoB],
    );
    await dataSource.query(
      `INSERT INTO manzanas (id, nombre, etapa_id) VALUES ($1, $2, $3)`,
      [manzanaA, 'Manzana 1', etapaA],
    );
    await dataSource.query(
      `INSERT INTO manzanas (id, nombre, etapa_id) VALUES ($1, $2, $3)`,
      [manzanaB, 'Manzana 2', etapaB],
    );
    await dataSource.query(
      `INSERT INTO casas (id, direccion_interna, manzana_id) VALUES ($1, $2, $3)`,
      [casaA, 'Casa 101', manzanaA],
    );
    await dataSource.query(
      `INSERT INTO casas (id, direccion_interna, manzana_id) VALUES ($1, $2, $3)`,
      [casaB, 'Casa 102', manzanaA],
    );
    await dataSource.query(
      `INSERT INTO casas (id, direccion_interna, manzana_id) VALUES ($1, $2, $3)`,
      [casaC, 'Casa 201', manzanaB],
    );

    // ── Propietarios ──────────────────────────────────────
    await dataSource.query(
      `INSERT INTO propietarios (id, nombre, telefono, tenant_id, created_at)
       VALUES ($1, $2, $3, $4, $5)`,
      [propietarioAlDia, 'Juan Al Día', '555-0101', tenantA, subDaysDate(now, 2)],
    );
    await dataSource.query(
      `INSERT INTO propietarios (id, nombre, telefono, tenant_id, created_at)
       VALUES ($1, $2, $3, $4, $5)`,
      [propietarioMora, 'Pedro En Mora', '555-0102', tenantA, subDaysDate(now, 30)],
    );
    await dataSource.query(
      `INSERT INTO propietarios (id, nombre, telefono, tenant_id)
       VALUES ($1, $2, $3, $4)`,
      [propietarioSinCuenta, 'Sin Cuenta', '555-0103', tenantA],
    );

    // ── Tenencias ─────────────────────────────────────────
    await dataSource.query(
      `INSERT INTO tenencias (id, propietario_id, casa_id, fecha_inicio)
       VALUES ($1, $2, $3, $4)`,
      [tenenciaAlDia, propietarioAlDia, casaA, '2026-01-01'],
    );
    await dataSource.query(
      `INSERT INTO tenencias (id, propietario_id, casa_id, fecha_inicio)
       VALUES ($1, $2, $3, $4)`,
      [tenenciaMora, propietarioMora, casaB, '2026-01-01'],
    );

    // ════════════════════════════════════════════════════════════
    // 2. Seed IAM Data
    // ════════════════════════════════════════════════════════════
    const adminHash = bcryptHashSync('admin123', 10);
    const cobradorHash = bcryptHashSync('cobrador123', 10);
    const propHash = bcryptHashSync('prop123', 10);

    await dataSource.query(
      `INSERT INTO usuarios (id, email, password_hash, nombre, rol, propietario_id, tenant_id, activo)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [adminUserId, 'admin-dash@test.com', adminHash, 'Admin Dashboard', 'ADMIN', null, tenantA, true],
    );
    await dataSource.query(
      `INSERT INTO usuarios (id, email, password_hash, nombre, rol, propietario_id, tenant_id, activo)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [cobradorUserId, 'cobrador-dash@test.com', cobradorHash, 'Cobrador Dashboard', 'COBRADOR', null, tenantA, true],
    );
    await dataSource.query(
      `INSERT INTO usuarios (id, email, password_hash, nombre, rol, propietario_id, tenant_id, activo)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [propietarioUserId, 'prop-dash@test.com', propHash, 'Prop Dashboard', 'PROPIETARIO', propietarioAlDia, tenantA, true],
    );

    // ── Asignar etapa al cobrador ─────────────────────────
    await dataSource.query(
      `INSERT INTO asignaciones_etapa (id, usuario_id, etapa_id, tenant_id)
       VALUES ($1, $2, $3, $4)`,
      [randomUUID(), cobradorUserId, etapaA, tenantA],
    );

    // ════════════════════════════════════════════════════════════
    // 3. Seed Ledger Data (Tarifas, Cuentas Cartera, Cuotas)
    // ════════════════════════════════════════════════════════════
    const tarifaMensualId = randomUUID();
    const tarifaQuincenalId = randomUUID();

    // ── Tarifas ───────────────────────────────────────────
    // Montos en centavos: 40000 COP = 4000000 centavos
    await dataSource.query(
      `INSERT INTO tarifas (id, tenant_id, conjunto_id, frecuencia, monto, fecha_vigencia)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [tarifaMensualId, tenantA, conjuntoA, 'MENSUAL', 4000000, '2026-01-01'],
    );
    await dataSource.query(
      `INSERT INTO tarifas (id, tenant_id, conjunto_id, frecuencia, monto, fecha_vigencia)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [tarifaQuincenalId, tenantA, conjuntoA, 'QUINCENAL', 2000000, '2026-01-01'],
    );

    // ── Cuentas de Cartera ────────────────────────────────
    await dataSource.query(
      `INSERT INTO cuentas_cartera (id, propietario_id, tenant_id, conjunto_id, frecuencia, fecha_activacion)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [randomUUID(), propietarioAlDia, tenantA, conjuntoA, 'MENSUAL', '2026-01-01'],
    );
    await dataSource.query(
      `INSERT INTO cuentas_cartera (id, propietario_id, tenant_id, conjunto_id, frecuencia, fecha_activacion)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [randomUUID(), propietarioMora, tenantA, conjuntoA, 'MENSUAL', '2026-01-01'],
    );

    // ── Cuotas ────────────────────────────────────────────
    // Propietario Al Día: 1 cuota pagada (this month) + 1 cuota pendiente (next month)
    // Propietario Mora: 1 cuota vencida (last month) + 1 cuota pendiente (this month)

    // Cuota PAGADA (propietarioAlDia, current month)
    await dataSource.query(
      `INSERT INTO cuotas (id, propietario_id, tenant_id, tarifa_id, concepto,
        monto, monto_pagado, periodo_inicio, periodo_fin, fecha_vencimiento, estado)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
      [cuotaPagadaId, propietarioAlDia, tenantA, tarifaMensualId,
        `Cuota ${mesNombre(now)} ${currentYear}`, 4000000, 4000000,
        thisMonthStart,
        addDaysStr(thisMonthStart, 30),
        addDaysStr(thisMonthStart, 15),
        'PAGADA'],
    );

    // Cuota PENDIENTE (propietarioMora, current month)
    await dataSource.query(
      `INSERT INTO cuotas (id, propietario_id, tenant_id, tarifa_id, concepto,
        monto, monto_pagado, periodo_inicio, periodo_fin, fecha_vencimiento, estado)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
      [cuotaPendienteId, propietarioMora, tenantA, tarifaMensualId,
        `Cuota ${mesNombre(now)} ${currentYear}`, 4000000, 0,
        thisMonthStart,
        addDaysStr(thisMonthStart, 30),
        addDaysStr(thisMonthStart, 15),
        'PENDIENTE'],
    );

    // Cuota VENCIDA (propietarioMora, last month)

    await dataSource.query(
      `INSERT INTO cuotas (id, propietario_id, tenant_id, tarifa_id, concepto,
        monto, monto_pagado, periodo_inicio, periodo_fin, fecha_vencimiento, estado)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
      [cuotaVencidaId, propietarioMora, tenantA, tarifaMensualId,
        `Cuota ${mesNombre(new Date(lastMonthYear, lastMonth - 1))} ${lastMonthYear}`, 4000000, 0,
        lastMonthStart,
        addDaysStr(lastMonthStart, 15),  // periodo_fin dentro del mes anterior
        `${lastMonthYear}-${String(lastMonth).padStart(2, '0')}-15`,
        'VENCIDA'],
    );

    // ════════════════════════════════════════════════════════════
    // 4. Seed Pagos
    // ════════════════════════════════════════════════════════════
    // Pago for cuotaPagadaId (propietarioAlDia pagó complete)
    const pagoDate = `${currentYear}-${String(currentMonth).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
    await dataSource.query(
      `INSERT INTO pagos (id, client_payment_id, tenant_id, cuota_id, monto, fecha_pago, cobrador_id, propietario_id)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [randomUUID(), `dash-pago-${randomUUID()}`, tenantA, cuotaPagadaId,
        4000000, pagoDate, cobradorUserId, propietarioAlDia],
    );

    // ════════════════════════════════════════════════════════════
    // 5. Seed Actividad
    // ════════════════════════════════════════════════════════════
    await dataSource.query(
      `INSERT INTO actividad (id, tenant_id, tipo, descripcion, usuario_nombre, usuario_id)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [randomUUID(), conjuntoA, 'pago_registrado', 'Pagó la cuota mensual', 'Juan Al Día', propietarioUserId],
    );
    await dataSource.query(
      `INSERT INTO actividad (id, tenant_id, tipo, descripcion, usuario_nombre, usuario_id)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [randomUUID(), conjuntoA, 'nuevo_propietario', 'Se registró en la plataforma', 'Juan Al Día', propietarioUserId],
    );

    // ════════════════════════════════════════════════════════════
    // 6. Seed Solicitudes
    // ════════════════════════════════════════════════════════════
    await dataSource.query(
      `INSERT INTO solicitudes (id, tenant_id, usuario_id, cuota_id, nro_recibo, tipo, descripcion, estado)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [randomUUID(), tenantA, propietarioUserId, cuotaPendienteId,
       'REC-001', 'REVISION_PAGO', 'Solicito revisión de mi pago', 'PENDIENTE'],
    );
    await dataSource.query(
      `INSERT INTO solicitudes (id, tenant_id, usuario_id, cuota_id, nro_recibo, tipo, descripcion, estado)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [randomUUID(), tenantA, propietarioUserId, cuotaVencidaId,
       'REC-002', 'DESCUENTO', ' Solicito descuento por pronto pago', 'PENDIENTE'],
    );

    // ════════════════════════════════════════════════════════════
    // 7. Seed Tenant B (for isolation test)
    // ════════════════════════════════════════════════════════════
    await dataSource.query(
      `INSERT INTO conjuntos (id, nombre, tenant_id) VALUES ($1, $2, $3)`,
      [randomUUID(), 'Conjunto Tenant B', tenantB],
    );
    const adminBId = randomUUID();
    const adminBHash = bcryptHashSync('adminB123', 10);
    await dataSource.query(
      `INSERT INTO usuarios (id, email, password_hash, nombre, rol, propietario_id, tenant_id, activo)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [adminBId, 'admin-b@test.com', adminBHash, 'Admin Tenant B', 'ADMIN', null, tenantB, true],
    );

    // ════════════════════════════════════════════════════════════
    // 8. Login — get admin token
    // ════════════════════════════════════════════════════════════
    const adminLoginRes = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: 'admin-dash@test.com', password: 'admin123' })
      .expect(201);
    adminToken = adminLoginRes.body.accessToken;

    const cobradorLoginRes = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: 'cobrador-dash@test.com', password: 'cobrador123' })
      .expect(201);
    cobradorToken = cobradorLoginRes.body.accessToken;

    const propLoginRes = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: 'prop-dash@test.com', password: 'prop123' })
      .expect(201);
    propietarioToken = propLoginRes.body.accessToken;
  });

  afterAll(async () => {
    // Clean up in FK-safe order
    await dataSource.query(`DELETE FROM pagos WHERE tenant_id IN ($1, $2)`, [tenantA, tenantB]);
    await dataSource.query(`DELETE FROM solicitudes WHERE tenant_id IN ($1, $2)`, [tenantA, tenantB]);
    await dataSource.query(`DELETE FROM actividad WHERE tenant_id IN ($1, $2)`, [tenantA, tenantB]);
    await dataSource.query(`DELETE FROM cuotas WHERE tenant_id IN ($1, $2)`, [tenantA, tenantB]);
    await dataSource.query(`DELETE FROM cuentas_cartera WHERE tenant_id IN ($1, $2)`, [tenantA, tenantB]);
    await dataSource.query(`DELETE FROM tarifas WHERE tenant_id IN ($1, $2)`, [tenantA, tenantB]);
    await dataSource.query(`DELETE FROM asignaciones_etapa WHERE tenant_id IN ($1, $2)`, [tenantA, tenantB]);
    await dataSource.query(`DELETE FROM usuarios WHERE tenant_id IN ($1, $2)`, [tenantA, tenantB]);
    await dataSource.query(`DELETE FROM tenencias WHERE propietario_id IN ($1, $2, $3)`,
      [propietarioAlDia, propietarioMora, propietarioSinCuenta]);
    await dataSource.query(`DELETE FROM propietarios WHERE tenant_id IN ($1, $2)`, [tenantA, tenantB]);
    await dataSource.query(`DELETE FROM casas WHERE manzana_id IN ($1, $2)`, [manzanaA, manzanaB]);
    await dataSource.query(`DELETE FROM manzanas WHERE etapa_id IN ($1, $2)`, [etapaA, etapaB]);
    await dataSource.query(`DELETE FROM etapas WHERE conjunto_id IN (SELECT id FROM conjuntos WHERE tenant_id IN ($1, $2))`, [tenantA, tenantB]);
    await dataSource.query(`DELETE FROM conjuntos WHERE tenant_id IN ($1, $2)`, [tenantA, tenantB]);

    await app.close();
  });

  // ═══════════════════════════════════════════════════════════════
  // 1. GET /dashboard/administrador — Admin Dashboard
  // ═══════════════════════════════════════════════════════════════

  describe('GET /dashboard/administrador', () => {
    it('1.1 Debe retornar 200 con estructura completa del dashboard', async () => {
      const res = await request(app.getHttpServer())
        .get(`/dashboard/administrador?mes=${currentMonth}&anio=${currentYear}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      // ── Top-level structure ───────────────────────────────
      expect(res.body).toHaveProperty('mes', currentMonth);
      expect(res.body).toHaveProperty('anio', currentYear);
      expect(res.body).toHaveProperty('resumen');
      expect(res.body).toHaveProperty('evolucion');
      expect(res.body).toHaveProperty('modalidades');
      expect(res.body).toHaveProperty('estadoCobros');
      expect(res.body).toHaveProperty('actividad');
      expect(res.body).toHaveProperty('solicitudesPendientes');
      expect(res.body).toHaveProperty('nuevosPropietariosSemana');
      expect(res.body).toHaveProperty('propietariosMora');
      expect(res.body).toHaveProperty('acumuladoAnual');
      expect(res.body).toHaveProperty('metaAnual');
      expect(res.body).toHaveProperty('historialMeses');
      expect(res.body).toHaveProperty('cobrosPorSemana');
    });

    it('1.2 Resumen debe reflejar los datos seedeados', async () => {
      const res = await request(app.getHttpServer())
        .get(`/dashboard/administrador?mes=${currentMonth}&anio=${currentYear}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      const { resumen } = res.body;

      // recaudoTotal: 4000000 (pago del propietarioAlDia)
      expect(resumen.recaudoTotal).toBe(4000000);

      // metaMensual: suma de cuotas del mes = 4000000 (cuotaPagada) + 4000000 (cuotaPendiente) = 8000000
      // Wait — cuotaPagada and cuotaPendiente are both for this month
      // cuotaPagada: 4000000, cuotaPendiente: 4000000 => metaMensual = 8000000
      expect(resumen.metaMensual).toBe(8000000);

      // porcentajeMeta = round((4000000 / 8000000) * 10000) / 100 = 50
      expect(resumen.porcentajeMeta).toBe(50);

      // pagaron: 1 (solo propietarioAlDia pagó)
      expect(resumen.pagaron).toBe(1);

      // pendientes: 1 (propietarioMora tiene cuota pendiente este mes)
      // countPendientesByMonth counts DISTINCT propietarioId with estado IN ('PENDIENTE','PARCIAL','VENCIDA')
      expect(resumen.pendientes).toBeGreaterThanOrEqual(1);

      // moraTotal: saldo de cuota VENCIDA = 4000000
      // cuotaVencida monto=4000000, monto_pagado=0
      // sumSaldoVencidasByTenant = SUM(monto - montoPagado) = 4000000
      expect(resumen.moraTotal).toBe(4000000);
    });

    it('1.3 Evolución diaria debe contener días con pagos', async () => {
      const res = await request(app.getHttpServer())
        .get(`/dashboard/administrador?mes=${currentMonth}&anio=${currentYear}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      const { evolucion } = res.body;
      expect(Array.isArray(evolucion)).toBe(true);

      // El pago se registró hoy, por lo que debe aparecer en la evolución
      const today = now.getDate();
      const todayEntry = evolucion.find((e: { dia: number }) => e.dia === today);
      expect(todayEntry).toBeDefined();
      expect(todayEntry.valor).toBe(4000000);
    });

    it('1.4 Modalidades debe desglosar por frecuencia de tarifa', async () => {
      const res = await request(app.getHttpServer())
        .get(`/dashboard/administrador?mes=${currentMonth}&anio=${currentYear}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      const { modalidades } = res.body;
      expect(Array.isArray(modalidades)).toBe(true);

      // Debemos ver al menos una modalidad (MENSUAL)
      const mensual = modalidades.find((m: { frecuencia: string }) => m.frecuencia === 'MENSUAL');
      expect(mensual).toBeDefined();
      expect(mensual.totalCuotas).toBeGreaterThanOrEqual(2);
      expect(mensual.pagadas).toBeGreaterThanOrEqual(1);
    });

    it('1.5 Estado de cobros muestra porcentajes', async () => {
      const res = await request(app.getHttpServer())
        .get(`/dashboard/administrador?mes=${currentMonth}&anio=${currentYear}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      const { estadoCobros } = res.body;
      expect(estadoCobros).toHaveProperty('pagados');
      expect(estadoCobros).toHaveProperty('pendientes');
      expect(estadoCobros).toHaveProperty('revision');
      expect(typeof estadoCobros.pagados).toBe('number');
      expect(typeof estadoCobros.pendientes).toBe('number');
    });

    it('1.6 Actividad reciente contiene los eventos semilla', async () => {
      const res = await request(app.getHttpServer())
        .get(`/dashboard/administrador?mes=${currentMonth}&anio=${currentYear}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      const { actividad } = res.body;
      expect(Array.isArray(actividad)).toBe(true);
      expect(actividad.length).toBeGreaterThanOrEqual(2);

      // Verificar estructura de cada item
      for (const item of actividad) {
        expect(item).toHaveProperty('id');
        expect(item).toHaveProperty('tipo');
        expect(item).toHaveProperty('descripcion');
        expect(item).toHaveProperty('usuario');
        expect(item).toHaveProperty('timestamp');
        expect(item).toHaveProperty('hace');
      }
    });

    it('1.7 Solicitudes pendientes refleja las seedeadas', async () => {
      const res = await request(app.getHttpServer())
        .get(`/dashboard/administrador?mes=${currentMonth}&anio=${currentYear}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      // Seed: 2 solicitudes PENDIENTES para propietarioAlDia
      expect(res.body.solicitudesPendientes).toBe(2);
    });

    it('1.8 Nuevos propietarios de la semana', async () => {
      const res = await request(app.getHttpServer())
        .get(`/dashboard/administrador?mes=${currentMonth}&anio=${currentYear}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      // propietarioAlDia fue creado hace 2 días (within last week)
      expect(res.body.nuevosPropietariosSemana).toBeGreaterThanOrEqual(1);
    });

    it('1.9 Propietarios en mora', async () => {
      const res = await request(app.getHttpServer())
        .get(`/dashboard/administrador?mes=${currentMonth}&anio=${currentYear}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      // Solo propietarioMora tiene cuota VENCIDA
      expect(res.body.propietariosMora).toBe(1);
    });

    it('1.10 Historial mensual contiene 12 meses', async () => {
      const res = await request(app.getHttpServer())
        .get(`/dashboard/administrador?mes=${currentMonth}&anio=${currentYear}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      const { historialMeses } = res.body;
      expect(Array.isArray(historialMeses)).toBe(true);
      expect(historialMeses.length).toBe(12);

      // Cada mes debe tener la estructura correcta
      for (const mes of historialMeses) {
        expect(mes).toHaveProperty('mes');
        expect(mes).toHaveProperty('anio');
        expect(mes).toHaveProperty('recaudo');
        expect(mes).toHaveProperty('pendientes');
        expect(mes).toHaveProperty('mora');
      }
    });

    it('1.11 Cobros por semana', async () => {
      const res = await request(app.getHttpServer())
        .get(`/dashboard/administrador?mes=${currentMonth}&anio=${currentYear}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      const { cobrosPorSemana } = res.body;
      expect(Array.isArray(cobrosPorSemana)).toBe(true);

      for (const semana of cobrosPorSemana) {
        expect(semana).toHaveProperty('semana');
        expect(semana).toHaveProperty('pagados');
        expect(semana).toHaveProperty('pendientes');
        expect(semana).toHaveProperty('mora');
      }
    });

    it('1.12 Acumulado anual refleja pagos del año', async () => {
      const res = await request(app.getHttpServer())
        .get(`/dashboard/administrador?mes=${currentMonth}&anio=${currentYear}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      // Solo hay 1 pago de 4000000 este año
      expect(res.body.acumuladoAnual).toBeGreaterThanOrEqual(4000000);

      // Meta anual: suma de montos de cuotas con periodoInicio este año
      expect(res.body.metaAnual).toBeGreaterThanOrEqual(8000000);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 2. Auth & Authorization
  // ═══════════════════════════════════════════════════════════════

  describe('Authorization', () => {
    it('2.1 Sin JWT → 401', async () => {
      const res = await request(app.getHttpServer())
        .get(`/dashboard/administrador?mes=${currentMonth}&anio=${currentYear}`)
        .expect(401);

      expect(res.body).toHaveProperty('message');
    });

    it('2.2 Con rol COBRADOR → 403 en admin dashboard', async () => {
      const res = await request(app.getHttpServer())
        .get(`/dashboard/administrador?mes=${currentMonth}&anio=${currentYear}`)
        .set('Authorization', `Bearer ${cobradorToken}`)
        .expect(403);

      expect(res.body).toHaveProperty('message');
    });

    it('2.3 Con rol PROPIETARIO → 403 en admin dashboard', async () => {
      const res = await request(app.getHttpServer())
        .get(`/dashboard/administrador?mes=${currentMonth}&anio=${currentYear}`)
        .set('Authorization', `Bearer ${propietarioToken}`)
        .expect(403);

      expect(res.body).toHaveProperty('message');
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 3. Edge Cases
  // ═══════════════════════════════════════════════════════════════

  describe('Edge cases', () => {
    it('3.1 Mes sin datos retorna resumen en cero', async () => {
      const res = await request(app.getHttpServer())
        .get('/dashboard/administrador?mes=1&anio=2020')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(res.body.resumen.recaudoTotal).toBe(0);
      expect(res.body.resumen.metaMensual).toBe(0);
      expect(res.body.resumen.porcentajeMeta).toBe(0);
      expect(res.body.resumen.pagaron).toBe(0);
      expect(res.body.evolucion).toEqual([]);
      expect(res.body.cobrosPorSemana).toEqual([]);
    });

    it('3.2 Año sin pagos retorna acumuladoAnual en cero', async () => {
      const res = await request(app.getHttpServer())
        .get('/dashboard/administrador?mes=6&anio=2019')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(res.body.acumuladoAnual).toBe(0);
    });

    it('3.3 Multi-tenant isolation: tenant B no ve datos de tenant A', async () => {
      // Login as admin of tenant B
      const loginB = await request(app.getHttpServer())
        .post('/auth/login')
        .send({ email: 'admin-b@test.com', password: 'adminB123' })
        .expect(201);
      const tokenB = loginB.body.accessToken;

      const res = await request(app.getHttpServer())
        .get(`/dashboard/administrador?mes=${currentMonth}&anio=${currentYear}`)
        .set('Authorization', `Bearer ${tokenB}`)
        .expect(200);

      // Tenant B has no data seeded — should be zeros
      expect(res.body.resumen.recaudoTotal).toBe(0);
      expect(res.body.resumen.metaMensual).toBe(0);
      expect(res.body.resumen.pagaron).toBe(0);
      expect(res.body.solicitudesPendientes).toBe(0);
      expect(res.body.nuevosPropietariosSemana).toBe(0);
      expect(res.body.propietariosMora).toBe(0);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 4. GET /dashboard/cobrador — Cobrador Dashboard
  // ═══════════════════════════════════════════════════════════════

  describe('GET /dashboard/cobrador', () => {
    it('4.1 Debe retornar estructura del dashboard del cobrador', async () => {
      const res = await request(app.getHttpServer())
        .get('/dashboard/cobrador')
        .set('Authorization', `Bearer ${cobradorToken}`)
        .expect(200);

      expect(res.body).toHaveProperty('cobrador');
      expect(res.body).toHaveProperty('stats');
      expect(res.body).toHaveProperty('viviendas');
      expect(res.body).toHaveProperty('ultimosCobros');

      expect(res.body.cobrador.nombre).toBe('Cobrador Dashboard');
      expect(res.body.stats).toHaveProperty('pendientes');
      expect(res.body.stats).toHaveProperty('montoEsperado');
      expect(res.body.stats).toHaveProperty('cobradosHoy');
      expect(res.body.stats).toHaveProperty('montoCobradoHoy');
    });

    it('4.2 Viviendas asignadas deben incluir las de la etapa asignada', async () => {
      const res = await request(app.getHttpServer())
        .get('/dashboard/cobrador')
        .set('Authorization', `Bearer ${cobradorToken}`)
        .expect(200);

      const { viviendas } = res.body;
      expect(Array.isArray(viviendas)).toBe(true);
      expect(viviendas.length).toBeGreaterThanOrEqual(1);

      // Debe incluir propietarioMora (tiene cuota pendiente en etapaA)
      const moraVivienda = viviendas.find(
        (v: { propietarioId: string }) => v.propietarioId === propietarioMora,
      );
      expect(moraVivienda).toBeDefined();
      expect(moraVivienda.etapaNombre).toBe('Etapa Alfa');
    });

    it('4.3 ADMIN no puede acceder al dashboard del cobrador', async () => {
      const res = await request(app.getHttpServer())
        .get('/dashboard/cobrador')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(403);

      expect(res.body).toHaveProperty('message');
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 5. GET /dashboard/propietario — Propietario Dashboard
  // ═══════════════════════════════════════════════════════════════

  describe('GET /dashboard/propietario', () => {
    it('5.1 Debe retornar dashboard del propietario autenticado', async () => {
      const res = await request(app.getHttpServer())
        .get('/dashboard/propietario')
        .set('Authorization', `Bearer ${propietarioToken}`)
        .expect(200);

      expect(res.body).toHaveProperty('saldo');
      expect(res.body).toHaveProperty('status');
      expect(res.body).toHaveProperty('proximoCobro');
      expect(res.body).toHaveProperty('ultimoPago');
      expect(res.body).toHaveProperty('movimientos');
    });

    it('5.2 Propietario al día debe tener status AL_DIA o PENDIENTE', async () => {
      const res = await request(app.getHttpServer())
        .get('/dashboard/propietario')
        .set('Authorization', `Bearer ${propietarioToken}`)
        .expect(200);

      // propietarioAlDia tiene 1 cuota PAGADA this month
      // y NO tiene cuotas VENCIDAS → status debería ser AL_DIA
      // Wait — propietarioAlDia has one PAGADA cuota for this month
      // So his saldo should be 0 because his only cuota is paid
      expect(res.body.saldo).toBe(0);
      expect(['AL_DIA', 'PENDIENTE']).toContain(res.body.status);
      // If no pending cuotas → AL_DIA
      expect(res.body.status).toBe('AL_DIA');
    });

    it('5.3 ADMIN no puede acceder al dashboard del propietario', async () => {
      const res = await request(app.getHttpServer())
        .get('/dashboard/propietario')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(403);

      expect(res.body).toHaveProperty('message');
    });

    it('5.4 Debe retornar propietarioInfo con nombre, casaDireccion y etapaNombre', async () => {
      const res = await request(app.getHttpServer())
        .get('/dashboard/propietario')
        .set('Authorization', `Bearer ${propietarioToken}`)
        .expect(200);

      expect(res.body).toHaveProperty('propietarioInfo');
      expect(res.body.propietarioInfo).toHaveProperty('nombre');
      expect(res.body.propietarioInfo).toHaveProperty('casaDireccion');
      expect(res.body.propietarioInfo).toHaveProperty('etapaNombre');

      // propietarioAlDia tiene tenencia → casaA → manzanaA → etapaA
      expect(res.body.propietarioInfo.nombre).toBe('Juan Al Día');
      expect(res.body.propietarioInfo.casaDireccion).toBeTruthy();
      expect(res.body.propietarioInfo.etapaNombre).toBe('Etapa Alfa');
    });


  });
});
