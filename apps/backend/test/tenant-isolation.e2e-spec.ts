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
import { CobroRepository } from '../src/ledger/infrastructure/persistence/cobro.repository';
import { Cobro } from '../src/ledger/domain/cobro.entity';
import { Money } from '../src/shared/common/value-objects';
import { limpiarTenant, purgarEmails } from './helpers/test-db';

/**
 * [Aislamiento multi-tenant] Un ADMIN del tenant A NO puede leer pagos ni
 * cobros del tenant B, aunque conozca los IDs exactos de los recursos de B
 * (el tenantId SIEMPRE viene del JWT, nunca de parametros del cliente).
 *
 * Vectores cubiertos:
 *   1. Referencia directa por ID:   GET /pagos/:idDeB
 *   2. Referencia por residenteId:  GET /pagos?residenteId=deB, GET /cobros/residente/deB
 *   3. Listado general:             GET /cobros sin filtros (nunca mezcla tenants)
 *   4. Write-path:                  POST /pagos con residenteId de B (rechazado)
 */
jest.setTimeout(30000);

describe('Aislamiento multi-tenant — ADMIN del tenant A vs datos del tenant B', () => {
  let app: INestApplication;
  let dataSource: DataSource;
  let cobroRepository: CobroRepository;

  // ── Tenants ──────────────────────────────────────────────
  let tenantA: string;
  let tenantB: string;

  // ── Recursos del tenant B (los que A intentara leer) ─────
  let cobroBId: string;
  let pagoBId: string;
  let residenteBId: string;

  // ── Tokens ───────────────────────────────────────────────
  let adminAToken: string; // ADMIN del tenant A
  let adminBToken: string; // ADMIN del tenant B (control: si ve sus datos)

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
    cobroRepository = app.get(CobroRepository);

    tenantA = randomUUID();
    tenantB = randomUUID();
    const proyectoB = randomUUID();
    residenteBId = randomUUID();
    const etapaB = randomUUID();
    const manzanaB = randomUUID();
    const casaB = randomUUID();
    const tenenciaB = randomUUID();
    const adminAUserId = randomUUID();
    const adminBUserId = randomUUID();

    await purgarEmails(dataSource, [
      'xt-admin-a@test.com',
      'xt-admin-b@test.com',
    ]);

    // ══ Tenant A: solo un ADMIN sin datos de ledger ══
    await dataSource.query(
      `INSERT INTO proyectos (id, nombre, tenant_id) VALUES ($1, $2, $3)`,
      [randomUUID(), 'Proyecto Tenant A', tenantA],
    );
    await dataSource.query(
      `INSERT INTO usuarios (id, email, password_hash, nombre, rol, residente_id, tenant_id, activo)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [
        adminAUserId,
        'xt-admin-a@test.com',
        bcryptHashSync('xtpass1', 10),
        'Admin Tenant A',
        'ADMIN',
        null,
        tenantA,
        true,
      ],
    );

    // ══ Tenant B: proyecto → etapa → manzana → casa → residente → plan → cobro → pago ══
    await dataSource.query(
      `INSERT INTO proyectos (id, nombre, tenant_id) VALUES ($1, $2, $3)`,
      [proyectoB, 'Proyecto Tenant B', tenantB],
    );
    await dataSource.query(
      `INSERT INTO etapas (id, nombre, proyecto_id) VALUES ($1, $2, $3)`,
      [etapaB, 'Etapa B', proyectoB],
    );
    await dataSource.query(
      `INSERT INTO manzanas (id, nombre, etapa_id) VALUES ($1, $2, $3)`,
      [manzanaB, 'Manzana B', etapaB],
    );
    await dataSource.query(
      `INSERT INTO casas (id, direccion_interna, manzana_id) VALUES ($1, $2, $3)`,
      [casaB, 'Casa B-001', manzanaB],
    );
    await dataSource.query(
      `INSERT INTO residentes (id, nombre, telefono, tenant_id) VALUES ($1, $2, $3, $4)`,
      [residenteBId, 'Residente Tenant B', '555-9000', tenantB],
    );
    await dataSource.query(
      `INSERT INTO tenencias (id, residente_id, casa_id, fecha_inicio) VALUES ($1, $2, $3, $4)`,
      [tenenciaB, residenteBId, casaB, '2026-01-01'],
    );
    await dataSource.query(
      `INSERT INTO usuarios (id, email, password_hash, nombre, rol, residente_id, tenant_id, activo)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [
        adminBUserId,
        'xt-admin-b@test.com',
        bcryptHashSync('xtpass2', 10),
        'Admin Tenant B',
        'ADMIN',
        null,
        tenantB,
        true,
      ],
    );
    await dataSource.query(
      `INSERT INTO planes_de_cobro (id, residente_id, tenant_id, proyecto_id, modalidad, valor_mensual, fecha_activacion)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [randomUUID(), residenteBId, tenantB, proyectoB, 'MENSUAL', 4000000, '2026-01-01'],
    );

    // Cobro del tenant B
    const cobroB = await cobroRepository.save(
      Cobro.crear(
        residenteBId,
        tenantB,
        'Cobro tenant B (confidencial)',
        Money.ofCOP(50000),
        '2026-01-01',
        '2026-02-01',
        '2026-01-15',
      ),
    );
    cobroBId = cobroB.id;

    // ── Logins ───────────────────────────────────────────────
    const loginA = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ username: 'xt-admin-a@test.com', password: 'xtpass1' })
      .expect(201);
    adminAToken = loginA.body.accessToken;

    const loginB = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ username: 'xt-admin-b@test.com', password: 'xtpass2' })
      .expect(201);
    adminBToken = loginB.body.accessToken;

    // Pago del tenant B, registrado por su propio ADMIN via HTTP
    const pagoRes = await request(app.getHttpServer())
      .post('/pagos')
      .set('Authorization', `Bearer ${adminBToken}`)
      .send({
        clientPaymentId: `xt-b-${randomUUID()}`,
        monto: 50000,
        fechaPago: '2026-01-20',
        residenteId: residenteBId,
      })
      .expect(201);
    pagoBId = pagoRes.body.pago.id;
  });

  afterAll(async () => {
    if (!dataSource || !dataSource.isInitialized) return;
    await limpiarTenant(dataSource, tenantA);
    await limpiarTenant(dataSource, tenantB);
    await app.close();
  });

  // ═══════════════════════════════════════════════════════════════
  // Vector 1: referencia directa por ID
  // ═══════════════════════════════════════════════════════════════

  describe('Referencia directa por ID', () => {
    it('GET /pagos/:idDeB → ADMIN A recibe 404 (el pago existe solo en el tenant B)', async () => {
      await request(app.getHttpServer())
        .get(`/pagos/${pagoBId}`)
        .set('Authorization', `Bearer ${adminAToken}`)
        .expect(404);
    });

    it('control: ADMIN B si puede leer su propio pago', async () => {
      const pago = await request(app.getHttpServer())
        .get(`/pagos/${pagoBId}`)
        .set('Authorization', `Bearer ${adminBToken}`)
        .expect(200);
      expect(pago.body.id).toBe(pagoBId);
      expect(pago.body.tenantId).toBe(tenantB);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Vector 2: referencia por residenteId del otro tenant
  // ═══════════════════════════════════════════════════════════════

  describe('Referencia por residenteId cross-tenant', () => {
    it('GET /pagos?residenteId=deB → ADMIN A obtiene lista vacia (nunca los pagos de B)', async () => {
      const res = await request(app.getHttpServer())
        .get('/pagos')
        .set('Authorization', `Bearer ${adminAToken}`)
        .query({ residenteId: residenteBId })
        .expect(200);

      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body).toEqual([]);
    });

    it('GET /cobros/residente/deB → ADMIN A obtiene lista vacia', async () => {
      const res = await request(app.getHttpServer())
        .get(`/cobros/residente/${residenteBId}`)
        .set('Authorization', `Bearer ${adminAToken}`)
        .expect(200);

      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body).toEqual([]);
    });

    it('control: ADMIN B si ve los pagos y cobros de su residente', async () => {
      const pagos = await request(app.getHttpServer())
        .get('/pagos')
        .set('Authorization', `Bearer ${adminBToken}`)
        .query({ residenteId: residenteBId })
        .expect(200);

      expect(pagos.body.length).toBeGreaterThan(0);
      for (const pago of pagos.body) {
        expect(pago.residenteId).toBe(residenteBId);
      }

      const cobros = await request(app.getHttpServer())
        .get(`/cobros/residente/${residenteBId}`)
        .set('Authorization', `Bearer ${adminBToken}`)
        .expect(200);

      expect(cobros.body.length).toBeGreaterThan(0);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // El listado general nunca mezcla tenants
  // ═══════════════════════════════════════════════════════════════

  describe('Listado general sin filtros', () => {
    it('GET /cobros del ADMIN A no contiene el cobro del tenant B', async () => {
      const res = await request(app.getHttpServer())
        .get('/cobros?limit=500')
        .set('Authorization', `Bearer ${adminAToken}`)
        .expect(200);

      expect(res.body).toHaveProperty('data');
      const ids = res.body.data.map((c: any) => c.id);
      expect(ids).not.toContain(cobroBId);
    });

    it('GET /cobros del ADMIN B contiene su cobro', async () => {
      const res = await request(app.getHttpServer())
        .get('/cobros?limit=500')
        .set('Authorization', `Bearer ${adminBToken}`)
        .expect(200);

      const ids = res.body.data.map((c: any) => c.id);
      expect(ids).toContain(cobroBId);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Write-path: no puede cargar pagos contra residentes ajenos
  // ═══════════════════════════════════════════════════════════════

  describe('Write-path cross-tenant', () => {
    it('POST /pagos con residenteId=deB → ADMIN A recibe 400 (plan de cobro inexistente en su tenant)', async () => {
      const res = await request(app.getHttpServer())
        .post('/pagos')
        .set('Authorization', `Bearer ${adminAToken}`)
        .send({
          clientPaymentId: `xt-attack-${randomUUID()}`,
          monto: 50000,
          fechaPago: '2026-01-20',
          residenteId: residenteBId,
        })
        .expect(400);

      expect(res.body).toHaveProperty('message');
      expect(res.body.message).toMatch(/no tiene un PlanDeCobro activo/i);
    });
  });
});
