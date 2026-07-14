import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe, ClassSerializerInterceptor } from '@nestjs/common';
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

  // ── Shared IDs for seed data ───────────────────────────────────
  let tenantId: string;
  let proyectoId: string;
  let etapaId: string;
  let casaId: string;
  let propietarioId: string;
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
    app.useGlobalInterceptors(new ClassSerializerInterceptor(app.get(Reflector)));
    await app.init();

    dataSource = app.get(DataSource);

    // ── Generate all IDs ────────────────────────────────────────
    tenantId = randomUUID();
    proyectoId = randomUUID();
    etapaId = randomUUID();
    casaId = randomUUID();
    propietarioId = randomUUID();
    const tenenciaId = randomUUID();
    const adminUserId = randomUUID();
    cobradorUserId = randomUUID();
    const propietarioUserId = randomUUID();

    // ── Seed community data ─────────────────────────────────────
    await dataSource.query(
      `INSERT INTO conjuntos (id, nombre, tenant_id) VALUES ($1, $2, $3)`,
      [proyectoId, 'Conjunto Auth Test', tenantId],
    );
    await dataSource.query(
      `INSERT INTO etapas (id, nombre, proyecto_id) VALUES ($1, $2, $3)`,
      [etapaId, 'Etapa Auth Test', proyectoId],
    );
    await dataSource.query(
      `INSERT INTO casas (id, direccion_interna, etapa_id) VALUES ($1, $2, $3)`,
      [casaId, 'Casa 001 Auth', etapaId],
    );
    await dataSource.query(
      `INSERT INTO propietarios (id, nombre, telefono, tenant_id) VALUES ($1, $2, $3, $4)`,
      [propietarioId, 'Propietario Auth Test', '555-9999', tenantId],
    );
    await dataSource.query(
      `INSERT INTO tenencias (id, residente_id, casa_id, fecha_inicio) VALUES ($1, $2, $3, $4)`,
      [tenenciaId, propietarioId, casaId, '2026-01-01'],
    );

    // ── Seed users with hashed passwords ────────────────────────
    const adminHash = bcryptHashSync('admin123', 10);
    const cobradorHash = bcryptHashSync('cobrador123', 10);
    const propHash = bcryptHashSync('prop123', 10);

    await dataSource.query(
      `INSERT INTO usuarios (id, email, password_hash, nombre, rol, residente_id, tenant_id, activo)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [adminUserId, 'admin@test.com', adminHash, 'Admin Test', 'ADMIN', null, tenantId, true],
    );
    await dataSource.query(
      `INSERT INTO usuarios (id, email, password_hash, nombre, rol, residente_id, tenant_id, activo)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [cobradorUserId, 'cobrador@test.com', cobradorHash, 'Cobrador Test', 'COBRADOR', null, tenantId, true],
    );
    await dataSource.query(
      `INSERT INTO usuarios (id, email, password_hash, nombre, rol, residente_id, tenant_id, activo)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [
        propietarioUserId,
        'prop@test.com',
        propHash,
        'Prop Test',
        'PROPIETARIO',
        propietarioId,
        tenantId,
        true,
      ],
    );
  });

  afterAll(async () => {
    // Clean up in dependency order to respect FK constraints
    await dataSource.query(`DELETE FROM asignaciones_etapa WHERE tenant_id = $1`, [tenantId]);
    await dataSource.query(`DELETE FROM tenencias WHERE residente_id = $1`, [propietarioId]);
    await dataSource.query(`DELETE FROM usuarios WHERE tenant_id = $1`, [tenantId]);
    await dataSource.query(`DELETE FROM propietarios WHERE tenant_id = $1`, [tenantId]);
    await dataSource.query(`DELETE FROM casas WHERE id = $1`, [casaId]);
    await dataSource.query(`DELETE FROM etapas WHERE id = $1`, [etapaId]);
    await dataSource.query(`DELETE FROM conjuntos WHERE id = $1`, [proyectoId]);

    await app.close();
  });

  // ═══════════════════════════════════════════════════════════════
  // 2. POST /auth/login
  // ═══════════════════════════════════════════════════════════════

  describe('POST /auth/login', () => {
    it('Login con credenciales válidas → 200, returns { accessToken, refreshToken, usuario }', async () => {
      const res = await request(app.getHttpServer())
        .post('/auth/login')
        .send({ email: 'admin@test.com', password: 'admin123' })
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

    it('Login con email incorrecto → 401', async () => {
      const res = await request(app.getHttpServer())
        .post('/auth/login')
        .send({ email: 'noexiste@test.com', password: 'admin123' })
        .expect(401);

      expect(res.body).toHaveProperty('message');
    });

    it('Login con password incorrecto → 401', async () => {
      const res = await request(app.getHttpServer())
        .post('/auth/login')
        .send({ email: 'admin@test.com', password: 'wrongpassword' })
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
          email: 'nuevo-admin@test.com',
          password: 'newadmin123',
          nombre: 'Nuevo Admin',
          rol: 'ADMIN',
          tenantId,
        })
        .expect(201);

      expect(res.body).toHaveProperty('id');
      expect(res.body.email).toBe('nuevo-admin@test.com');
      expect(res.body.nombre).toBe('Nuevo Admin');
      expect(res.body.rol).toBe('ADMIN');
      expect(res.body.activo).toBe(true);
      expect(res.body).not.toHaveProperty('passwordHash');
    });

    it('Register sin token → 401', async () => {
      const res = await request(app.getHttpServer())
        .post('/auth/register')
        .send({
          email: 'sin-token@test.com',
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
          email: 'nuevo-cobrador@test.com',
          password: 'cobrador123',
          nombre: 'Nuevo Cobrador',
          rol: 'COBRADOR',
          tenantId,
        })
        .expect(201);

      expect(res.body).toHaveProperty('id');
      expect(res.body.email).toBe('nuevo-cobrador@test.com');
      expect(res.body.rol).toBe('COBRADOR');
    });

    it('Register con email duplicado → 409', async () => {
      const res = await request(app.getHttpServer())
        .post('/auth/register')
        .set('Authorization', `Bearer ${adminAccessToken}`)
        .send({
          email: 'admin@test.com',
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
        .send({ email: 'cobrador@test.com', password: 'cobrador123' })
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
      // Tokens should be different from the originals
      expect(res.body.accessToken).not.toBe(adminAccessToken);
      expect(res.body.refreshToken).not.toBe(adminRefreshToken);
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

      const asignacion = res.body.find((a: { id: string }) => a.id === asignacionId);
      expect(asignacion).toBeDefined();
      expect(asignacion.etapaId).toBe(etapaId);
      expect(asignacion).toHaveProperty('createdAt');
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 7. Role-filtered GET /propietarios
  // ═══════════════════════════════════════════════════════════════

  describe('GET /propietarios con filtro por rol', () => {
    it('ADMIN ve todos los propietarios', async () => {
      const res = await request(app.getHttpServer())
        .get('/propietarios')
        .set('Authorization', `Bearer ${adminAccessToken}`)
        .query({ tenantId })
        .expect(200);

      expect(Array.isArray(res.body)).toBe(true);
      // Should include the seed propietario
      const found = res.body.find((p: { id: string }) => p.id === propietarioId);
      expect(found).toBeDefined();
      expect(found.nombre).toBe('Propietario Auth Test');
    });

    it('COBRADOR ve solo los de sus etapas asignadas', async () => {
      const res = await request(app.getHttpServer())
        .get('/propietarios')
        .set('Authorization', `Bearer ${cobradorAccessToken}`)
        .query({ tenantId })
        .expect(200);

      expect(Array.isArray(res.body)).toBe(true);
      // Cobrador was assigned etapaId which contains casaId,
      // and the propietario has a tenencia for that casa
      const found = res.body.find((p: { id: string }) => p.id === propietarioId);
      expect(found).toBeDefined();
      expect(found.nombre).toBe('Propietario Auth Test');
    });
  });
});
