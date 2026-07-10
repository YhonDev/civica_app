import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe, ClassSerializerInterceptor } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import request from 'supertest';
import { DataSource } from 'typeorm';
import { hashSync as bcryptHashSync } from 'bcrypt';
import { randomUUID } from 'node:crypto';
import { AppModule } from '../src/app.module';
import { CuotaRepository } from '../src/ledger/infrastructure/persistence/cuota.repository';
import { Cuota } from '../src/ledger/domain/cuota.entity';
import { Money } from '../src/shared/common/value-objects';

jest.setTimeout(30000);

describe('Ledger API Integration (Sprint 3)', () => {
  let app: INestApplication;
  let dataSource: DataSource;
  let cuotaRepository: CuotaRepository;

  // ── Shared IDs ───────────────────────────────────────────
  let tenantId: string;
  let conjuntoId: string;
  let etapaId: string;
  let casaId: string;
  let propietarioId: string;

  // ── Auth tokens ──────────────────────────────────────────
  let adminToken: string;
  let cobradorToken: string;

  // ── IDs for ledger entities ──────────────────────────────
  let tarifaId: string;

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
    cuotaRepository = app.get(CuotaRepository);

    // ── Generate IDs ─────────────────────────────────────
    tenantId = randomUUID();
    conjuntoId = randomUUID();
    etapaId = randomUUID();
    casaId = randomUUID();
    propietarioId = randomUUID();
    const tenenciaId = randomUUID();
    const adminUserId = randomUUID();
    const cobradorUserId = randomUUID();

    // ── Seed community data (conjunto → etapa → casa → propietario → tenencia) ──
    await dataSource.query(
      `INSERT INTO conjuntos (id, nombre, tenant_id) VALUES ($1, $2, $3)`,
      [conjuntoId, 'Conjunto Ledger Test', tenantId],
    );
    await dataSource.query(
      `INSERT INTO etapas (id, nombre, conjunto_id) VALUES ($1, $2, $3)`,
      [etapaId, 'Etapa Ledger Test', conjuntoId],
    );
    await dataSource.query(
      `INSERT INTO casas (id, direccion_interna, etapa_id) VALUES ($1, $2, $3)`,
      [casaId, 'Casa 001 Ledger', etapaId],
    );
    await dataSource.query(
      `INSERT INTO propietarios (id, nombre, telefono, tenant_id) VALUES ($1, $2, $3, $4)`,
      [propietarioId, 'Propietario Ledger Test', '555-9999', tenantId],
    );
    await dataSource.query(
      `INSERT INTO tenencias (id, propietario_id, casa_id, fecha_inicio) VALUES ($1, $2, $3, $4)`,
      [tenenciaId, propietarioId, casaId, '2026-01-01'],
    );

    // ── Seed users with hashed passwords ──────────────────
    const adminHash = bcryptHashSync('admin123', 10);
    const cobradorHash = bcryptHashSync('cobrador123', 10);

    await dataSource.query(
      `INSERT INTO usuarios (id, email, password_hash, nombre, rol, propietario_id, tenant_id, activo)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [adminUserId, 'admin-ledger@test.com', adminHash, 'Admin Ledger', 'ADMIN', null, tenantId, true],
    );
    await dataSource.query(
      `INSERT INTO usuarios (id, email, password_hash, nombre, rol, propietario_id, tenant_id, activo)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [cobradorUserId, 'cobrador-ledger@test.com', cobradorHash, 'Cobrador Ledger', 'COBRADOR', null, tenantId, true],
    );

    // ── Login to get admin token ──────────────────────────
    const adminLoginRes = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: 'admin-ledger@test.com', password: 'admin123' })
      .expect(201);
    adminToken = adminLoginRes.body.accessToken;

    // ── Login to get cobrador token ───────────────────────
    const cobradorLoginRes = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: 'cobrador-ledger@test.com', password: 'cobrador123' })
      .expect(201);
    cobradorToken = cobradorLoginRes.body.accessToken;
  });

  afterAll(async () => {
    // Clean up ledger data first (reverse creation order / FK-safe)
    await dataSource.query(`DELETE FROM cuotas WHERE tenant_id = $1`, [tenantId]);
    await dataSource.query(`DELETE FROM cuentas_cartera WHERE tenant_id = $1`, [tenantId]);
    await dataSource.query(`DELETE FROM tarifas WHERE tenant_id = $1`, [tenantId]);
    await dataSource.query(`DELETE FROM montos_predefinidos WHERE tenant_id = $1`, [tenantId]);

    // Clean up IAM / community data
    await dataSource.query(`DELETE FROM asignaciones_etapa WHERE tenant_id = $1`, [tenantId]);
    await dataSource.query(`DELETE FROM tenencias WHERE propietario_id = $1`, [propietarioId]);
    await dataSource.query(`DELETE FROM usuarios WHERE tenant_id = $1`, [tenantId]);
    await dataSource.query(`DELETE FROM propietarios WHERE tenant_id = $1`, [tenantId]);
    await dataSource.query(`DELETE FROM casas WHERE id = $1`, [casaId]);
    await dataSource.query(`DELETE FROM etapas WHERE id = $1`, [etapaId]);
    await dataSource.query(`DELETE FROM conjuntos WHERE id = $1`, [conjuntoId]);

    await app.close();
  });

  // ═══════════════════════════════════════════════════════════
  // 1. Tarifas CRUD
  // ═══════════════════════════════════════════════════════════

  describe('Tarifas CRUD', () => {
    const montoPesos = 50000; // 50.000 COP in pesos
    const montoCentavos = 5000000; // 50.000 * 100 = 5.000.000 centavos

    it('POST /tarifas as ADMIN → 201, returns tarifa with monto in centavos', async () => {
      const res = await request(app.getHttpServer())
        .post('/tarifas')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          conjuntoId,
          frecuencia: 'MENSUAL',
          monto: montoPesos,
          fechaVigencia: '2026-01-15',
        })
        .expect(201);

      expect(res.body).toHaveProperty('id');
      expect(res.body.conjuntoId).toBe(conjuntoId);
      expect(res.body.frecuencia).toBe('MENSUAL');
      expect(res.body.monto).toBe(montoCentavos);
      expect(res.body.fechaVigencia).toBe('2026-01-15');
      expect(res.body.activa).toBe(true);
      tarifaId = res.body.id;
    });

    it('GET /tarifas?conjuntoId= → 200, returns list', async () => {
      const res = await request(app.getHttpServer())
        .get('/tarifas')
        .set('Authorization', `Bearer ${adminToken}`)
        .query({ conjuntoId })
        .expect(200);

      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBeGreaterThanOrEqual(1);
      const created = res.body.find((t: { id: string }) => t.id === tarifaId);
      expect(created).toBeDefined();
      expect(created.monto).toBe(montoCentavos);
    });

    it('PATCH /tarifas/:id → 200, updates monto', async () => {
      const nuevoMontoPesos = 60000;
      const nuevoMontoCentavos = 6000000;

      const res = await request(app.getHttpServer())
        .patch(`/tarifas/${tarifaId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ monto: nuevoMontoPesos })
        .expect(200);

      expect(res.body).toHaveProperty('id');
      expect(res.body.monto).toBe(nuevoMontoCentavos);

      // Reset back for other tests
      await request(app.getHttpServer())
        .patch(`/tarifas/${tarifaId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ monto: montoPesos })
        .expect(200);
    });

    it('DELETE /tarifas/:id → 200, sets activa=false', async () => {
      const res = await request(app.getHttpServer())
        .delete(`/tarifas/${tarifaId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(res.body.message).toBe('Tarifa desactivada correctamente');

      // Verify soft-delete — tarifa still shows in list but activa=false
      const getRes = await request(app.getHttpServer())
        .get('/tarifas')
        .set('Authorization', `Bearer ${adminToken}`)
        .query({ conjuntoId })
        .expect(200);

      const tarifa = getRes.body.find((t: { id: string }) => t.id === tarifaId);
      expect(tarifa).toBeDefined();
      expect(tarifa.activa).toBe(false);

      // Re-activate for later test groups
      await dataSource.query(
        `UPDATE tarifas SET activa = true WHERE id = $1`,
        [tarifaId],
      );
    });

    it('POST /tarifas without JWT → 401', async () => {
      const res = await request(app.getHttpServer())
        .post('/tarifas')
        .send({
          conjuntoId,
          frecuencia: 'MENSUAL',
          monto: montoPesos,
          fechaVigencia: '2026-02-01',
        })
        .expect(401);

      expect(res.body).toHaveProperty('message');
    });

    it('POST /tarifas with COBRADOR token → 403', async () => {
      const res = await request(app.getHttpServer())
        .post('/tarifas')
        .set('Authorization', `Bearer ${cobradorToken}`)
        .send({
          conjuntoId,
          frecuencia: 'MENSUAL',
          monto: montoPesos,
          fechaVigencia: '2026-02-01',
        })
        .expect(403);

      expect(res.body).toHaveProperty('message');
    });
  });

  // ═══════════════════════════════════════════════════════════
  // 2. Montos Predefinidos
  // ═══════════════════════════════════════════════════════════

  describe('Montos Predefinidos', () => {
    let montoId1: string;

    it('POST /montos-predefinidos as ADMIN → 201, creates monto with auto orden', async () => {
      const res = await request(app.getHttpServer())
        .post('/montos-predefinidos')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          conjuntoId,
          monto: 10000,
          descripcion: 'Pago mínimo',
        })
        .expect(201);

      expect(res.body).toHaveProperty('id');
      expect(res.body.descripcion).toBe('Pago mínimo');
      expect(res.body.activo).toBe(true);
      expect(res.body.orden).toBe(1);
      montoId1 = res.body.id;
    });

    it('GET /montos-predefinidos?conjuntoId= → 200, returns active sorted by orden', async () => {
      const res = await request(app.getHttpServer())
        .get('/montos-predefinidos')
        .set('Authorization', `Bearer ${adminToken}`)
        .query({ conjuntoId })
        .expect(200);

      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBeGreaterThanOrEqual(1);
      // Should be sorted by orden ASC
      for (let i = 1; i < res.body.length; i++) {
        expect(res.body[i].orden).toBeGreaterThanOrEqual(res.body[i - 1].orden);
      }
      const created = res.body.find((m: { id: string }) => m.id === montoId1);
      expect(created).toBeDefined();
      expect(created.activo).toBe(true);
    });

    it('Can create up to 5 montos for the same conjunto', async () => {
      // We already have 1 — create 4 more to reach 5
      for (let i = 2; i <= 5; i++) {
        const res = await request(app.getHttpServer())
          .post('/montos-predefinidos')
          .set('Authorization', `Bearer ${adminToken}`)
          .send({
            conjuntoId,
            monto: 10000 + i * 5000,
            descripcion: `Monto opcional ${i}`,
          })
          .expect(201);

        expect(res.body.orden).toBe(i);
      }
    });

    it('Trying to create 6th monto → 400 with error message', async () => {
      const res = await request(app.getHttpServer())
        .post('/montos-predefinidos')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          conjuntoId,
          monto: 50000,
          descripcion: 'Sexto monto (debe fallar)',
        })
        .expect(400);

      expect(res.body).toHaveProperty('message');
      expect(res.body.message).toMatch(/máximo 5 montos/i);
    });

    it('DELETE /montos-predefinidos/:id → 200 (soft delete)', async () => {
      const res = await request(app.getHttpServer())
        .delete(`/montos-predefinidos/${montoId1}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(res.body.message).toBe('Monto desactivado correctamente');

      // Verify soft-delete: not in active list
      const listRes = await request(app.getHttpServer())
        .get('/montos-predefinidos')
        .set('Authorization', `Bearer ${adminToken}`)
        .query({ conjuntoId })
        .expect(200);

      const deleted = listRes.body.find((m: { id: string }) => m.id === montoId1);
      expect(deleted).toBeUndefined();
    });
  });

  // ═══════════════════════════════════════════════════════════
  // 3. Cuentas de Cartera
  // ═══════════════════════════════════════════════════════════

  describe('Cuentas de Cartera', () => {
    let cuentaId: string;

    it('POST /cuentas-cartera as ADMIN → 201', async () => {
      const res = await request(app.getHttpServer())
        .post('/cuentas-cartera')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          propietarioId,
          conjuntoId,
          frecuencia: 'MENSUAL',
          fechaActivacion: '2026-01-01',
        })
        .expect(201);

      expect(res.body).toHaveProperty('id');
      expect(res.body.propietarioId).toBe(propietarioId);
      expect(res.body.conjuntoId).toBe(conjuntoId);
      expect(res.body.frecuencia).toBe('MENSUAL');
      expect(res.body.fechaActivacion).toBe('2026-01-01');
      expect(res.body.activa).toBe(true);
      cuentaId = res.body.id;
    });

    it('GET /cuentas-cartera/:propietarioId → 200', async () => {
      const res = await request(app.getHttpServer())
        .get(`/cuentas-cartera/${propietarioId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(res.body).toHaveProperty('id');
      expect(res.body.id).toBe(cuentaId);
      expect(res.body.propietarioId).toBe(propietarioId);
      expect(res.body.frecuencia).toBe('MENSUAL');
    });

    it('PATCH /cuentas-cartera/:id/frecuencia → 200, changes frecuencia', async () => {
      const res = await request(app.getHttpServer())
        .patch(`/cuentas-cartera/${cuentaId}/frecuencia`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ frecuencia: 'QUINCENAL' })
        .expect(200);

      expect(res.body).toHaveProperty('id');
      expect(res.body.frecuencia).toBe('QUINCENAL');

      // Reset back for subsequent tests
      await request(app.getHttpServer())
        .patch(`/cuentas-cartera/${cuentaId}/frecuencia`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ frecuencia: 'MENSUAL' })
        .expect(200);
    });

    it('POST /cuentas-cartera duplicate propietario → 400', async () => {
      const res = await request(app.getHttpServer())
        .post('/cuentas-cartera')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          propietarioId,
          conjuntoId,
          frecuencia: 'SEMANAL',
          fechaActivacion: '2026-02-01',
        })
        .expect(400);

      expect(res.body).toHaveProperty('message');
      expect(res.body.message).toMatch(/ya tiene una cuenta/i);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // 4. Generar Cuotas
  // ═══════════════════════════════════════════════════════════

  describe('Generar Cuotas', () => {
    const montoPesos = 75000;
    const montoCentavos = 7500000;

    it('Creates a vigente tarifa for the account', async () => {
      // Create an active tarifa whose fechaVigencia is <= the fechaActivacion
      // so the Periodo.calcularSiguiente can find it as vigente.
      const res = await request(app.getHttpServer())
        .post('/tarifas')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          conjuntoId,
          frecuencia: 'MENSUAL',
          monto: montoPesos,
          fechaVigencia: '2026-01-01',
        })
        .expect(201);

      expect(res.body.monto).toBe(montoCentavos);
      expect(res.body.activa).toBe(true);
    });

    it('POST /cuotas/generar → 201, returns { generated: N } with N > 0', async () => {
      const res = await request(app.getHttpServer())
        .post('/cuotas/generar')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ conjuntoId })
        .expect(201);

      expect(res.body).toHaveProperty('generated');
      expect(typeof res.body.generated).toBe('number');
      expect(res.body.generated).toBeGreaterThan(0);
      expect(res.body).toHaveProperty('detalles');
      expect(Array.isArray(res.body.detalles)).toBe(true);
    });

    it('GET /cuotas/propietario/:propietarioId → 200, returns cuotas list', async () => {
      const res = await request(app.getHttpServer())
        .get(`/cuotas/propietario/${propietarioId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBeGreaterThanOrEqual(1);
    });

    it('Generated cuota has correct estado PENDIENTE, monto, and periodo', async () => {
      const res = await request(app.getHttpServer())
        .get(`/cuotas/propietario/${propietarioId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      const cuota = res.body[0];
      expect(cuota.estado).toBe('PENDIENTE');
      expect(cuota.monto).toBe(montoCentavos);
      expect(cuota.propietarioId).toBe(propietarioId);
      expect(cuota.periodoInicio).toBe('2026-01-01'); // starts from fechaActivacion
      expect(cuota.periodoFin).toBe('2026-02-01'); // MENSUAL adds 1 month
    });
  });

  // ═══════════════════════════════════════════════════════════
  // 5. Cuota Domain Logic (via repository)
  // ═══════════════════════════════════════════════════════════

  describe('Cuota Domain Logic', () => {
    it('Applying partial payment changes estado to PARCIAL', async () => {
      const cuota = Cuota.crear(
        propietarioId,
        tenantId,
        'Cuota test parcial',
        Money.ofCOP(100000), // 100.000 centavos = 1.000 COP
        '2026-05-01',
        '2026-06-01',
        '2026-06-15',
      );
      const saved = await cuotaRepository.save(cuota);

      expect(saved.estado).toBe('PENDIENTE');
      expect(saved.montoPagado).toBe(0);

      saved.aplicarPago(Money.ofCOP(30000)); // 300 centavos partial payment
      const updated = await cuotaRepository.save(saved);

      expect(updated.estado).toBe('PARCIAL');
      expect(updated.montoPagado).toBe(30000);
    });

    it('Applying full payment changes estado to PAGADA', async () => {
      const cuota = Cuota.crear(
        propietarioId,
        tenantId,
        'Cuota test completa',
        Money.ofCOP(100000),
        '2026-06-01',
        '2026-07-01',
        '2026-07-15',
      );
      const saved = await cuotaRepository.save(cuota);

      saved.aplicarPago(Money.ofCOP(100000)); // full payment
      const updated = await cuotaRepository.save(saved);

      expect(updated.estado).toBe('PAGADA');
      expect(updated.montoPagado).toBe(100000);
    });

    it('marcarVencida() on PENDIENTE changes estado to VENCIDA', async () => {
      const cuota = Cuota.crear(
        propietarioId,
        tenantId,
        'Cuota test vencimiento',
        Money.ofCOP(100000),
        '2026-07-01',
        '2026-08-01',
        '2026-08-15',
      );
      const saved = await cuotaRepository.save(cuota);

      expect(saved.estado).toBe('PENDIENTE');
      saved.marcarVencida();
      const updated = await cuotaRepository.save(saved);

      expect(updated.estado).toBe('VENCIDA');
    });

    it('marcarVencida() on PAGADA does nothing', async () => {
      const cuota = Cuota.crear(
        propietarioId,
        tenantId,
        'Cuota test no-change',
        Money.ofCOP(100000),
        '2026-08-01',
        '2026-09-01',
        '2026-09-15',
      );
      const saved = await cuotaRepository.save(cuota);
      saved.aplicarPago(Money.ofCOP(100000));
      const pagada = await cuotaRepository.save(saved);

      expect(pagada.estado).toBe('PAGADA');

      // marcarVencida on PAGADA should be a no-op
      pagada.marcarVencida();
      const afterVencida = await cuotaRepository.save(pagada);

      expect(afterVencida.estado).toBe('PAGADA');
    });

    it('aplicarPago on PAGADA throws error', async () => {
      const cuota = Cuota.crear(
        propietarioId,
        tenantId,
        'Cuota test error',
        Money.ofCOP(100000),
        '2026-09-01',
        '2026-10-01',
        '2026-10-15',
      );
      const saved = await cuotaRepository.save(cuota);
      saved.aplicarPago(Money.ofCOP(100000));
      const pagada = await cuotaRepository.save(saved);

      expect(() => {
        pagada.aplicarPago(Money.ofCOP(50000));
      }).toThrow('No se puede pagar una cuota ya PAGADA');
    });
  });
});
