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
 * [Regresión C5] IDOR en GET /pagos
 *
 * Antes del fix, `listByResidente` hacía fallback al query string:
 *   const targetId = residenteId ?? user.residenteId;
 * por lo que un RESIDENTE podía leer los pagos de terceros con
 * `GET /pagos?residenteId=<víctima>` (fuga financiera cross-residente).
 *
 * El fix obliga a usar SIEMPRE el residenteId del JWT para el rol RESIDENTE.
 * Este spec lo demuestra end-to-end vía HTTP real (supertest) contra la API
 * montada con AppModule completo (JWT + guards + repos reales), igual que
 * en producción.
 */
jest.setTimeout(30000);

describe('Pagos API — [Regresión C5] IDOR entre residentes', () => {
  let app: INestApplication;
  let dataSource: DataSource;
  let cobroRepository: CobroRepository;

  // ── Identidades ──────────────────────────────────────────
  let tenantId: string;
  let proyectoId: string;
  let residenteAId: string; // atacante (tiene cuenta)
  let residenteBId: string; // víctima (tiene cuenta)
  let residenteB2Id: string; // víctima sin cuenta de usuario

  // ── Tokens ───────────────────────────────────────────────
  let tokenA: string; // RESIDENTE A
  let tokenB: string; // RESIDENTE B
  let tokenC: string; // RESIDENTE C (cuenta sin residenteId vinculado)
  let adminToken: string; // ADMIN (control: sí puede filtrar por query)

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

    tenantId = randomUUID();
    proyectoId = randomUUID();
    residenteAId = randomUUID();
    residenteBId = randomUUID();
    residenteB2Id = randomUUID();
    const manzanaId = randomUUID();
    const etapaId = randomUUID();
    const casaIdA = randomUUID();
    const casaIdB = randomUUID();
    const adminUserId = randomUUID();
    const userAId = randomUUID();
    const userBId = randomUUID();
    const userCId = randomUUID();

    // ── Datos huérfanos de corridas previas ─────────────────
    await purgarEmails(dataSource, [
      'c5-admin@test.com',
      'c5-residente-a@test.com',
      'c5-residente-b@test.com',
    ]);

    // ── Seed de comunidad (proyecto → etapa → manzana → casas) ──
    await dataSource.query(
      `INSERT INTO proyectos (id, nombre, tenant_id) VALUES ($1, $2, $3)`,
      [proyectoId, 'Proyecto C5 IDOR', tenantId],
    );
    await dataSource.query(
      `INSERT INTO etapas (id, nombre, proyecto_id) VALUES ($1, $2, $3)`,
      [etapaId, 'Etapa C5', proyectoId],
    );
    await dataSource.query(
      `INSERT INTO manzanas (id, nombre, etapa_id) VALUES ($1, $2, $3)`,
      [manzanaId, 'Manzana C5', etapaId],
    );
    await dataSource.query(
      `INSERT INTO casas (id, direccion_interna, manzana_id) VALUES ($1, $2, $3)`,
      [casaIdA, 'Casa C5 A', manzanaId],
    );
    await dataSource.query(
      `INSERT INTO casas (id, direccion_interna, manzana_id) VALUES ($1, $2, $3)`,
      [casaIdB, 'Casa C5 B', manzanaId],
    );

    // Residentes A (atacante), B (víctima con cuenta) y B2 (sin cuenta)
    await dataSource.query(
      `INSERT INTO residentes (id, nombre, telefono, tenant_id) VALUES ($1, $2, $3, $4)`,
      [residenteAId, 'Residente C5 Atacante', '555-0001', tenantId],
    );
    await dataSource.query(
      `INSERT INTO residentes (id, nombre, telefono, tenant_id) VALUES ($1, $2, $3, $4)`,
      [residenteBId, 'Residente C5 Victima', '555-0002', tenantId],
    );
    await dataSource.query(
      `INSERT INTO residentes (id, nombre, telefono, tenant_id) VALUES ($1, $2, $3, $4)`,
      [residenteB2Id, 'Residente C5 Sin Cuenta', '555-0003', tenantId],
    );
    await dataSource.query(
      `INSERT INTO tenencias (id, residente_id, casa_id, fecha_inicio) VALUES ($1, $2, $3, $4)`,
      [randomUUID(), residenteAId, casaIdA, '2026-01-01'],
    );
    await dataSource.query(
      `INSERT INTO tenencias (id, residente_id, casa_id, fecha_inicio) VALUES ($1, $2, $3, $4)`,
      [randomUUID(), residenteBId, casaIdB, '2026-01-01'],
    );

    // ── Usuarios (hash bcrypt real, login vía HTTP) ──────────
    await dataSource.query(
      `INSERT INTO usuarios (id, email, password_hash, nombre, rol, residente_id, tenant_id, activo)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [
        adminUserId,
        'c5-admin@test.com',
        bcryptHashSync('c5pass1', 10),
        'Admin C5',
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
        userAId,
        'c5-residente-a@test.com',
        bcryptHashSync('c5pass2', 10),
        'Usuario Residente A',
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
        userBId,
        'c5-residente-b@test.com',
        bcryptHashSync('c5pass3', 10),
        'Usuario Residente B',
        'RESIDENTE',
        residenteBId,
        tenantId,
        true,
      ],
    );
    // Cuenta RESIDENTE huérfana: sin residenteId vinculado (caso unitario del fix:
    // con query falsificado debe devolver vacío, nunca pagos de terceros)
    await dataSource.query(
      `INSERT INTO usuarios (id, email, password_hash, nombre, rol, residente_id, tenant_id, activo)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [
        userCId,
        'c5-residente-c@test.com',
        bcryptHashSync('c5pass4', 10),
        'Usuario Residente C (sin residente)',
        'RESIDENTE',
        null,
        tenantId,
        true,
      ],
    );

    // ── Logins reales por HTTP (JWT firmado como en producción) ──
    const adminLogin = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ username: 'c5-admin@test.com', password: 'c5pass1' })
      .expect(201);
    adminToken = adminLogin.body.accessToken;

    const loginA = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ username: 'c5-residente-a@test.com', password: 'c5pass2' })
      .expect(201);
    tokenA = loginA.body.accessToken;

    const loginB = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ username: 'c5-residente-b@test.com', password: 'c5pass3' })
      .expect(201);
    tokenB = loginB.body.accessToken;

    const loginC = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ username: 'c5-residente-c@test.com', password: 'c5pass4' })
      .expect(201);
    tokenC = loginC.body.accessToken;

    // ── Planes de cobro activos (requeridos para registrar pagos) ──
    await dataSource.query(
      `INSERT INTO planes_de_cobro (id, residente_id, tenant_id, proyecto_id, modalidad, valor_mensual, fecha_activacion)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [randomUUID(), residenteAId, tenantId, proyectoId, 'MENSUAL', 4000000, '2026-01-01'],
    );
    await dataSource.query(
      `INSERT INTO planes_de_cobro (id, residente_id, tenant_id, proyecto_id, modalidad, valor_mensual, fecha_activacion)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [randomUUID(), residenteBId, tenantId, proyectoId, 'MENSUAL', 4000000, '2026-01-01'],
    );

    // ── Pagos sembrados: 1 pago para A y 1 pago para B ──────
    await seedPagoPara(residenteAId, 'C5 pago del atacante');
    await seedPagoPara(residenteBId, 'C5 pago de la víctima');
  });

  /** Crea cuota + registra un pago vía HTTP como ADMIN para el residente dado. */
  async function seedPagoPara(residenteId: string, concepto: string) {
    await cobroRepository.save(
      Cobro.crear(
        residenteId,
        tenantId,
        concepto,
        Money.ofCOP(40000),
        '2026-01-01',
        '2026-02-01',
        '2026-01-15',
      ),
    );
    await request(app.getHttpServer())
      .post('/pagos')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        clientPaymentId: `c5-${residenteId.slice(0, 8)}-${randomUUID()}`,
        monto: 40000,
        fechaPago: '2026-01-20',
        residenteId,
      })
      .expect(201);
  }

  afterAll(async () => {
    if (!dataSource || !dataSource.isInitialized) return;
    await limpiarTenant(dataSource, tenantId);
    await app.close();
  });

  // ═══════════════════════════════════════════════════════════════
  // El ataque: RESIDENTE con ?residenteId falsificado
  // ═══════════════════════════════════════════════════════════════

  describe('RESIDENTE con ?residenteId falsificado (el vector del IDOR)', () => {
    it('GET /pagos?residenteId=<víctima> devuelve SOLO los pagos propios del atacante', async () => {
      const res = await request(app.getHttpServer())
        .get('/pagos')
        .set('Authorization', `Bearer ${tokenA}`)
        .query({ residenteId: residenteBId }) // ← falsificación del vector original
        .expect(200);

      expect(Array.isArray(res.body)).toBe(true);
      // Nunca debe aparecer el pago de la víctima
      const ids = res.body.map((p: any) => p.residenteId);
      expect(ids).not.toContain(residenteBId);
      // Todo lo devuelto pertenece al atacante
      expect(ids.length).toBeGreaterThan(0);
      expect(new Set(ids)).toEqual(new Set([residenteAId]));
    });

    it('sin query param devuelve exactamente los mismos pagos propios', async () => {
      const conQuery = await request(app.getHttpServer())
        .get('/pagos')
        .set('Authorization', `Bearer ${tokenA}`)
        .query({ residenteId: residenteBId })
        .expect(200);

      const sinQuery = await request(app.getHttpServer())
        .get('/pagos')
        .set('Authorization', `Bearer ${tokenA}`)
        .expect(200);

      expect(sinQuery.body.map((p: any) => p.id).sort()).toEqual(
        conQuery.body.map((p: any) => p.id).sort(),
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Variantes del vector (identidades existentes, UUID al azar, auto)
  // ═══════════════════════════════════════════════════════════════

  describe('Variantes del vector', () => {
    it('RESIDENTE con ?residenteId de tercero SIN pagos → el query se ignora: ve los suyos', async () => {
      // El fix NO delega en el query: la respuesta es idéntica a la de su propio
      // residenteId, sin importar el valor falsificado (válido, ajeno o basura).
      const res = await request(app.getHttpServer())
        .get('/pagos')
        .set('Authorization', `Bearer ${tokenA}`)
        .query({ residenteId: residenteB2Id })
        .expect(200);

      expect(Array.isArray(res.body)).toBe(true);
      for (const pago of res.body) {
        expect(pago.residenteId).toBe(residenteAId);
      }
    });

    it('RESIDENTE con ?residenteId inexistente (UUID al azar) → ve los suyos, nunca fuga', async () => {
      const res = await request(app.getHttpServer())
        .get('/pagos')
        .set('Authorization', `Bearer ${tokenA}`)
        .query({ residenteId: randomUUID() })
        .expect(200);

      for (const pago of res.body) {
        expect(pago.residenteId).toBe(residenteAId);
      }
    });

    it('cuenta RESIDENTE sin residenteId + ?residenteId=<víctima con pagos> → vacío (sin fuga)', async () => {
      // La víctima B SÍ tiene pagos sembrados; una cuenta huérfana no puede
      // usar su query como proxy para leerlos.
      const res = await request(app.getHttpServer())
        .get('/pagos')
        .set('Authorization', `Bearer ${tokenC}`)
        .query({ residenteId: residenteBId })
        .expect(200);

      expect(res.body).toEqual([]);
    });

    it('RESIDENTE sin query param ve sus propios pagos (flujo normal intacto)', async () => {
      const res = await request(app.getHttpServer())
        .get('/pagos')
        .set('Authorization', `Bearer ${tokenB}`)
        .expect(200);

      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBeGreaterThan(0);
      for (const pago of res.body) {
        expect(pago.residenteId).toBe(residenteBId);
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Control: el fix no debe romper ADMIN/COBRADOR (sí filtran por query)
  // ═══════════════════════════════════════════════════════════════

  describe('Control — roles con facultad de filtrar conservan el query param', () => {
    it('ADMIN con ?residenteId=<A> ve los pagos de A (comportamiento legítimo)', async () => {
      const res = await request(app.getHttpServer())
        .get('/pagos')
        .set('Authorization', `Bearer ${adminToken}`)
        .query({ residenteId: residenteAId })
        .expect(200);

      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBeGreaterThan(0);
      for (const pago of res.body) {
        expect(pago.residenteId).toBe(residenteAId);
      }
    });

    it('ADMIN con ?residenteId de residente sin pagos → vacío', async () => {
      const res = await request(app.getHttpServer())
        .get('/pagos')
        .set('Authorization', `Bearer ${adminToken}`)
        .query({ residenteId: residenteB2Id })
        .expect(200);

      expect(res.body).toEqual([]);
    });
  });
});
