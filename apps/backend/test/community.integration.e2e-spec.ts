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
import { AppModule } from '../src/app.module';
import { randomUUID } from 'node:crypto';
import { limpiarTenant, purgarEmails } from './helpers/test-db';

jest.setTimeout(30000);

describe('Community API Integration', () => {
  let app: INestApplication;
  let dataSource: DataSource;
  let tenantId: string;
  let proyectoId: string;
  let etapaId: string;
  let manzanaId: string;
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
    app.useGlobalInterceptors(
      new ClassSerializerInterceptor(app.get(Reflector)),
    );
    await app.init();

    dataSource = app.get(DataSource);
    tenantId = randomUUID();

    // Datos huérfanos de corridas previas (su afterAll pudo fallar)
    await purgarEmails(dataSource, ['admin-community@test.com']);

    // ── Seed admin user for JWT auth ────────────────────
    const adminId = randomUUID();
    const adminHash = bcryptHashSync('admin123', 10);
    await dataSource.query(
      `INSERT INTO usuarios (id, email, password_hash, nombre, rol, residente_id, tenant_id, activo)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [
        adminId,
        'admin-community@test.com',
        adminHash,
        'Admin Community',
        'ADMIN',
        null,
        tenantId,
        true,
      ],
    );

    // ── Login to get admin token ────────────────────────
    const loginRes = await request(app.getHttpServer())
      .post('/auth/login')
      .send({
        username: 'admin-community@test.com',
        password: 'admin123',
      })
      .expect(201);
    adminToken = loginRes.body.accessToken;
  });

  afterAll(async () => {
    if (!dataSource || !dataSource.isInitialized) return;
    await limpiarTenant(dataSource, tenantId);
    await app.close();
  });

  // ── S1.7.1 Create Proyecto ──────────────────────────────────────────

  it('should create a proyecto (POST /proyectos) → 201', async () => {
    const res = await request(app.getHttpServer())
      .post('/proyectos')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ nombre: 'Residencial Test' })
      .expect(201);

    expect(res.body).toHaveProperty('id');
    expect(res.body.nombre).toBe('Residencial Test');
    proyectoId = res.body.id;
  });

  // ── S1.7.2 Create Etapa ─────────────────────────────────────────────

  it('should create an etapa linked to proyecto (POST /proyectos/:id/etapas) → 201', async () => {
    const res = await request(app.getHttpServer())
      .post(`/proyectos/${proyectoId}/etapas`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ nombre: 'Etapa 1' })
      .expect(201);

    expect(res.body).toHaveProperty('id');
    expect(res.body.nombre).toBe('Etapa 1');
    expect(res.body.proyectoId).toBe(proyectoId);
    etapaId = res.body.id;
  });

  // ── S1.7.3 Create Manzana + Casa ────────────────────────────────────

  it('should create a manzana (POST /proyectos/etapas/:id/manzanas) → 201', async () => {
    const res = await request(app.getHttpServer())
      .post(`/proyectos/etapas/${etapaId}/manzanas`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ nombre: 'Manzana 1' })
      .expect(201);

    expect(res.body).toHaveProperty('id');
    expect(res.body.nombre).toBe('Manzana 1');
    manzanaId = res.body.id;
  });

  it('should create a casa linked to manzana (POST /proyectos/manzanas/:id/casas) → 201', async () => {
    const res = await request(app.getHttpServer())
      .post(`/proyectos/manzanas/${manzanaId}/casas`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ direccionInterna: 'Casa 101' })
      .expect(201);

    expect(res.body).toHaveProperty('id');
    expect(res.body.direccionInterna).toBe('Casa 101');
    expect(res.body.manzanaId).toBe(manzanaId);
    casaId = res.body.id;
  });

  // ── S1.7.4 Create Residente (sin casa) ──────────────────────────────

  it('should create a residente sin casa (POST /residentes) → 201', async () => {
    const res = await request(app.getHttpServer())
      .post('/residentes')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        nombre: 'Juan Pérez',
        telefono: '555-0100',
      })
      .expect(201);

    // RegistrarResidenteUseCase retorna { residente, credenciales? }
    const body = res.body.residente ?? res.body;
    expect(body).toHaveProperty('id');
    expect(body.nombre).toBe('Juan Pérez');
    expect(body.telefono).toBe('555-0100');
  });

  // ── S1.7.5 Create Residente con casa (tenencia) ─────────────────────

  it('should create a residente with casa tenencia (POST /residentes) → 201', async () => {
    // La asignación de casa genera plan + cobros, que requieren tarifa vigente
    await dataSource.query(
      `INSERT INTO tarifas (id, tenant_id, proyecto_id, modalidad, monto, fecha_vigencia)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [randomUUID(), tenantId, proyectoId, 'MENSUAL', 10000000, '2026-01-01'],
    );

    const res = await request(app.getHttpServer())
      .post('/residentes')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        nombre: 'María García',
        telefono: '555-0200',
        email: 'maria.community@test.com',
        casaId,
        modalidadPago: 'MENSUAL',
        fechaInicio: '2026-01-01',
      })
      .expect(201);

    const body = res.body.residente ?? res.body;
    expect(body).toHaveProperty('id');
    expect(body.nombre).toBe('María García');
  });

  // ── S1.7.6 List Proyectos ───────────────────────────────────────────

  it('should list proyectos del tenant (GET /proyectos) → 200', async () => {
    const res = await request(app.getHttpServer())
      .get('/proyectos')
      .set('Authorization', `Bearer ${adminToken}`)
      .expect(200);

    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.some((c: { id: string }) => c.id === proyectoId)).toBe(
      true,
    );
  });

  // ── S1.7.7 List / Search Residentes ─────────────────────────────────

  it('should list residentes del tenant (GET /residentes) → 200', async () => {
    const res = await request(app.getHttpServer())
      .get('/residentes')
      .set('Authorization', `Bearer ${adminToken}`)
      .expect(200);

    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBeGreaterThanOrEqual(2);
  });

  it('should filter residentes by casa (GET /residentes?casa=) → 200', async () => {
    const res = await request(app.getHttpServer())
      .get('/residentes')
      .set('Authorization', `Bearer ${adminToken}`)
      .query({ casa: casaId })
      .expect(200);

    expect(Array.isArray(res.body)).toBe(true);
    // Solo María García tiene tenencia sobre esta casa
    expect(
      res.body.every((p: { nombre: string }) => p.nombre === 'María García'),
    ).toBe(true);
    expect(res.body.length).toBe(1);
  });

  // ── S1.7.8 Validation ───────────────────────────────────────────────

  it('should return 400 for empty body on POST /proyectos', async () => {
    const res = await request(app.getHttpServer())
      .post('/proyectos')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({})
      .expect(400);

    expect(res.body).toHaveProperty('message');
    expect(Array.isArray(res.body.message)).toBe(true);
    expect(res.body.message.length).toBeGreaterThanOrEqual(1);
  });

  it('should return 400 for missing required fields on POST /residentes', async () => {
    const res = await request(app.getHttpServer())
      .post('/residentes')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ nombre: 'Incompleto' })
      .expect(400);

    expect(res.body).toHaveProperty('message');
    expect(Array.isArray(res.body.message)).toBe(true);
  });

  it('should return 404 for etapa creation with non-existent proyecto', async () => {
    const fakeId = '00000000-0000-0000-0000-000000000000';
    const res = await request(app.getHttpServer())
      .post(`/proyectos/${fakeId}/etapas`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ nombre: 'Etapa huérfana' })
      .expect(404);

    expect(res.body).toHaveProperty('message');
    expect(res.body.message).toContain('no encontrado');
  });
});
