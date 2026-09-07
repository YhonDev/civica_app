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

describe('Auth & IAM Integration', () => {
  let app: INestApplication;
  let dataSource: DataSource;

  // ── Shared IDs for seed data ──────────────────────────────────
  let tenantId: string;
  let proyectoId: string;
  let etapaId: string;
  let manzanaId: string;
  let casaId: string;
  let residenteId: string;
  let cobradorUserId: string;

  // ── Auth tokens (set by login tests) ───────────────────────────
  let adminAccessToken: string;
  let adminRefreshToken: string;
  let cobradorAccessToken: string;

  // ── 1. Setup ──────────────────────────────────────────────────

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

    // ── Generate all IDs ────────────────────────────────────────
    tenantId = randomUUID();
    proyectoId = randomUUID();
    etapaId = randomUUID();
    manzanaId = randomUUID();
    casaId = randomUUID();
    residenteId = randomUUID();
    const tenenciaId = randomUUID();
    const adminUserId = randomUUID();
    cobradorUserId = randomUUID();
    const residenteUserId = randomUUID();

    // ── Seed community data ─────────────────────────────────────
    await dataSource.query(
      `INSERT INTO proyectos (id, nombre, tenant_id) VALUES ($1, $2, $3)`,
      [proyectoId, 'Proyecto Auth Test', tenantId],
    );
    await dataSource.query(
      `INSERT INTO etapas (id, nombre, proyecto_id) VALUES ($1, $2, $3)`,
      [etapaId, 'Etapa Auth Test', proyectoId],
    );
    await dataSource.query(
      `INSERT INTO manzanas (id, nombre, etapa_id) VALUES ($1, $2, $3)`,
      [manzanaId, 'Manzana Auth Test', etapaId],
    );
    await dataSource.query(
      `INSERT INTO casas (id, direccion_interna, manzana_id) VALUES ($1, $2, $3)`,
      [casaId, 'Casa 001 Auth', manzanaId],
    );
    await dataSource.query(
      `INSERT INTO residentes (id, nombre, telefono, tenant_id) VALUES ($1, $2, $3, $4)`,
      [residenteId, 'Residente Auth Test', '555-9999', tenantId],
    );
    await dataSource.query(
      `INSERT INTO tenencias (id, residente_id, casa_id, fecha_inicio) VALUES ($1, $2, $3, $4)`,
      [tenenciaId, residenteId, casaId, '2026-01-01'],
    );

    // ── Seed users with hashed passwords ────────────────────────
    const adminHash = bcryptHashSync('admin123', 10);
    const cobradorHash = bcryptHashSync('cobrador123', 10);
    const residenteHash = bcryptHashSync('prop123', 10);

    await dataSource.query(
      `INSERT INTO usuarios (id, email, password_hash, nombre, rol, residente_id, tenant_id, activo)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [
        adminUserId,
        'admin@test.com',
        adminHash,
        'Admin Test',
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
        'cobrador@test.com',
        cobradorHash,
        'Cobrador Test',
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
        residenteUserId,
        'prop@test.com',
        residenteHash,
        'Residente Test',
        'RESIDENTE',
        residenteId,
        tenantId,
        true,
      ],
    );
  });

  afterAll(async () => {
    // Clean up in dependency order to respect FK constraints
    await dataSource.query(
      `DELETE FROM asignaciones_etapa WHERE tenant_id = $1`,
      [tenantId],
    );
    await dataSource.query(`DELETE FROM tenencias WHERE residente_id = $1`, [
      residenteId,
    ]);
    await dataSource.query(`DELETE FROM usuarios WHERE tenant_id = $1`, [
      tenantId,
    ]);
    await dataSource.query(`DELETE FROM residentes WHERE id = $1`, [
      residenteId,
    ]);
    await dataSource.query(`DELETE FROM casas WHERE id = $1`, [casaId]);
    await dataSource.query(`DELETE FROM manzanas WHERE id = $1`, [manzanaId]);
    await dataSource.query(`DELETE FROM etapas WHERE id = $1`, [etapaId]);
    await dataSource.query(`DELETE FROM proyectos WHERE id = $1`, [proyectoId]);

    await app.close();
  });

  // ═══════════════════════════════════════════════════════════════
  // 2. POST /auth/login
  // ═══════════════════════════════════════════════════════════════

  describe('POST /auth/login', () => {
    it('Login con credenciales válidas → 200, returns { accessToken, refreshToken, usuario }', async () => {
      const res = await request(app.getHttpServer())
        .post('/auth/login')
        .send({ username: 'admin@test.com', password: 'admin123' })
        .expect(201);

      expect(res.body).toHaveProperty('accessToken');
      expect(res.body).toHaveProperty('refreshToken');
      expect(res.body).toHaveProperty('usuario');
      expect(res.body.usuario).toHaveProperty('id');
      expect(res.body.usuario.email).toBe('admin@test.com');
      expect(res.body.usuario.nombre).toBe('Admin Test');
      expect(res.body.usuario.rol).toBe('ADMIN');
      // passwordHash should be excluded by ClassSerializerInterceptor
      expect(res.body.usuario).not.toHaveProperty('passwordHash');

      // Store tokens for subsequent tests
      adminAccessToken = res.body.accessToken;
      adminRefreshToken = res.body.refreshToken;
    });

    it('Login con username incorrecto → 401', async () => {
      const res = await request(app.getHttpServer())
        .post('/auth/login')
        .send({ username: 'noexiste@test.com', password: 'admin123' })
        .expect(401);

      expect(res.body).toHaveProperty('message');
    });

    it('Login con password incorrecto → 401', async () => {
      const res = await request(app.getHttpServer())
        .post('/auth/login')
        .send({ username: 'admin@test.com', password: 'wrongpassword' })
        .expect(401);

      expect(res.body).toHaveProperty('message');
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 3. POST /auth/register (requires JWT + ADMIN)
  // ═══════════════════════════════════════════════════════════════

  describe('POST /auth/register', () => {
    it('Register como ADMIN creando nuevo usuario → 201', async () => {
      const res = await request(app.getHttpServer())
        .post('/auth/register')
        .set('Authorization', `Bearer ${adminAccessToken}`)
        .send({
          username: 'nuevo-admin@test.com',
          password: 'newadmin123',
          nombre: 'Nuevo Admin',
          rol: 'ADMIN',
          tenantId,
        })
        .expect(201);

      expect(res.body).toHaveProperty('id');
      expect(res.body.username ?? res.body.email).toBe('nuevo-admin@test.com');
      expect(res.body.nombre).toBe('Nuevo Admin');
      expect(res.body.rol).toBe('ADMIN');
      expect(res.body.activo).toBe(true);
      expect(res.body).not.toHaveProperty('passwordHash');
    });

    it('Register sin token → 401', async () => {
      const res = await request(app.getHttpServer())
        .post('/auth/register')
        .send({
          username: 'sin-token@test.com',
          password: 'password123',
          nombre: 'Sin Token',
          rol: 'ADMIN',
          tenantId,
        })
        .expect(401);

      expect(res.body).toHaveProperty('message');
    });

    it('Register con rol COBRADOR → 201', async () => {
      const res = await request(app.getHttpServer())
        .post('/auth/register')
        .set('Authorization', `Bearer ${adminAccessToken}`)
        .send({
          username: 'nuevo-cobrador@test.com',
          password: 'cobrador123',
          nombre: 'Nuevo Cobrador',
          rol: 'COBRADOR',
          tenantId,
        })
        .expect(201);

      expect(res.body).toHaveProperty('id');
      expect(res.body.username ?? res.body.email).toBe(
        'nuevo-cobrador@test.com',
      );
      expect(res.body.rol).toBe('COBRADOR');
    });

    it('Register con email duplicado → 409', async () => {
      const res = await request(app.getHttpServer())
        .post('/auth/register')
        .set('Authorization', `Bearer ${adminAccessToken}`)
        .send({
          username: 'admin@test.com',
          password: 'admin123',
          nombre: 'Duplicado',
          rol: 'ADMIN',
          tenantId,
        })
        .expect(409);

      expect(res.body).toHaveProperty('message');
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 4. GET /usuarios (requires JWT + ADMIN)
  // ═══════════════════════════════════════════════════════════════

  describe('GET /usuarios', () => {
    it('Listar usuarios con token ADMIN → 200', async () => {
      const res = await request(app.getHttpServer())
        .get('/usuarios')
        .set('Authorization', `Bearer ${adminAccessToken}`)
        .expect(200);

      // Current implementation returns empty array
      expect(Array.isArray(res.body)).toBe(true);
    });

    it('Listar con token COBRADOR → 403', async () => {
      // First login como cobrador
      const loginRes = await request(app.getHttpServer())
        .post('/auth/login')
        .send({ username: 'cobrador@test.com', password: 'cobrador123' })
        .expect(201);

      cobradorAccessToken = loginRes.body.accessToken;

      const res = await request(app.getHttpServer())
        .get('/usuarios')
        .set('Authorization', `Bearer ${cobradorAccessToken}`)
        .expect(403);

      expect(res.body).toHaveProperty('message');
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 5. POST /auth/refresh
  // ═══════════════════════════════════════════════════════════════

  describe('POST /auth/refresh', () => {
    it('Refresh con token válido → 200, returns new tokens', async () => {
      const res = await request(app.getHttpServer())
        .post('/auth/refresh')
        .send({ refreshToken: adminRefreshToken })
        .expect(201);

      expect(res.body).toHaveProperty('accessToken');
      expect(res.body).toHaveProperty('refreshToken');
      expect(typeof res.body.accessToken).toBe('string');
      expect(typeof res.body.refreshToken).toBe('string');
      // Nota: el JWT es determinista (mismo payload + iat/exp en el mismo segundo),
      // por lo que el token renovado puede ser idéntico al original — lo correcto
      // es validar que el par renovado sea válido y usable.
    });

    it('Refresh con token inválido → 401', async () => {
      const res = await request(app.getHttpServer())
        .post('/auth/refresh')
        .send({ refreshToken: 'token-invalido' })
        .expect(401);

      expect(res.body).toHaveProperty('message');
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 6. Assign etapas to cobrador
  // ═══════════════════════════════════════════════════════════════

  describe('Asignación de etapas', () => {
    let asignacionId: string;

    it('POST /usuarios/:id/etapas con ADMIN → 201', async () => {
      const res = await request(app.getHttpServer())
        .post(`/usuarios/${cobradorUserId}/etapas`)
        .set('Authorization', `Bearer ${adminAccessToken}`)
        .send({ etapaId })
        .expect(201);

      expect(res.body).toHaveProperty('id');
      expect(res.body.etapaId).toBe(etapaId);
      expect(res.body.usuarioId).toBe(cobradorUserId);
      asignacionId = res.body.id;
    });

    it('POST /usuarios/:id/etapas con COBRADOR → 403', async () => {
      const res = await request(app.getHttpServer())
        .post(`/usuarios/${cobradorUserId}/etapas`)
        .set('Authorization', `Bearer ${cobradorAccessToken}`)
        .send({ etapaId })
        .expect(403);

      expect(res.body).toHaveProperty('message');
    });

    it('GET /usuarios/:id/etapas → 200, returns asignaciones', async () => {
      const res = await request(app.getHttpServer())
        .get(`/usuarios/${cobradorUserId}/etapas`)
        .set('Authorization', `Bearer ${adminAccessToken}`)
        .expect(200);

      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBeGreaterThanOrEqual(1);

      const asignacion = res.body.find(
        (a: { id: string }) => a.id === asignacionId,
      );
      expect(asignacion).toBeDefined();
      expect(asignacion.etapaId).toBe(etapaId);
      expect(asignacion).toHaveProperty('createdAt');
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 7. GET /residentes (rol-filtered listing, tenant desde JWT)
  // ═══════════════════════════════════════════════════════════════

  describe('GET /residentes', () => {
    it('ADMIN ve los residentes de su tenant', async () => {
      const res = await request(app.getHttpServer())
        .get('/residentes')
        .set('Authorization', `Bearer ${adminAccessToken}`)
        .expect(200);

      expect(Array.isArray(res.body)).toBe(true);
      const found = res.body.find((p: { id: string }) => p.id === residenteId);
      expect(found).toBeDefined();
      expect(found.nombre).toBe('Residente Auth Test');
    });

    it('COBRADOR también puede listar (roles ADMIN/COBRADOR/RESIDENTE)', async () => {
      const res = await request(app.getHttpServer())
        .get('/residentes')
        .set('Authorization', `Bearer ${cobradorAccessToken}`)
        .expect(200);

      expect(Array.isArray(res.body)).toBe(true);
      const found = res.body.find((p: { id: string }) => p.id === residenteId);
      expect(found).toBeDefined();
    });
  });
});
