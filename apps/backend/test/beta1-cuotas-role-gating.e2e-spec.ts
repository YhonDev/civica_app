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
 * Integration tests for Beta1 cuotas role gating.
 *
 * Covers:
 * - GET /cuotas: 200 for COBRADOR, 403 for PROPIETARIO
 * - GET /cuotas/propietario/:id: 200 for PROPIETARIO (own data), 403 for cross-propietario
 */
describe('Beta1 Cuotas Role Gating', () => {
  let app: INestApplication;
  let dataSource: DataSource;

  // Shared IDs
  let tenantId: string;
  let proyectoId: string;
  let etapaId: string;
  let manzanaId: string;
  let casaAId: string;
  let casaBId: string;
  let propietarioAId: string;
  let propietarioBId: string;
  let adminUserId: string;
  let cobradorUserId: string;
  let propietarioAUserId: string;
  let propietarioBUserId: string;
  let tarifaId: string;

  // Auth tokens
  let adminToken: string;
  let cobradorToken: string;
  let propietarioAToken: string;
  let propietarioBToken: string;

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

    // Generate IDs
    tenantId = randomUUID();
    proyectoId = randomUUID();
    etapaId = randomUUID();
    manzanaId = randomUUID();
    casaAId = randomUUID();
    casaBId = randomUUID();
    propietarioAId = randomUUID();
    propietarioBId = randomUUID();
    adminUserId = randomUUID();
    cobradorUserId = randomUUID();
    propietarioAUserId = randomUUID();
    propietarioBUserId = randomUUID();
    tarifaId = randomUUID();

    // Seed community
    await dataSource.query(
      `INSERT INTO conjuntos (id, nombre, tenant_id) VALUES ($1, $2, $3)`,
      [proyectoId, 'Conjunto Role Test', tenantId],
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

    // Propietarios
    await dataSource.query(
      `INSERT INTO propietarios (id, nombre, telefono, tenant_id) VALUES ($1, $2, $3, $4)`,
      [propietarioAId, 'Propietario A', '555-0001', tenantId],
    );
    await dataSource.query(
      `INSERT INTO propietarios (id, nombre, telefono, tenant_id) VALUES ($1, $2, $3, $4)`,
      [propietarioBId, 'Propietario B', '555-0002', tenantId],
    );

    // Tenencias
    await dataSource.query(
      `INSERT INTO tenencias (id, residente_id, casa_id, fecha_inicio) VALUES ($1, $2, $3, $4)`,
      [randomUUID(), propietarioAId, casaAId, '2026-01-01'],
    );
    await dataSource.query(
      `INSERT INTO tenencias (id, residente_id, casa_id, fecha_inicio) VALUES ($1, $2, $3, $4)`,
      [randomUUID(), propietarioBId, casaBId, '2026-01-01'],
    );

    // Users
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
        propietarioAUserId,
        'propA-role@test.com',
        propAHash,
        'Prop A Role',
        'PROPIETARIO',
        propietarioAId,
        tenantId,
        true,
      ],
    );
    await dataSource.query(
      `INSERT INTO usuarios (id, email, password_hash, nombre, rol, residente_id, tenant_id, activo)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [
        propietarioBUserId,
        'propB-role@test.com',
        propBHash,
        'Prop B Role',
        'PROPIETARIO',
        propietarioBId,
        tenantId,
        true,
      ],
    );

    // Asignar etapa al cobrador
    await dataSource.query(
      `INSERT INTO asignaciones_etapa (id, usuario_id, etapa_id, tenant_id) VALUES ($1, $2, $3, $4)`,
      [randomUUID(), cobradorUserId, etapaId, tenantId],
    );

    // Tarifa + cuenta cartera
    await dataSource.query(
      `INSERT INTO tarifas (id, tenant_id, proyecto_id, frecuencia, monto, fecha_vigencia) VALUES ($1, $2, $3, $4, $5, $6)`,
      [tarifaId, tenantId, proyectoId, 'MENSUAL', 4000000, '2026-01-01'],
    );
    await dataSource.query(
      `INSERT INTO cuentas_cartera (id, residente_id, tenant_id, proyecto_id, frecuencia, fecha_activacion) VALUES ($1, $2, $3, $4, $5, $6)`,
      [
        randomUUID(),
        propietarioAId,
        tenantId,
        proyectoId,
        'MENSUAL',
        '2026-01-01',
      ],
    );
    await dataSource.query(
      `INSERT INTO cuentas_cartera (id, residente_id, tenant_id, proyecto_id, frecuencia, fecha_activacion) VALUES ($1, $2, $3, $4, $5, $6)`,
      [
        randomUUID(),
        propietarioBId,
        tenantId,
        proyectoId,
        'MENSUAL',
        '2026-01-01',
      ],
    );

    // Cuotas for both propietarios
    const now = new Date();
    const thisMonthStart = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-01`;
    const nextMonthDate = new Date(now.getFullYear(), now.getMonth() + 1, 15);
    const nextMonthStr = `${nextMonthDate.getFullYear()}-${String(nextMonthDate.getMonth() + 1).padStart(2, '0')}-15`;

    await dataSource.query(
      `INSERT INTO cuotas (id, residente_id, tenant_id, tarifa_id, concepto, monto, monto_pagado, periodo_inicio, periodo_fin, fecha_vencimiento, estado)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
      [
        randomUUID(),
        propietarioAId,
        tenantId,
        tarifaId,
        'Cuota Test A',
        4000000,
        0,
        thisMonthStart,
        nextMonthStr,
        nextMonthStr,
        'PENDIENTE',
      ],
    );
    await dataSource.query(
      `INSERT INTO cuotas (id, residente_id, tenant_id, tarifa_id, concepto, monto, monto_pagado, periodo_inicio, periodo_fin, fecha_vencimiento, estado)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
      [
        randomUUID(),
        propietarioBId,
        tenantId,
        tarifaId,
        'Cuota Test B',
        4000000,
        0,
        thisMonthStart,
        nextMonthStr,
        nextMonthStr,
        'PENDIENTE',
      ],
    );

    // Login all users
    const adminRes = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: 'admin-role@test.com', password: 'admin123' })
      .expect(201);
    adminToken = adminRes.body.accessToken;

    const cobradorRes = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: 'cobrador-role@test.com', password: 'cobrador123' })
      .expect(201);
    cobradorToken = cobradorRes.body.accessToken;

    const propARes = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: 'propA-role@test.com', password: 'propA123' })
      .expect(201);
    propietarioAToken = propARes.body.accessToken;

    const propBRes = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: 'propB-role@test.com', password: 'propB123' })
      .expect(201);
    propietarioBToken = propBRes.body.accessToken;
  });

  afterAll(async () => {
    await dataSource.query(`DELETE FROM pagos WHERE tenant_id = $1`, [
      tenantId,
    ]);
    await dataSource.query(`DELETE FROM cuotas WHERE tenant_id = $1`, [
      tenantId,
    ]);
    await dataSource.query(`DELETE FROM cuentas_cartera WHERE tenant_id = $1`, [
      tenantId,
    ]);
    await dataSource.query(`DELETE FROM tarifas WHERE tenant_id = $1`, [
      tenantId,
    ]);
    await dataSource.query(
      `DELETE FROM asignaciones_etapa WHERE tenant_id = $1`,
      [tenantId],
    );
    await dataSource.query(`DELETE FROM usuarios WHERE tenant_id = $1`, [
      tenantId,
    ]);
    await dataSource.query(
      `DELETE FROM tenencias WHERE residente_id IN ($1, $2)`,
      [propietarioAId, propietarioBId],
    );
    await dataSource.query(`DELETE FROM propietarios WHERE tenant_id = $1`, [
      tenantId,
    ]);
    await dataSource.query(`DELETE FROM casas WHERE id IN ($1, $2)`, [
      casaAId,
      casaBId,
    ]);
    await dataSource.query(`DELETE FROM manzanas WHERE id = $1`, [manzanaId]);
    await dataSource.query(`DELETE FROM etapas WHERE id = $1`, [etapaId]);
    await dataSource.query(`DELETE FROM conjuntos WHERE id = $1`, [proyectoId]);
    await app.close();
  });

  // ═══════════════════════════════════════════════════════════
  // GET /cuotas — Role gating
  // ═══════════════════════════════════════════════════════════

  describe('GET /cuotas role gating', () => {
    it('ADMIN can access GET /cuotas → 200', async () => {
      await request(app.getHttpServer())
        .get('/cuotas')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);
    });

    it('COBRADOR can access GET /cuotas → 200', async () => {
      await request(app.getHttpServer())
        .get('/cuotas')
        .set('Authorization', `Bearer ${cobradorToken}`)
        .expect(200);
    });

    it('PROPIETARIO cannot access GET /cuotas → 403', async () => {
      const res = await request(app.getHttpServer())
        .get('/cuotas')
        .set('Authorization', `Bearer ${propietarioAToken}`)
        .expect(403);

      expect(res.body).toHaveProperty('message');
    });
  });

  // ═══════════════════════════════════════════════════════════
  // GET /cuotas/propietario/:id — Self-access guard
  // ═══════════════════════════════════════════════════════════

  describe('GET /cuotas/propietario/:id self-access guard', () => {
    it('PROPIETARIO can access own cuotas → 200', async () => {
      const res = await request(app.getHttpServer())
        .get(`/cuotas/propietario/${propietarioAId}`)
        .set('Authorization', `Bearer ${propietarioAToken}`)
        .expect(200);

      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBeGreaterThanOrEqual(1);
    });

    it('PROPIETARIO cannot access another propietario cuotas → 403', async () => {
      const res = await request(app.getHttpServer())
        .get(`/cuotas/propietario/${propietarioBId}`)
        .set('Authorization', `Bearer ${propietarioAToken}`)
        .expect(403);

      expect(res.body).toHaveProperty('message');
    });

    it('ADMIN can access any propietario cuotas → 200', async () => {
      await request(app.getHttpServer())
        .get(`/cuotas/propietario/${propietarioAId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);
    });
  });
});
