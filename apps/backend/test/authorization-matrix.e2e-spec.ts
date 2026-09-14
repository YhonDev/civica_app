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
import { JwtService } from '@nestjs/jwt';

jest.setTimeout(45000);

describe('Matriz de Autorización Multi-Tenant — Aislamiento E2E', () => {
  let app: INestApplication;
  let dataSource: DataSource;
  let cobroRepository: CobroRepository;
  let jwtService: JwtService;

  // ── Tenants ──────────────────────────────────────────────
  let tenantA: string;
  let tenantB: string;

  // ── IDs Tenant A ─────────────────────────────────────────
  let proyectoAId: string;
  let etapaA1Id: string;
  let etapaA2Id: string;
  let manzanaA1Id: string;
  let manzanaA2Id: string;
  let casaA1Id: string;
  let casaA2Id: string;
  let residenteA1Id: string;
  let residenteA2Id: string;
  let cobroA1Id: string;
  let cobroA2Id: string;

  // ── IDs Tenant B ─────────────────────────────────────────
  let proyectoBId: string;
  let etapaBId: string;
  let manzanaBId: string;
  let casaBId: string;
  let residenteBId: string;
  let cobroBId: string;

  // ── Tokens ───────────────────────────────────────────────
  let adminAToken: string;
  let cobradorA1Token: string; // Cobrador asignado SOLO a Etapa A1
  let residenteA1Token: string;
  let residenteA2Token: string;
  let adminBToken: string;

  const emailsPurgar = [
    'matriz-admin-a@test.com',
    'matriz-cob-a1@test.com',
    'matriz-res-a1@test.com',
    'matriz-res-a2@test.com',
    'matriz-admin-b@test.com',
    'temp-logout@test.com',
  ];

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
    jwtService = app.get(JwtService);

    tenantA = randomUUID();
    tenantB = randomUUID();

    await purgarEmails(dataSource, emailsPurgar);

    // ═════════════════════════════════════════════════════════
    // SEED TENANT A
    // ═════════════════════════════════════════════════════════
    proyectoAId = randomUUID();
    etapaA1Id = randomUUID();
    etapaA2Id = randomUUID();
    manzanaA1Id = randomUUID();
    manzanaA2Id = randomUUID();
    casaA1Id = randomUUID();
    casaA2Id = randomUUID();
    residenteA1Id = randomUUID();
    residenteA2Id = randomUUID();

    const adminAUserId = randomUUID();
    const cobradorA1UserId = randomUUID();
    const residenteA1UserId = randomUUID();
    const residenteA2UserId = randomUUID();

    // Proyecto y Etapas
    await dataSource.query(
      `INSERT INTO proyectos (id, nombre, tenant_id) VALUES ($1, $2, $3)`,
      [proyectoAId, 'Proyecto Matriz A', tenantA],
    );
    await dataSource.query(
      `INSERT INTO etapas (id, nombre, proyecto_id) VALUES ($1, $2, $3), ($4, $5, $6)`,
      [etapaA1Id, 'Etapa A1', proyectoAId, etapaA2Id, 'Etapa A2', proyectoAId],
    );
    await dataSource.query(
      `INSERT INTO manzanas (id, nombre, etapa_id) VALUES ($1, $2, $3), ($4, $5, $6)`,
      [manzanaA1Id, 'Manzana A1', etapaA1Id, manzanaA2Id, 'Manzana A2', etapaA2Id],
    );
    await dataSource.query(
      `INSERT INTO casas (id, direccion_interna, manzana_id) VALUES ($1, $2, $3), ($4, $5, $6)`,
      [casaA1Id, 'Casa A1-01', manzanaA1Id, casaA2Id, 'Casa A2-01', manzanaA2Id],
    );

    // Residentes
    await dataSource.query(
      `INSERT INTO residentes (id, nombre, telefono, tenant_id) VALUES ($1, $2, $3, $4), ($5, $6, $7, $8)`,
      [
        residenteA1Id, 'Residente A1', '3001111111', tenantA,
        residenteA2Id, 'Residente A2', '3002222222', tenantA,
      ],
    );
    await dataSource.query(
      `INSERT INTO tenencias (id, residente_id, casa_id, fecha_inicio) VALUES ($1, $2, $3, $4), ($5, $6, $7, $8)`,
      [
        randomUUID(), residenteA1Id, casaA1Id, '2026-01-01',
        randomUUID(), residenteA2Id, casaA2Id, '2026-01-01',
      ],
    );

    // Usuarios Tenant A
    const defaultHash = bcryptHashSync('TestPass123!', 10);
    await dataSource.query(
      `INSERT INTO usuarios (id, email, password_hash, nombre, rol, residente_id, tenant_id, activo)
       VALUES 
       ($1, $2, $3, $4, $5, $6, $7, $8),
       ($9, $10, $11, $12, $13, $14, $15, $16),
       ($17, $18, $19, $20, $21, $22, $23, $24),
       ($25, $26, $27, $28, $29, $30, $31, $32)`,
      [
        adminAUserId, 'matriz-admin-a@test.com', defaultHash, 'Admin A', 'ADMIN', null, tenantA, true,
        cobradorA1UserId, 'matriz-cob-a1@test.com', defaultHash, 'Cobrador A1', 'COBRADOR', null, tenantA, true,
        residenteA1UserId, 'matriz-res-a1@test.com', defaultHash, 'Residente A1 User', 'RESIDENTE', residenteA1Id, tenantA, true,
        residenteA2UserId, 'matriz-res-a2@test.com', defaultHash, 'Residente A2 User', 'RESIDENTE', residenteA2Id, tenantA, true,
      ],
    );

    // Asignación territorial: Cobrador A1 asignado EXCLUSIVAMENTE a Etapa A1
    await dataSource.query(
      `INSERT INTO asignaciones_etapa (id, usuario_id, etapa_id, tenant_id) VALUES ($1, $2, $3, $4)`,
      [randomUUID(), cobradorA1UserId, etapaA1Id, tenantA],
    );

    // Cobros Tenant A
    const cobroA1 = await cobroRepository.save(
      Cobro.crear(
        residenteA1Id,
        tenantA,
        'Cuota Ene A1',
        Money.ofCOP(50000),
        '2026-01-01',
        '2026-02-01',
        '2026-01-15',
        casaA1Id,
      ),
    );
    cobroA1Id = cobroA1.id;

    const cobroA2 = await cobroRepository.save(
      Cobro.crear(
        residenteA2Id,
        tenantA,
        'Cuota Ene A2',
        Money.ofCOP(50000),
        '2026-01-01',
        '2026-02-01',
        '2026-01-15',
        casaA2Id,
      ),
    );
    cobroA2Id = cobroA2.id;

    // ═════════════════════════════════════════════════════════
    // SEED TENANT B
    // ═════════════════════════════════════════════════════════
    proyectoBId = randomUUID();
    etapaBId = randomUUID();
    manzanaBId = randomUUID();
    casaBId = randomUUID();
    residenteBId = randomUUID();
    const adminBUserId = randomUUID();

    await dataSource.query(
      `INSERT INTO proyectos (id, nombre, tenant_id) VALUES ($1, $2, $3)`,
      [proyectoBId, 'Proyecto Matriz B', tenantB],
    );
    await dataSource.query(
      `INSERT INTO etapas (id, nombre, proyecto_id) VALUES ($1, $2, $3)`,
      [etapaBId, 'Etapa B', proyectoBId],
    );
    await dataSource.query(
      `INSERT INTO manzanas (id, nombre, etapa_id) VALUES ($1, $2, $3)`,
      [manzanaBId, 'Manzana B', etapaBId],
    );
    await dataSource.query(
      `INSERT INTO casas (id, direccion_interna, manzana_id) VALUES ($1, $2, $3)`,
      [casaBId, 'Casa B-01', manzanaBId],
    );
    await dataSource.query(
      `INSERT INTO residentes (id, nombre, telefono, tenant_id) VALUES ($1, $2, $3, $4)`,
      [residenteBId, 'Residente B', '3003333333', tenantB],
    );
    await dataSource.query(
      `INSERT INTO tenencias (id, residente_id, casa_id, fecha_inicio) VALUES ($1, $2, $3, $4)`,
      [randomUUID(), residenteBId, casaBId, '2026-01-01'],
    );
    await dataSource.query(
      `INSERT INTO usuarios (id, email, password_hash, nombre, rol, residente_id, tenant_id, activo)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [adminBUserId, 'matriz-admin-b@test.com', defaultHash, 'Admin B', 'ADMIN', null, tenantB, true],
    );

    const cobroB = await cobroRepository.save(
      Cobro.crear(
        residenteBId,
        tenantB,
        'Cuota Ene B',
        Money.ofCOP(60000),
        '2026-01-01',
        '2026-02-01',
        '2026-01-15',
        casaBId,
      ),
    );
    cobroBId = cobroB.id;

    // ── OBTENER TOKENS MEDIANTE LOGIN ───────────────────────
    const login = async (email: string) => {
      const res = await request(app.getHttpServer())
        .post('/auth/login')
        .send({ username: email, password: 'TestPass123!' })
        .expect(201);
      return res.body.accessToken as string;
    };

    adminAToken = await login('matriz-admin-a@test.com');
    cobradorA1Token = await login('matriz-cob-a1@test.com');
    residenteA1Token = await login('matriz-res-a1@test.com');
    residenteA2Token = await login('matriz-res-a2@test.com');
    adminBToken = await login('matriz-admin-b@test.com');
  });

  afterAll(async () => {
    try {
      await purgarEmails(dataSource, emailsPurgar);
      if (tenantA) await limpiarTenant(dataSource, tenantA);
      if (tenantB) await limpiarTenant(dataSource, tenantB);
    } catch {
      // Ignorar errores en teardown
    }
    if (app) await app.close();
  });

  // ═══════════════════════════════════════════════════════════
  // 1. Aislamiento Cross-Residente (IDOR)
  // ═══════════════════════════════════════════════════════════
  describe('Vector 1 — Aislamiento Cross-Residente (IDOR)', () => {
    it('Residente A1 NO puede listar cobros de Residente A2 (403 Forbidden)', async () => {
      await request(app.getHttpServer())
        .get(`/cobros/residente/${residenteA2Id}`)
        .set('Authorization', `Bearer ${residenteA1Token}`)
        .expect(403);
    });

    it('Residente A1 NO puede crear una solicitud sobre el cobro de Residente A2 (403 Forbidden)', async () => {
      await request(app.getHttpServer())
        .post('/solicitudes')
        .set('Authorization', `Bearer ${residenteA1Token}`)
        .send({
          cobroId: cobroA2Id,
          tipo: 'SOLICITUD_REVISION',
          descripcion: 'Intento de manipular cuota de vecino',
        })
        .expect(403);
    });

    it('Residente A1 al consultar /pagos solo recibe sus propios pagos aunque envíe el residenteId de A2', async () => {
      const res = await request(app.getHttpServer())
        .get(`/pagos?residenteId=${residenteA2Id}`)
        .set('Authorization', `Bearer ${residenteA1Token}`)
        .expect(200);

      // No debe contener pagos ni datos de A2
      expect(Array.isArray(res.body)).toBe(true);
      const contieneA2 = res.body.some(
        (p: any) => p.residenteId === residenteA2Id,
      );
      expect(contieneA2).toBe(false);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // 2. Aislamiento Cross-Tenant
  // ═══════════════════════════════════════════════════════════
  describe('Vector 2 — Aislamiento Cross-Tenant', () => {
    it('Admin de Tenant A NO puede ver cobros de Tenant B (404/vacío)', async () => {
      const res = await request(app.getHttpServer())
        .get(`/cobros/residente/${residenteBId}`)
        .set('Authorization', `Bearer ${adminAToken}`)
        .expect(200);

      expect(res.body).toEqual([]);
    });

    it('Admin de Tenant A NO puede obtener proyecto de Tenant B (404 Not Found)', async () => {
      await request(app.getHttpServer())
        .get(`/proyectos/${proyectoBId}`)
        .set('Authorization', `Bearer ${adminAToken}`)
        .expect(404);
    });

    it('Cobrador de Tenant A NO puede registrar pago con residente de Tenant B (404/400)', async () => {
      await request(app.getHttpServer())
        .post('/pagos')
        .set('Authorization', `Bearer ${cobradorA1Token}`)
        .send({
          residenteId: residenteBId,
          monto: 6000000,
          metodo: 'EFECTIVO',
          cobroId: cobroBId,
        })
        .expect((res) => {
          expect([400, 403, 404]).toContain(res.status);
        });
    });
  });

  // ═══════════════════════════════════════════════════════════
  // 3. Segregación Territorial — Cobrador fuera de etapas
  // ═══════════════════════════════════════════════════════════
  describe('Vector 3 — Segregación Territorial de Cobrador', () => {
    it('Cobrador A1 (Etapa 1) NO puede registrar pago para Residente A2 (Etapa 2) (403 Forbidden)', async () => {
      await request(app.getHttpServer())
        .post('/pagos')
        .set('Authorization', `Bearer ${cobradorA1Token}`)
        .send({
          clientPaymentId: `pay-test-${randomUUID()}`,
          fechaPago: '2026-01-20',
          residenteId: residenteA2Id,
          monto: 5000000,
          cobroId: cobroA2Id,
        })
        .expect(403);
    });

    it('Cobrador A1 al consultar cobros de residente de Etapa 2 recibe lista vacía', async () => {
      const res = await request(app.getHttpServer())
        .get(`/cobros/residente/${residenteA2Id}`)
        .set('Authorization', `Bearer ${cobradorA1Token}`)
        .expect(200);

      expect(res.body).toEqual([]);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // 4. Modificación de recursos ajenos y privilegios RBAC
  // ═══════════════════════════════════════════════════════════
  describe('Vector 4 — Privilegios RBAC y Endpoints Administrativos', () => {
    it('Residente NO puede registrar nuevos usuarios (403 Forbidden)', async () => {
      await request(app.getHttpServer())
        .post('/auth/register')
        .set('Authorization', `Bearer ${residenteA1Token}`)
        .send({
          username: 'nuevo-hacker@test.com',
          password: 'Password123!',
          nombre: 'Hacker',
          rol: 'ADMIN',
        })
        .expect(403);
    });

    it('Residente NO puede acceder al endpoint de métricas (403 Forbidden)', async () => {
      await request(app.getHttpServer())
        .get('/metrics')
        .set('Authorization', `Bearer ${residenteA1Token}`)
        .expect(403);
    });

    it('Residente NO puede generar cobros (403 Forbidden)', async () => {
      await request(app.getHttpServer())
        .post('/cobros/generar')
        .set('Authorization', `Bearer ${residenteA1Token}`)
        .expect(403);
    });

    it('Cobrador NO puede ver reportes administrativos de recaudo (403 Forbidden)', async () => {
      await request(app.getHttpServer())
        .get(`/reportes/recaudo?proyectoId=${proyectoAId}`)
        .set('Authorization', `Bearer ${cobradorA1Token}`)
        .expect(403);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // 5. Ciclo de Vida e Invalidación de Tokens
  // ═══════════════════════════════════════════════════════════
  describe('Vector 5 — Ciclo de Vida e Invalidación de Tokens', () => {
    it('Petición con token falsificado/mal firmado es rechazada (401 Unauthorized)', async () => {
      await request(app.getHttpServer())
        .get('/cobros')
        .set('Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.falso.token')
        .expect(401);
    });

    it('Petición anónima a endpoint protegido es rechazada (401 Unauthorized)', async () => {
      await request(app.getHttpServer())
        .get('/cobros')
        .expect(401);
    });

    it('Token revocado mediante logout queda inmediatamente invalidado (401 Unauthorized)', async () => {
      // 1. Crear usuario temporal y generar token firmado directamente
      const tempUserId = randomUUID();
      const tempEmail = 'temp-logout@test.com';
      await dataSource.query(
        `INSERT INTO usuarios (id, email, password_hash, nombre, rol, tenant_id, activo)
         VALUES ($1, $2, $3, $4, $5, $6, $7)`,
        [
          tempUserId,
          tempEmail,
          bcryptHashSync('Temp123!', 10),
          'Temp Logout User',
          'RESIDENTE',
          tenantA,
          true,
        ],
      );

      const tempToken = jwtService.sign({
        sub: tempUserId,
        email: tempEmail,
        rol: 'RESIDENTE',
        tenantId: tenantA,
      });

      // 2. Verificar que el token funciona
      await request(app.getHttpServer())
        .get('/auth/sessions')
        .set('Authorization', `Bearer ${tempToken}`)
        .expect(200);

      // 3. Ejecutar logout enviando el accessToken en Authorization
      await request(app.getHttpServer())
        .post('/auth/logout')
        .set('Authorization', `Bearer ${tempToken}`)
        .send({})
        .expect(200);

      // 4. Verificar que el accessToken queda inmediatamente rechazado
      await request(app.getHttpServer())
        .get('/auth/sessions')
        .set('Authorization', `Bearer ${tempToken}`)
        .expect(401);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // 6. Manipulación de IDs relacionales
  // ═══════════════════════════════════════════════════════════
  describe('Vector 6 — Integridad y Validación de IDs Relacionales', () => {
    it('Solicitud con pagoId que no pertenece al cobroId es rechazada (400 BadRequest)', async () => {
      const fakePagoId = randomUUID();
      await request(app.getHttpServer())
        .post('/solicitudes')
        .set('Authorization', `Bearer ${residenteA1Token}`)
        .send({
          cobroId: cobroA1Id,
          pagoId: fakePagoId,
          tipo: 'SOLICITUD_REVISION',
          descripcion: 'Intento con pago inventado',
        })
        .expect(400);
    });
  });
});
