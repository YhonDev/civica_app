import { Test, TestingModule } from '@nestjs/testing';
import {
  INestApplication,
  ValidationPipe,
  ClassSerializerInterceptor,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import request from 'supertest';
import { DataSource } from 'typeorm';
import { hashSync as bcryptHashSync } from 'bcrypt';
import { randomUUID } from 'node:crypto';

import { AppModule } from '../src/app.module';
import { limpiarTenant, purgarEmails } from './helpers/test-db';

jest.setTimeout(30000);

/**
 * Integration tests for Dashboard endpoints.
 *
 * Covers:
 * - GET /dashboard/administrador (KPIs, evolución, modalidades, estados, etc.)
 * - GET /dashboard/cobrador (viviendas asignadas)
 * - GET /dashboard/residente (alias /dashboard/propietario)
 * - Auth validation (no JWT, wrong role)
 * - Edge cases (mes sin datos, aislamiento multi-tenant)
 */
describe('Dashboard API Integration (Admin Dashboard)', () => {
  let app: INestApplication;
  let dataSource: DataSource;

  // ── Shared IDs ───────────────────────────────────────────
  let tenantA: string;
  let tenantB: string;
  let etapaA: string;
  let manzanaA: string;
  let manzanaB: string;
  let residenteAlDia: string;
  let residenteMora: string;
  let adminUserId: string;
  let cobradorUserId: string;
  let residenteUserId: string;
  let cobroPagadaId: string;
  let cobroPendienteId: string;
  let cobroVencidaId: string;

  // ── Auth tokens ──────────────────────────────────────────
  let adminToken: string;
  let cobradorToken: string;
  let residenteToken: string;

  // ── Date helpers ─────────────────────────────────────────
  const now = new Date();
  const currentMonth = now.getMonth() + 1; // 1-indexed
  const currentYear = now.getFullYear();
  const thisMonthStart = `${currentYear}-${String(currentMonth).padStart(2, '0')}-01`;

  const addDaysStr = (dateStr: string, days: number): string => {
    const d = new Date(dateStr);
    d.setDate(d.getDate() + days);
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  };

  const mesNombre = (date: Date): string => {
    const nombres = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return nombres[date.getMonth()];
  };

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
    app.useGlobalInterceptors(
      new ClassSerializerInterceptor(app.get(Reflector)),
    );
    await app.init();

    dataSource = app.get(DataSource);

    // ── Datos huérfanos de corridas previas ──────────────
    await purgarEmails(dataSource, [
      'admin-dash@test.com',
      'cobrador-dash@test.com',
      'prop-dash@test.com',
      'admin-b@test.com',
    ]);

    // ── Generate all IDs ─────────────────────────────────
    tenantA = randomUUID();
    tenantB = randomUUID();
    const proyectoA = randomUUID();
    const proyectoB = randomUUID();
    etapaA = randomUUID();
    const etapaB = randomUUID();
    manzanaA = randomUUID();
    manzanaB = randomUUID();
    const casaA = randomUUID();
    const casaB = randomUUID();
    const casaC = randomUUID();
    residenteAlDia = randomUUID();
    residenteMora = randomUUID();
    const residenteSinCuenta = randomUUID();
    const tenenciaAlDia = randomUUID();
    const tenenciaMora = randomUUID();
    adminUserId = randomUUID();
    cobradorUserId = randomUUID();
    residenteUserId = randomUUID();
    cobroPagadaId = randomUUID();
    cobroPendienteId = randomUUID();
    cobroVencidaId = randomUUID();

    // ════════════════════════════════════════════════════════
    // 1. Estructura territorial (Tenant A)
    // ════════════════════════════════════════════════════════
    await dataSource.query(
      `INSERT INTO proyectos (id, nombre, tenant_id) VALUES ($1, $2, $3)`,
      [proyectoA, 'Proyecto Dashboard Test', tenantA],
    );
    await dataSource.query(
      `INSERT INTO proyectos (id, nombre, tenant_id) VALUES ($1, $2, $3)`,
      [proyectoB, 'Otro Proyecto', tenantA],
    );
    await dataSource.query(
      `INSERT INTO etapas (id, nombre, proyecto_id) VALUES ($1, $2, $3)`,
      [etapaA, 'Etapa Alfa', proyectoA],
    );
    await dataSource.query(
      `INSERT INTO etapas (id, nombre, proyecto_id) VALUES ($1, $2, $3)`,
      [etapaB, 'Etapa Beta', proyectoB],
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

    // ── Residentes ────────────────────────────────────────
    const hace2Dias = new Date(now);
    hace2Dias.setDate(hace2Dias.getDate() - 2);
    const hace30Dias = new Date(now);
    hace30Dias.setDate(hace30Dias.getDate() - 30);

    await dataSource.query(
      `INSERT INTO residentes (id, nombre, telefono, tenant_id, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $5)`,
      [residenteAlDia, 'Juan Al Día', '555-0101', tenantA, hace2Dias],
    );
    await dataSource.query(
      `INSERT INTO residentes (id, nombre, telefono, tenant_id, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $5)`,
      [residenteMora, 'Pedro En Mora', '555-0102', tenantA, hace30Dias],
    );
    await dataSource.query(
      `INSERT INTO residentes (id, nombre, telefono, tenant_id) VALUES ($1, $2, $3, $4)`,
      [residenteSinCuenta, 'Sin Plan', '555-0103', tenantA],
    );

    // ── Tenencias ─────────────────────────────────────────
    await dataSource.query(
      `INSERT INTO tenencias (id, residente_id, casa_id, fecha_inicio) VALUES ($1, $2, $3, $4)`,
      [tenenciaAlDia, residenteAlDia, casaA, '2026-01-01'],
    );
    await dataSource.query(
      `INSERT INTO tenencias (id, residente_id, casa_id, fecha_inicio) VALUES ($1, $2, $3, $4)`,
      [tenenciaMora, residenteMora, casaB, '2026-01-01'],
    );

    // ════════════════════════════════════════════════════════
    // 2. IAM + asignación del cobrador
    // ════════════════════════════════════════════════════════
    const adminHash = bcryptHashSync('admin123', 10);
    const cobradorHash = bcryptHashSync('cobrador123', 10);
    const residenteHash = bcryptHashSync('prop123', 10);

    await dataSource.query(
      `INSERT INTO usuarios (id, email, password_hash, nombre, rol, residente_id, tenant_id, activo)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [
        adminUserId,
        'admin-dash@test.com',
        adminHash,
        'Admin Dashboard',
        'ADMIN',
        null,
        tenantA,
        true,
      ],
    );
    await dataSource.query(
      `INSERT INTO usuarios (id, email, password_hash, nombre, rol, residente_id, tenant_id, activo)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [
        cobradorUserId,
        'cobrador-dash@test.com',
        cobradorHash,
        'Cobrador Dashboard',
        'COBRADOR',
        null,
        tenantA,
        true,
      ],
    );
    await dataSource.query(
      `INSERT INTO usuarios (id, email, password_hash, nombre, rol, residente_id, tenant_id, activo)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [
        residenteUserId,
        'prop-dash@test.com',
        residenteHash,
        'Residente Dashboard',
        'RESIDENTE',
        residenteAlDia,
        tenantA,
        true,
      ],
    );

    await dataSource.query(
      `INSERT INTO asignaciones_etapa (id, usuario_id, etapa_id, tenant_id) VALUES ($1, $2, $3, $4)`,
      [randomUUID(), cobradorUserId, etapaA, tenantA],
    );

    // ════════════════════════════════════════════════════════
    // 3. Ledger: tarifa, planes de cobro, cobros, pago
    // ════════════════════════════════════════════════════════
    const tarifaMensualId = randomUUID();

    await dataSource.query(
      `INSERT INTO tarifas (id, tenant_id, proyecto_id, modalidad, monto, fecha_vigencia)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [tarifaMensualId, tenantA, proyectoA, 'MENSUAL', 4000000, '2026-01-01'],
    );

    for (const rid of [residenteAlDia, residenteMora]) {
      await dataSource.query(
        `INSERT INTO planes_de_cobro (id, residente_id, tenant_id, proyecto_id, modalidad, valor_mensual, fecha_activacion)
         VALUES ($1, $2, $3, $4, $5, $6, $7)`,
        [
          randomUUID(),
          rid,
          tenantA,
          proyectoA,
          'MENSUAL',
          4000000,
          '2026-01-01',
        ],
      );
    }

    // Cobro PAGADA (Al Día, mes actual)
    await dataSource.query(
      `INSERT INTO cobros (id, residente_id, tenant_id, tarifa_id, concepto,
        monto, monto_pagado, periodo_inicio, periodo_fin, fecha_vencimiento, estado)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
      [
        cobroPagadaId,
        residenteAlDia,
        tenantA,
        tarifaMensualId,
        `Cuota ${mesNombre(now)} ${currentYear}`,
        4000000,
        4000000,
        thisMonthStart,
        addDaysStr(thisMonthStart, 30),
        addDaysStr(thisMonthStart, 15),
        'PAGADA',
      ],
    );

    // Cobro PENDIENTE (Mora, mes actual)
    await dataSource.query(
      `INSERT INTO cobros (id, residente_id, tenant_id, tarifa_id, concepto,
        monto, monto_pagado, periodo_inicio, periodo_fin, fecha_vencimiento, estado)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
      [
        cobroPendienteId,
        residenteMora,
        tenantA,
        tarifaMensualId,
        `Cuota ${mesNombre(now)} ${currentYear}`,
        4000000,
        0,
        thisMonthStart,
        addDaysStr(thisMonthStart, 30),
        addDaysStr(thisMonthStart, 15),
        'PENDIENTE',
      ],
    );

    // Cobro VENCIDA (Mora, mes anterior)
    await dataSource.query(
      `INSERT INTO cobros (id, residente_id, tenant_id, tarifa_id, concepto,
        monto, monto_pagado, periodo_inicio, periodo_fin, fecha_vencimiento, estado)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
      [
        cobroVencidaId,
        residenteMora,
        tenantA,
        tarifaMensualId,
        `Cuota ${mesNombre(new Date(lastMonthYear, lastMonth - 1))} ${lastMonthYear}`,
        4000000,
        0,
        lastMonthStart,
        addDaysStr(lastMonthStart, 15),
        `${lastMonthYear}-${String(lastMonth).padStart(2, '0')}-15`,
        'VENCIDA',
      ],
    );

    // ── Pago (para el cobro PAGADA de Al Día) ─────────────
    await dataSource.query(
      `INSERT INTO pagos (id, client_payment_id, tenant_id, cobro_id, monto, fecha_pago, cobrador_id, residente_id)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [
        randomUUID(),
        `dash-pago-${randomUUID()}`,
        tenantA,
        cobroPagadaId,
        4000000,
        thisMonthStart,
        cobradorUserId,
        residenteAlDia,
      ],
    );

    // ════════════════════════════════════════════════════════
    // 4. Actividad + solicitudes
    // ════════════════════════════════════════════════════════
    await dataSource.query(
      `INSERT INTO actividad (id, tenant_id, tipo, descripcion, usuario_nombre, usuario_id)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [
        randomUUID(),
        tenantA,
        'pago_registrado',
        'Pagó la cuota mensual',
        'Juan Al Día',
        residenteUserId,
      ],
    );
    await dataSource.query(
      `INSERT INTO actividad (id, tenant_id, tipo, descripcion, usuario_nombre, usuario_id)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [
        randomUUID(),
        tenantA,
        'nuevo_residente',
        'Se registró en la plataforma',
        'Juan Al Día',
        residenteUserId,
      ],
    );

    await dataSource.query(
      `INSERT INTO solicitudes (id, tenant_id, usuario_id, cobro_id, nro_recibo, tipo, descripcion, estado)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [
        randomUUID(),
        tenantA,
        residenteUserId,
        cobroPendienteId,
        'REC-001',
        'REVISION_PAGO',
        'Solicito revisión de mi pago',
        'PENDIENTE',
      ],
    );
    await dataSource.query(
      `INSERT INTO solicitudes (id, tenant_id, usuario_id, cobro_id, nro_recibo, tipo, descripcion, estado)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [
        randomUUID(),
        tenantA,
        residenteUserId,
        cobroVencidaId,
        'REC-002',
        'DESCUENTO',
        'Solicito descuento por pronto pago',
        'PENDIENTE',
      ],
    );

    // ════════════════════════════════════════════════════════
    // 5. Tenant B (para el test de aislamiento)
    // ════════════════════════════════════════════════════════
    await dataSource.query(
      `INSERT INTO proyectos (id, nombre, tenant_id) VALUES ($1, $2, $3)`,
      [randomUUID(), 'Proyecto Tenant B', tenantB],
    );
    const adminBId = randomUUID();
    await dataSource.query(
      `INSERT INTO usuarios (id, email, password_hash, nombre, rol, residente_id, tenant_id, activo)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [
        adminBId,
        'admin-b@test.com',
        bcryptHashSync('adminB123', 10),
        'Admin Tenant B',
        'ADMIN',
        null,
        tenantB,
        true,
      ],
    );

    // ════════════════════════════════════════════════════════
    // 6. Login — tokens
    // ════════════════════════════════════════════════════════
    const adminLoginRes = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ username: 'admin-dash@test.com', password: 'admin123' })
      .expect(201);
    adminToken = adminLoginRes.body.accessToken;

    const cobradorLoginRes = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ username: 'cobrador-dash@test.com', password: 'cobrador123' })
      .expect(201);
    cobradorToken = cobradorLoginRes.body.accessToken;

    const propLoginRes = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ username: 'prop-dash@test.com', password: 'prop123' })
      .expect(201);
    residenteToken = propLoginRes.body.accessToken;
  });

  afterAll(async () => {
    if (!dataSource || !dataSource.isInitialized) return;
    await limpiarTenant(dataSource, tenantA);
    await limpiarTenant(dataSource, tenantB);
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

      expect(res.body).toHaveProperty('mes', currentMonth);
      expect(res.body).toHaveProperty('anio', currentYear);
      expect(res.body).toHaveProperty('resumen');
      expect(res.body).toHaveProperty('evolucion');
      expect(res.body).toHaveProperty('modalidades');
      expect(res.body).toHaveProperty('estadoCobros');
      expect(res.body).toHaveProperty('actividad');
      expect(res.body).toHaveProperty('solicitudesPendientes');
      expect(res.body).toHaveProperty('nuevosResidentesSemana');
      expect(res.body).toHaveProperty('residentesMora');
      expect(res.body).toHaveProperty('acumuladoAnual');
      expect(res.body).toHaveProperty('metaAnual');
      expect(res.body).toHaveProperty('historialMeses');
      expect(res.body).toHaveProperty('cobrosPorSemana');
      expect(res.body).toHaveProperty('cobrosResumen');
      expect(res.body).toHaveProperty('totalResidentes');
    });

    it('1.2 Resumen debe reflejar los datos seedeados', async () => {
      const res = await request(app.getHttpServer())
        .get(`/dashboard/administrador?mes=${currentMonth}&anio=${currentYear}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      const { resumen } = res.body;

      // recaudoTotal: 4000000 (pago del residente Al Día)
      expect(resumen.recaudoTotal).toBe(4000000);

      // metaMensual: cobros del mes = 4000000 (PAGADA) + 4000000 (PENDIENTE) = 8000000
      expect(resumen.metaMensual).toBe(8000000);

      // porcentajeMeta = round((4000000 / 8000000) * 10000) / 100 = 50
      expect(resumen.porcentajeMeta).toBe(50);

      // pagaron: 1 (solo residenteAlDia pagó)
      expect(resumen.pagaron).toBe(1);

      // pendientes: al menos el cobro PENDIENTE de este mes
      expect(resumen.pendientes).toBeGreaterThanOrEqual(1);

      // moraTotal: saldo del cobro VENCIDA (mes anterior) = 4000000
      expect(resumen.moraTotal).toBe(4000000);
    });

    it('1.3 Evolución diaria debe contener el día con el pago', async () => {
      const res = await request(app.getHttpServer())
        .get(`/dashboard/administrador?mes=${currentMonth}&anio=${currentYear}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      const { evolucion } = res.body;
      expect(Array.isArray(evolucion)).toBe(true);

      // El pago se registró el día 1 del mes (thisMonthStart)
      const todayEntry = evolucion.find(
        (e: { dia: string | number }) => Number(e.dia) === 1,
      );
      expect(todayEntry).toBeDefined();
      expect(todayEntry.valor).toBe(4000000);
    });

    it('1.4 Modalidades debe desglosar por modalidad de tarifa', async () => {
      const res = await request(app.getHttpServer())
        .get(`/dashboard/administrador?mes=${currentMonth}&anio=${currentYear}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      const { modalidades } = res.body;
      expect(Array.isArray(modalidades)).toBe(true);

      const mensual = modalidades.find(
        (m: { modalidad: string }) => m.modalidad === 'MENSUAL',
      );
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

      // Seed: 2 solicitudes PENDIENTES
      expect(res.body.solicitudesPendientes).toBe(2);
    });

    it('1.8 Nuevos residentes de la semana', async () => {
      const res = await request(app.getHttpServer())
        .get(`/dashboard/administrador?mes=${currentMonth}&anio=${currentYear}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      // residenteAlDia fue creado hace 2 días (within last week)
      expect(res.body.nuevosResidentesSemana).toBeGreaterThanOrEqual(1);
    });

    it('1.9 Residentes en mora', async () => {
      const res = await request(app.getHttpServer())
        .get(`/dashboard/administrador?mes=${currentMonth}&anio=${currentYear}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      // Solo residenteMora tiene cobro VENCIDA
      expect(res.body.residentesMora).toBe(1);
    });

    it('1.10 Historial mensual contiene 12 meses', async () => {
      const res = await request(app.getHttpServer())
        .get(`/dashboard/administrador?mes=${currentMonth}&anio=${currentYear}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      const { historialMeses } = res.body;
      expect(Array.isArray(historialMeses)).toBe(true);
      expect(historialMeses.length).toBe(12);

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

      // Meta anual: suma de montos de cobros del año (3 × 4000000)
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

    it('2.3 Con rol RESIDENTE → 403 en admin dashboard', async () => {
      const res = await request(app.getHttpServer())
        .get(`/dashboard/administrador?mes=${currentMonth}&anio=${currentYear}`)
        .set('Authorization', `Bearer ${residenteToken}`)
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
      const loginB = await request(app.getHttpServer())
        .post('/auth/login')
        .send({ username: 'admin-b@test.com', password: 'adminB123' })
        .expect(201);
      const tokenB = loginB.body.accessToken;

      const res = await request(app.getHttpServer())
        .get(`/dashboard/administrador?mes=${currentMonth}&anio=${currentYear}`)
        .set('Authorization', `Bearer ${tokenB}`)
        .expect(200);

      // Tenant B no tiene datos — todo en cero
      expect(res.body.resumen.recaudoTotal).toBe(0);
      expect(res.body.resumen.metaMensual).toBe(0);
      expect(res.body.resumen.pagaron).toBe(0);
      expect(res.body.solicitudesPendientes).toBe(0);
      expect(res.body.nuevosResidentesSemana).toBe(0);
      expect(res.body.residentesMora).toBe(0);
      expect(res.body.totalResidentes).toBe(0);
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

      // Debe incluir residenteMora (tiene cobro pendiente en etapaA)
      const moraVivienda = viviendas.find(
        (v: { residenteId: string }) => v.residenteId === residenteMora,
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
  // 5. GET /dashboard/residente — Residente Dashboard
  // ═══════════════════════════════════════════════════════════════

  describe('GET /dashboard/residente', () => {
    it('5.1 Debe retornar dashboard del residente autenticado', async () => {
      const res = await request(app.getHttpServer())
        .get('/dashboard/residente')
        .set('Authorization', `Bearer ${residenteToken}`)
        .expect(200);

      expect(res.body).toHaveProperty('saldo');
      expect(res.body).toHaveProperty('status');
      expect(res.body).toHaveProperty('proximoCobro');
      expect(res.body).toHaveProperty('ultimoPago');
      expect(res.body).toHaveProperty('movimientos');
      expect(res.body).toHaveProperty('residenteInfo');
    });

    it('5.2 Residente al día debe tener saldo 0 y status AL_DIA', async () => {
      const res = await request(app.getHttpServer())
        .get('/dashboard/residente')
        .set('Authorization', `Bearer ${residenteToken}`)
        .expect(200);

      // residenteAlDia tiene 1 cobro PAGADA este mes y NO tiene vencidas
      expect(res.body.saldo).toBe(0);
      expect(res.body.status).toBe('AL_DIA');
    });

    it('5.3 ADMIN no puede acceder al dashboard del residente', async () => {
      const res = await request(app.getHttpServer())
        .get('/dashboard/residente')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(403);

      expect(res.body).toHaveProperty('message');
    });

    it('5.4 Debe retornar residenteInfo con nombre, casaDireccion y etapaNombre', async () => {
      const res = await request(app.getHttpServer())
        .get('/dashboard/residente')
        .set('Authorization', `Bearer ${residenteToken}`)
        .expect(200);

      expect(res.body).toHaveProperty('residenteInfo');
      expect(res.body.residenteInfo).toHaveProperty('nombre');
      expect(res.body.residenteInfo).toHaveProperty('casaDireccion');
      expect(res.body.residenteInfo).toHaveProperty('etapaNombre');

      // residenteAlDia tiene tenencia → casaA → manzanaA → etapaA
      expect(res.body.residenteInfo.nombre).toBe('Juan Al Día');
      expect(res.body.residenteInfo.casaDireccion).toBeTruthy();
      expect(res.body.residenteInfo.etapaNombre).toBe('Etapa Alfa');
    });
  });
});
