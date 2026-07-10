import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe, ClassSerializerInterceptor } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import request from 'supertest';
import { DataSource } from 'typeorm';
import { hashSync as bcryptHashSync } from 'bcrypt';
import { AppModule } from '../src/app.module';
import { randomUUID } from 'node:crypto';

jest.setTimeout(30000);

describe('Community API Integration', () => {
  let app: INestApplication;
  let dataSource: DataSource;
  let tenantId: string;
  let conjuntoId: string;
  let etapaId: string;
  let casaId: string;

  // ── Auth ─────────────────────────────────────────────
  let adminToken: string;

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
    tenantId = randomUUID();

    // ── Seed admin user for JWT auth ────────────────────
    const adminId = randomUUID();
    const adminHash = bcryptHashSync('admin123', 10);
    await dataSource.query(
      `INSERT INTO usuarios (id, email, password_hash, nombre, rol, propietario_id, tenant_id, activo)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [adminId, 'admin-community@test.com', adminHash, 'Admin Community', 'ADMIN', null, tenantId, true],
    );

    // ── Login to get admin token ────────────────────────
    const loginRes = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: 'admin-community@test.com', password: 'admin123' })
      .expect(201);
    adminToken = loginRes.body.accessToken;
  });

  afterAll(async () => {
    // Clean up in dependency order to respect FK constraints
    await dataSource.query(`DELETE FROM asignaciones_etapa WHERE tenant_id = $1`, [tenantId]);
    await dataSource.query(
      `DELETE FROM tenencias WHERE propietario_id IN (SELECT id FROM propietarios WHERE tenant_id = $1)`,
      [tenantId],
    );
    await dataSource.query(`DELETE FROM propietarios WHERE tenant_id = $1`, [tenantId]);
    await dataSource.query(`DELETE FROM usuarios WHERE tenant_id = $1`, [tenantId]);
    await dataSource.query(`DELETE FROM casas WHERE etapa_id = $1`, [etapaId]);
    await dataSource.query(`DELETE FROM etapas WHERE conjunto_id = $1`, [conjuntoId]);
    await dataSource.query(`DELETE FROM conjuntos WHERE tenant_id = $1`, [tenantId]);

    await app.close();
  });

  // ── S1.7.1 Create Conjunto ──────────────────────────────────────────

  it('should create a conjunto (POST /conjuntos) → 201', async () => {
    const res = await request(app.getHttpServer())
      .post('/conjuntos')
      .send({ nombre: 'Residencial Test', tenantId })
      .expect(201);

    expect(res.body).toHaveProperty('id');
    expect(res.body.nombre).toBe('Residencial Test');
    expect(res.body.tenantId).toBe(tenantId);
    conjuntoId = res.body.id;
  });

  // ── S1.7.2 Create Etapa ─────────────────────────────────────────────

  it('should create an etapa linked to conjunto (POST /conjuntos/:id/etapas) → 201', async () => {
    const res = await request(app.getHttpServer())
      .post(`/conjuntos/${conjuntoId}/etapas`)
      .send({ nombre: 'Etapa 1' })
      .expect(201);

    expect(res.body).toHaveProperty('id');
    expect(res.body.nombre).toBe('Etapa 1');
    expect(res.body.conjuntoId).toBe(conjuntoId);
    etapaId = res.body.id;
  });

  // ── S1.7.3 Create Casa ──────────────────────────────────────────────

  it('should create a casa linked to etapa (POST /conjuntos/:id/casas) → 201', async () => {
    const res = await request(app.getHttpServer())
      .post(`/conjuntos/${etapaId}/casas`)
      .send({ direccionInterna: 'Casa 101' })
      .expect(201);

    expect(res.body).toHaveProperty('id');
    expect(res.body.direccionInterna).toBe('Casa 101');
    expect(res.body.etapaId).toBe(etapaId);
    casaId = res.body.id;
  });

  // ── S1.7.4 Create Propietario (sin casa) ────────────────────────────

  it('should create a propietario (POST /propietarios) → 201', async () => {
    const res = await request(app.getHttpServer())
      .post('/propietarios')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        nombre: 'Juan Pérez',
        telefono: '555-0100',
        tenantId,
      })
      .expect(201);

    expect(res.body).toHaveProperty('id');
    expect(res.body.nombre).toBe('Juan Pérez');
    expect(res.body.telefono).toBe('555-0100');
    expect(res.body.tenantId).toBe(tenantId);
  });

  // ── S1.7.5 Create Propietario con Tenencia ──────────────────────────

  it('should create a propietario with casa tenencia (POST /propietarios) → 201', async () => {
    const res = await request(app.getHttpServer())
      .post('/propietarios')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        nombre: 'María García',
        telefono: '555-0200',
        tenantId,
        casaId,
        fechaInicio: '2026-01-01',
      })
      .expect(201);

    expect(res.body).toHaveProperty('id');
    expect(res.body.nombre).toBe('María García');
    expect(res.body.tenencias).toBeDefined();
    expect(res.body.tenencias).toHaveLength(1);
    expect(res.body.tenencias[0].casaId).toBe(casaId);
    expect(res.body.tenencias[0].fechaFin).toBeNull();
  });

  // ── S1.7.6 List Conjuntos ───────────────────────────────────────────

  it('should list conjuntos by tenant (GET /conjuntos?tenantId=) → 200', async () => {
    const res = await request(app.getHttpServer())
      .get('/conjuntos')
      .query({ tenantId })
      .expect(200);

    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBeGreaterThanOrEqual(1);
    expect(res.body.some((c: { id: string }) => c.id === conjuntoId)).toBe(true);

    // Verify the conjunto includes nested etapas and casas
    const created = res.body.find((c: { id: string }) => c.id === conjuntoId);
    expect(created.etapas).toBeDefined();
    expect(created.etapas.length).toBeGreaterThanOrEqual(1);
    expect(created.etapas[0].casas).toBeDefined();
  });

  // ── S1.7.7 Search Propietarios ──────────────────────────────────────

  it('should search propietarios by tenant (GET /propietarios?tenantId=) → 200', async () => {
    const res = await request(app.getHttpServer())
      .get('/propietarios')
      .set('Authorization', `Bearer ${adminToken}`)
      .query({ tenantId })
      .expect(200);

    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBeGreaterThanOrEqual(2);
  });

  it('should filter propietarios by casa (GET /propietarios?tenantId=&casa=) → 200', async () => {
    const res = await request(app.getHttpServer())
      .get('/propietarios')
      .set('Authorization', `Bearer ${adminToken}`)
      .query({ tenantId, casa: casaId })
      .expect(200);

    expect(Array.isArray(res.body)).toBe(true);
    // Only María García has a tenencia for this casa
    expect(res.body.every((p: { nombre: string }) => p.nombre === 'María García')).toBe(true);
  });

  // ── S1.7.8 Validation ───────────────────────────────────────────────

  it('should return 400 for empty body on POST /conjuntos', async () => {
    const res = await request(app.getHttpServer())
      .post('/conjuntos')
      .send({})
      .expect(400);

    expect(res.body).toHaveProperty('message');
    expect(Array.isArray(res.body.message)).toBe(true);
    expect(res.body.message.length).toBeGreaterThanOrEqual(1);
  });

  it('should return 400 for missing required fields on POST /propietarios', async () => {
    const res = await request(app.getHttpServer())
      .post('/propietarios')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ nombre: 'Incompleto' })
      .expect(400);

    expect(res.body).toHaveProperty('message');
    expect(Array.isArray(res.body.message)).toBe(true);
  });

  it('should return 404 for etapa creation with non-existent conjunto', async () => {
    const fakeId = '00000000-0000-0000-0000-000000000000';
    const res = await request(app.getHttpServer())
      .post(`/conjuntos/${fakeId}/etapas`)
      .send({ nombre: 'Etapa huérfana' })
      .expect(404);

    expect(res.body).toHaveProperty('message');
    expect(res.body.message).toContain('no encontrado');
  });
});
