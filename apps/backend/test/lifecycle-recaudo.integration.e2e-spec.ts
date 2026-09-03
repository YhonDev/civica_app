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

jest.setTimeout(30000);

/**
 * Ciclo Completo del Motor de Recaudo — E2E Integration
 *
 * Validates the full recaudo lifecycle end-to-end against REAL API endpoints:
 *
 *   1. Infraestructura Física:  Proyecto → Etapa → Manzana → Casa
 *   2. Residente & Cobros:      Registrar residente con casaId → auto-genera
 *                                PlanDeCobro + PeriodoCobro + Cobros
 *   3. Pago Completo (FIFO):    Cobrador registra pago completo
 *   4. Pago Parcial (FIFO):     Segundo residente con pago parcial
 *   5. Reporte de Recaudo:      GET /reportes/recaudo con desglose por etapa
 */
describe('Ciclo Completo del Motor de Recaudo (E2E Integration)', () => {
  let app: INestApplication;
  let dataSource: DataSource;

  let tenantId: string;
  let adminToken: string;
  let cobradorToken: string;

  // Paso 1: IDs de infraestructura
  let proyectoId: string;
  let etapaId: string;
  let manzanaId: string;
  let casaId: string;
  let casaId2: string;

  // Paso 2: IDs de residentes
  let residenteId: string;
  let residenteId2: string;

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
    tenantId = randomUUID();

    // ── Seed Admin & Cobrador users ──────────────────────────
    const adminId = randomUUID();
    const cobradorId = randomUUID();
    const adminHash = bcryptHashSync('admin123', 10);
    const cobradorHash = bcryptHashSync('cobrador123', 10);

    await dataSource.query(
      `INSERT INTO usuarios (id, email, password_hash, nombre, rol, residente_id, tenant_id, activo)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8), ($9, $10, $11, $12, $13, $14, $15, $16)`,
      [
        adminId,
        `admin-lifecycle-${tenantId.substring(0, 8)}@test.com`,
        adminHash,
        'Admin E2E',
        'ADMIN',
        null,
        tenantId,
        true,
        cobradorId,
        `cobrador-lifecycle-${tenantId.substring(0, 8)}@test.com`,
        cobradorHash,
        'Cobrador E2E',
        'COBRADOR',
        null,
        tenantId,
        true,
      ],
    );

    // ── Login Admin ─────────────────────────────────────────
    const loginAdmin = await request(app.getHttpServer())
      .post('/auth/login')
      .send({
        username: `admin-lifecycle-${tenantId.substring(0, 8)}@test.com`,
        password: 'admin123',
      })
      .expect(201);
    adminToken = loginAdmin.body.accessToken;

    // ── Login Cobrador ──────────────────────────────────────
    const loginCobrador = await request(app.getHttpServer())
      .post('/auth/login')
      .send({
        username: `cobrador-lifecycle-${tenantId.substring(0, 8)}@test.com`,
        password: 'cobrador123',
      })
      .expect(201);
    cobradorToken = loginCobrador.body.accessToken;
  });

  afterAll(async () => {
    if (!dataSource || !dataSource.isInitialized) return;

    // Cleanup in reverse dependency order
    await dataSource.query('DELETE FROM tickets WHERE tenant_id = $1', [
      tenantId,
    ]);
    await dataSource.query('DELETE FROM pagos WHERE tenant_id = $1', [
      tenantId,
    ]);
    await dataSource.query('DELETE FROM cobros WHERE tenant_id = $1', [
      tenantId,
    ]);
    await dataSource.query('DELETE FROM periodos_cobro WHERE tenant_id = $1', [
      tenantId,
    ]);
    await dataSource.query('DELETE FROM planes_de_cobro WHERE tenant_id = $1', [
      tenantId,
    ]);
    await dataSource.query(
      'DELETE FROM tenencias WHERE residente_id IN (SELECT id FROM residentes WHERE tenant_id = $1)',
      [tenantId],
    );
    await dataSource.query('DELETE FROM usuarios WHERE tenant_id = $1', [
      tenantId,
    ]);
    await dataSource.query('DELETE FROM residentes WHERE tenant_id = $1', [
      tenantId,
    ]);
    if (casaId2)
      await dataSource.query('DELETE FROM casas WHERE id = $1', [casaId2]);
    if (casaId)
      await dataSource.query('DELETE FROM casas WHERE id = $1', [casaId]);
    if (manzanaId)
      await dataSource.query('DELETE FROM manzanas WHERE id = $1', [manzanaId]);
    if (etapaId)
      await dataSource.query('DELETE FROM etapas WHERE id = $1', [etapaId]);
    if (proyectoId)
      await dataSource.query('DELETE FROM proyectos WHERE id = $1', [
        proyectoId,
      ]);
    await dataSource.query('DELETE FROM actividad WHERE tenant_id = $1', [
      tenantId,
    ]);

    await app.close();
  });

  // ═══════════════════════════════════════════════════════════════
  // Paso 1: Estructura Territorial (Proyecto → Etapa → Manzana → Casa)
  // ═══════════════════════════════════════════════════════════════

  describe('Paso 1: Estructura Territorial (Proyecto → Etapa → Manzana → Casa)', () => {
    it('debe crear un Proyecto', async () => {
      const res = await request(app.getHttpServer())
        .post('/proyectos')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ nombre: 'Urbanización E2E Recaudo' })
        .expect(201);

      expect(res.body).toHaveProperty('id');
      expect(res.body.nombre).toBe('Urbanización E2E Recaudo');
      proyectoId = res.body.id;
    });

    it('debe crear una Etapa en el Proyecto', async () => {
      const res = await request(app.getHttpServer())
        .post(`/proyectos/${proyectoId}/etapas`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ nombre: 'Etapa 1 Sol' })
        .expect(201);

      expect(res.body).toHaveProperty('id');
      expect(res.body.nombre).toBe('Etapa 1 Sol');
      etapaId = res.body.id;
    });

    it('debe crear una Manzana en la Etapa', async () => {
      const res = await request(app.getHttpServer())
        .post(`/proyectos/etapas/${etapaId}/manzanas`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ nombre: 'Manzana Alpha' })
        .expect(201);

      expect(res.body).toHaveProperty('id');
      expect(res.body.nombre).toBe('Manzana Alpha');
      manzanaId = res.body.id;
    });

    it('debe crear dos Casas en la Manzana', async () => {
      const res1 = await request(app.getHttpServer())
        .post(`/proyectos/manzanas/${manzanaId}/casas`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ direccionInterna: 'Casa 101' })
        .expect(201);

      expect(res1.body).toHaveProperty('id');
      expect(res1.body.direccionInterna).toBe('Casa 101');
      casaId = res1.body.id;

      const res2 = await request(app.getHttpServer())
        .post(`/proyectos/manzanas/${manzanaId}/casas`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ direccionInterna: 'Casa 102' })
        .expect(201);

      expect(res2.body).toHaveProperty('id');
      casaId2 = res2.body.id;
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Paso 2: Tarifa + Residentes (auto-genera PlanDeCobro + Cobros)
  // ═══════════════════════════════════════════════════════════════

  describe('Paso 2: Tarifa & Residentes con auto-generación de Cobros', () => {
    it('debe crear una tarifa vigente para el proyecto', async () => {
      // La generación de cobros necesita una tarifa vigente para calcular montos
      const hoy = new Date();
      const fechaVigencia = hoy.toISOString().split('T')[0];

      const res = await request(app.getHttpServer())
        .post('/tarifas')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          proyectoId,
          modalidad: 'MENSUAL',
          monto: 100000, // 100.000 COP en PESOS (el use case convierte a centavos ×100)
          fechaVigencia,
        })
        .expect(201);

      expect(res.body).toHaveProperty('id');
      // ConfigurarTarifaUseCase guarda en centavos: 100.000 × 100 = 10.000.000
      expect(res.body.monto).toBe(10000000);
    });

    it('debe registrar Residente 1 con casa, generando PlanDeCobro + Cobros automáticamente', async () => {
      const hoy = new Date();
      const fechaInicio = hoy.toISOString().split('T')[0];

      const res = await request(app.getHttpServer())
        .post('/residentes')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          nombre: 'Carlos Residente E2E',
          telefono: '3009998877',
          email: 'carlos.e2e@test.com',
          casaId,
          modalidadPago: 'MENSUAL',
          fechaInicio,
        })
        .expect(201);

      // RegistrarResidenteUseCase returns { residente, credenciales }
      expect(res.body).toHaveProperty('residente');
      expect(res.body.residente.nombre).toBe('Carlos Residente E2E');
      residenteId = res.body.residente.id;

      // Verify cobros were auto-generated in DB
      const cobros = await dataSource.query(
        'SELECT id, estado, monto FROM cobros WHERE residente_id = $1 AND tenant_id = $2',
        [residenteId, tenantId],
      );
      expect(cobros.length).toBeGreaterThanOrEqual(1);
      expect(cobros[0].estado).toBe('PENDIENTE');
      expect(cobros[0].monto).toBe(10000000); // MENSUAL = 1 cobro of full amount
    });

    it('debe registrar Residente 2 con segunda casa, generando Cobros', async () => {
      const hoy = new Date();
      const fechaInicio = hoy.toISOString().split('T')[0];

      const res = await request(app.getHttpServer())
        .post('/residentes')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          nombre: 'Maria Residente E2E',
          telefono: '3001112233',
          email: 'maria.e2e@test.com',
          casaId: casaId2,
          modalidadPago: 'MENSUAL',
          fechaInicio,
        })
        .expect(201);

      expect(res.body).toHaveProperty('residente');
      residenteId2 = res.body.residente.id;

      // Verify cobros auto-generated
      const cobros = await dataSource.query(
        'SELECT id, estado FROM cobros WHERE residente_id = $1',
        [residenteId2],
      );
      expect(cobros.length).toBeGreaterThanOrEqual(1);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Paso 3: Pago Completo (FIFO) — Cobrador en Terreno
  // ═══════════════════════════════════════════════════════════════

  describe('Paso 3: Pago Completo por Cobrador (FIFO Distribution)', () => {
    it('debe registrar un pago completo que cierra el cobro del Residente 1', async () => {
      const res = await request(app.getHttpServer())
        .post('/pagos')
        .set('Authorization', `Bearer ${cobradorToken}`)
        .send({
          clientPaymentId: `lifecycle-full-${randomUUID()}`,
          monto: 10000000, // 100.000 COP — matches the cobro amount
          fechaPago: new Date().toISOString().split('T')[0],
          residenteId,
        })
        .expect(201);

      // RegistrarPagoUseCase returns { pago, cobrosAfectados, event, ticket }
      expect(res.body).toHaveProperty('pago');
      expect(res.body).toHaveProperty('cobrosAfectados');
      expect(res.body).toHaveProperty('ticket');
      expect(res.body.pago.monto).toBe(10000000);
      expect(res.body.pago.residenteId).toBe(residenteId);

      // Cobro should be PAGADA
      const afectados = res.body.cobrosAfectados;
      expect(afectados.length).toBeGreaterThanOrEqual(1);
      expect(afectados[0].estado).toBe('PAGADA');
      expect(afectados[0].montoPagado).toBe(10000000);

      // Verify in DB
      const [cobroDb] = await dataSource.query(
        'SELECT estado, monto_pagado FROM cobros WHERE id = $1',
        [afectados[0].id],
      );
      expect(cobroDb.estado).toBe('PAGADA');
      expect(cobroDb.monto_pagado).toBe(10000000);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Paso 4: Pago Parcial (FIFO) — Residente 2
  // ═══════════════════════════════════════════════════════════════

  describe('Paso 4: Pago Parcial (Abono) del Residente 2', () => {
    it('debe registrar un abono parcial que deja el cobro en estado PARCIAL', async () => {
      const res = await request(app.getHttpServer())
        .post('/pagos')
        .set('Authorization', `Bearer ${cobradorToken}`)
        .send({
          clientPaymentId: `lifecycle-partial-${randomUUID()}`,
          monto: 5000000, // 50.000 COP — half of the cobro
          fechaPago: new Date().toISOString().split('T')[0],
          residenteId: residenteId2,
        })
        .expect(201);

      expect(res.body).toHaveProperty('pago');
      expect(res.body.pago.monto).toBe(5000000);

      const afectados = res.body.cobrosAfectados;
      expect(afectados.length).toBe(1);
      expect(afectados[0].estado).toBe('PARCIAL');
      expect(afectados[0].montoPagado).toBe(5000000);

      // Verify saldo remaining in DB
      const [cobroDb] = await dataSource.query(
        'SELECT estado, monto, monto_pagado FROM cobros WHERE id = $1',
        [afectados[0].id],
      );
      expect(cobroDb.estado).toBe('PARCIAL');
      expect(cobroDb.monto - cobroDb.monto_pagado).toBe(5000000); // saldo pendiente
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Paso 5: Reporte de Recaudo con Desglose por Etapa
  // ═══════════════════════════════════════════════════════════════

  describe('Paso 5: Reporte de Recaudo con Desglose por Etapa', () => {
    it('debe retornar el reporte reflejando pagos completos, parciales y desglose por etapa', async () => {
      const hoy = new Date();
      const mes = hoy.getMonth() + 1;
      const anio = hoy.getFullYear();

      const res = await request(app.getHttpServer())
        .get(
          `/reportes/recaudo?proyectoId=${proyectoId}&mes=${mes}&anio=${anio}`,
        )
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(res.body.mes).toBe(mes);
      expect(res.body.anio).toBe(anio);

      // GenerarReporteUseCase divides centavos by 100 for the response:
      //   Residente 1: 10.000.000 centavos pagado → totalRecaudado += 100.000
      //   Residente 2: 5.000.000 centavos pagado, 5.000.000 pendiente
      //                → totalRecaudado += 50.000, totalPendiente += 50.000
      //
      // Total recaudado: 150.000 COP
      // Total pendiente: 50.000 COP
      // Meta: 200.000 COP
      // Porcentaje: 75%
      expect(res.body.totalRecaudado).toBe(150000);
      expect(res.body.totalPendiente).toBe(50000);
      expect(res.body.meta).toBe(200000);
      expect(res.body.porcentaje).toBe(75);

      // Validate desglosePorEstado
      expect(res.body.desglosePorEstado).toBeDefined();
      expect(res.body.desglosePorEstado.pagadasCount).toBe(1); // Residente 1 cobro
      expect(res.body.desglosePorEstado.pendientesCount).toBe(1); // Residente 2 cobro (PARCIAL)

      // Validate desglosePorEtapa
      expect(res.body.desglosePorEtapa).toBeInstanceOf(Array);
      expect(res.body.desglosePorEtapa.length).toBeGreaterThanOrEqual(1);

      const etapaSol = res.body.desglosePorEtapa.find(
        (e: any) => e.etapaId === etapaId,
      );
      expect(etapaSol).toBeDefined();
      expect(etapaSol.etapaNombre).toBe('Etapa 1 Sol');
      expect(etapaSol.totalRecaudado).toBe(150000);
      expect(etapaSol.totalPendiente).toBe(50000);
    });
  });
});
