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
 * Integration tests for Beta1 cuotas role gating.
 *
 * Covers:
 * - GET /cobros: 200 for ADMIN and COBRADOR, 403 for RESIDENTE
 * - GET /cobros/residente/:id: 200 for RESIDENTE (own data), 401 for cross-residente
 */
describe('Beta1 Cobros Role Gating', () => {
  let app: INestApplication;
  let dataSource: DataSource;

  // Shared IDs
  let tenantId: string;
  let residenteAId: string;
  let residenteBId: string;
  let adminUserId: string;
  let cobradorUserId: string;
  let residenteAUserId: string;
  let residenteBUserId: string;

  // Auth tokens
  let adminToken: string;
  let cobradorToken: string;
  let residenteAToken: string;
  let residenteBToken: string;

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

    // Datos huérfanos de corridas previas (su afterAll pudo fallar)
    await purgarEmails(dataSource, [
      'admin-role@test.com',
      'cobrador-role@test.com',
      'propA-role@test.com',
      'propB-role@test.com',
    ]);

    // Seed community
    const proyectoId = randomUUID();
    const etapaId = randomUUID();
    const manzanaId = randomUUID();
    const casaAId = randomUUID();
    const casaBId = randomUUID();
    residenteAId = randomUUID();
    residenteBId = randomUUID();

    await dataSource.query(
      `INSERT INTO proyectos (id, nombre, tenant_id) VALUES ($1, $2, $3)`,
      [proyectoId, 'Proyecto Role Test', tenantId],
    );
    await dataSource.query(
      `INSERT INTO etapas (id, nombre, proyecto_id) VALUES ($1, $2, $3)`,
      [etapaId, 'Etapa Role Test', proyectoId],
    );
    await dataSource.query(
      `INSERT INTO manzanas (id, nombre, etapa_id) VALUES ($1, $2, $3)`,
      [manzanaId, 'Mz A', etapaId],
    );
    await dataSource.query(
      `INSERT INTO casas (id, direccion_interna, manzana_id) VALUES ($1, $2, $3)`,
      [casaAId, 'Casa 101', manzanaId],
    );
    await dataSource.query(
      `INSERT INTO casas (id, direccion_interna, manzana_id) VALUES ($1, $2, $3)`,
      [casaBId, 'Casa 202', manzanaId],
    );

    // Residentes + tenencias
    await dataSource.query(
      `INSERT INTO residentes (id, nombre, telefono, tenant_id) VALUES ($1, $2, $3, $4)`,
      [residenteAId, 'Residente A', '555-0001', tenantId],
    );
    await dataSource.query(
      `INSERT INTO residentes (id, nombre, telefono, tenant_id) VALUES ($1, $2, $3, $4)`,
      [residenteBId, 'Residente B', '555-0002', tenantId],
    );
    await dataSource.query(
      `INSERT INTO tenencias (id, residente_id, casa_id, fecha_inicio) VALUES ($1, $2, $3, $4)`,
      [randomUUID(), residenteAId, casaAId, '2026-01-01'],
    );
    await dataSource.query(
      `INSERT INTO tenencias (id, residente_id, casa_id, fecha_inicio) VALUES ($1, $2, $3, $4)`,
      [randomUUID(), residenteBId, casaBId, '2026-01-01'],
    );

    // Users
    adminUserId = randomUUID();
    cobradorUserId = randomUUID();
    residenteAUserId = randomUUID();
    residenteBUserId = randomUUID();

    const adminHash = bcryptHashSync('admin123', 10);
    const cobradorHash = bcryptHashSync('cobrador123', 10);
    const propAHash = bcryptHashSync('propA123', 10);
    const propBHash = bcryptHashSync('propB123', 10);

    await dataSource.query(
      `INSERT INTO usuarios (id, email, password_hash, nombre, rol, residente_id, tenant_id, activo)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [
        adminUserId,
        'admin-role@test.com',
        adminHash,
        'Admin Role',
        'ADMIN',
        null,
        tenantId,
        true,
      ],
    );
    await dataSource.query(
      `INSERT INTO usuarios (id, email, password_hash, nombre, rol, residente_id, tenant_id, activo)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [
        cobradorUserId,
        'cobrador-role@test.com',
        cobradorHash,
        'Cobrador Role',
        'COBRADOR',
        null,
        tenantId,
        true,
      ],
    );
    await dataSource.query(
      `INSERT INTO usuarios (id, email, password_hash, nombre, rol, residente_id, tenant_id, activo)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [
        residenteAUserId,
        'propA-role@test.com',
        propAHash,
        'Residente A Role',
        'RESIDENTE',
        residenteAId,
        tenantId,
        true,
      ],
    );
    await dataSource.query(
      `INSERT INTO usuarios (id, email, password_hash, nombre, rol, residente_id, tenant_id, activo)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [
        residenteBUserId,
        'propB-role@test.com',
        propBHash,
        'Residente B Role',
        'RESIDENTE',
        residenteBId,
        tenantId,
        true,
      ],
    );

    // Asignar etapa al cobrador
    await dataSource.query(
      `INSERT INTO asignaciones_etapa (id, usuario_id, etapa_id, tenant_id) VALUES ($1, $2, $3, $4)`,
      [randomUUID(), cobradorUserId, etapaId, tenantId],
    );

    // Tarifa + planes de cobro (los cobros se crean vía dominio para cada test)
    await dataSource.query(
      `INSERT INTO tarifas (id, tenant_id, proyecto_id, modalidad, monto, fecha_vigencia) VALUES ($1, $2, $3, $4, $5, $6)`,
      [randomUUID(), tenantId, proyectoId, 'MENSUAL', 4000000, '2026-01-01'],
    );
    await dataSource.query(
      `INSERT INTO planes_de_cobro (id, residente_id, tenant_id, proyecto_id, modalidad, valor_mensual, fecha_activacion)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [
        randomUUID(),
        residenteAId,
        tenantId,
        proyectoId,
        'MENSUAL',
        4000000,
        '2026-01-01',
      ],
    );
    await dataSource.query(
      `INSERT INTO planes_de_cobro (id, residente_id, tenant_id, proyecto_id, modalidad, valor_mensual, fecha_activacion)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [
        randomUUID(),
        residenteBId,
        tenantId,
        proyectoId,
        'MENSUAL',
        4000000,
        '2026-01-01',
      ],
    );

    // Cobro pendiente para cada residente (mismo monto)
    const now = new Date();
    const thisMonthStart = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-01`;
    const nextMonthDate = new Date(now.getFullYear(), now.getMonth() + 1, 15);
    const nextMonthStr = `${nextMonthDate.getFullYear()}-${String(nextMonthDate.getMonth() + 1).padStart(2, '0')}-15`;

    for (const [residenteId, concepto] of [
      [residenteAId, 'Cobro Test A'],
      [residenteBId, 'Cobro Test B'],
    ] as const) {
      await dataSource.query(
        `INSERT INTO cobros (id, residente_id, tenant_id, concepto, monto, monto_pagado, periodo_inicio, periodo_fin, fecha_vencimiento, estado)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
        [
          randomUUID(),
          residenteId,
          tenantId,
          concepto,
          4000000,
          0,
          thisMonthStart,
          nextMonthStr,
          nextMonthStr,
          'PENDIENTE',
        ],
      );
    }

    // Login all users
    const adminRes = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ username: 'admin-role@test.com', password: 'admin123' })
      .expect(201);
    adminToken = adminRes.body.accessToken;

    const cobradorRes = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ username: 'cobrador-role@test.com', password: 'cobrador123' })
      .expect(201);
    cobradorToken = cobradorRes.body.accessToken;

    const propARes = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ username: 'propA-role@test.com', password: 'propA123' })
      .expect(201);
    residenteAToken = propARes.body.accessToken;

    const propBRes = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ username: 'propB-role@test.com', password: 'propB123' })
      .expect(201);
    residenteBToken = propBRes.body.accessToken;
  });

  afterAll(async () => {
    if (!dataSource || !dataSource.isInitialized) return;
    await limpiarTenant(dataSource, tenantId);
    await app.close();
  });

  // ═══════════════════════════════════════════════════════════
  // GET /cobros — Role gating
  // ═══════════════════════════════════════════════════════════

  describe('GET /cobros role gating', () => {
    it('ADMIN can access GET /cobros → 200', async () => {
      await request(app.getHttpServer())
        .get('/cobros')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);
    });

    it('COBRADOR can access GET /cobros → 200', async () => {
      await request(app.getHttpServer())
        .get('/cobros')
        .set('Authorization', `Bearer ${cobradorToken}`)
        .expect(200);
    });

    it('RESIDENTE cannot access GET /cobros → 403', async () => {
      const res = await request(app.getHttpServer())
        .get('/cobros')
        .set('Authorization', `Bearer ${residenteAToken}`)
        .expect(403);

      expect(res.body).toHaveProperty('message');
    });
  });

  // ═══════════════════════════════════════════════════════════
  // GET /cobros/residente/:id — Self-access guard
  // ═══════════════════════════════════════════════════════════

  describe('GET /cobros/residente/:id self-access guard', () => {
    it('RESIDENTE can access own cobros → 200', async () => {
      const res = await request(app.getHttpServer())
        .get(`/cobros/residente/${residenteAId}`)
        .set('Authorization', `Bearer ${residenteAToken}`)
        .expect(200);

      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBeGreaterThanOrEqual(1);
    });

    it('RESIDENTE cannot access another residente cobros → 403', async () => {
      const res = await request(app.getHttpServer())
        .get(`/cobros/residente/${residenteBId}`)
        .set('Authorization', `Bearer ${residenteAToken}`)
        .expect(403);

      expect(res.body).toHaveProperty('message');
    });

    it('ADMIN can access any residente cobros → 200', async () => {
      await request(app.getHttpServer())
        .get(`/cobros/residente/${residenteAId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);
    });
  });
});
