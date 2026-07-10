import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe, ClassSerializerInterceptor } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import request from 'supertest';
import { DataSource, Repository } from 'typeorm';
import { hashSync as bcryptHashSync } from 'bcrypt';
import { randomUUID } from 'node:crypto';
import { AppModule } from '../src/app.module';
import { CuotaRepository } from '../src/ledger/infrastructure/persistence/cuota.repository';
import { Cuota } from '../src/ledger/domain/cuota.entity';
import { PagoRepository } from '../src/ledger/infrastructure/persistence/pago.repository';
import { MarcarVencidasUseCase } from '../src/ledger/application/use-cases/marcar-vencidas.use-case';
import { Money } from '../src/shared/common/value-objects';

jest.setTimeout(30000);

describe('Pagos API Integration — Sprint 4 (FIFO)', () => {
  let app: INestApplication;
  let dataSource: DataSource;
  let cuotaRepository: CuotaRepository;
  let cuotaOrmRepo: Repository<Cuota>;
  let pagoRepository: PagoRepository;
  let marcarVencidasUC: MarcarVencidasUseCase;

  // ── Shared IDs ───────────────────────────────────────────
  let tenantId: string;
  let conjuntoId: string;
  let etapaId: string;
  let casaId: string;
  let propietarioId: string;
  let propietarioSinCuentaId: string;

  // ── Auth tokens ──────────────────────────────────────────
  let adminToken: string;
  let cobradorToken: string;
  let propietarioToken: string;

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
    cuotaOrmRepo = dataSource.getRepository(Cuota);
    pagoRepository = app.get(PagoRepository);
    marcarVencidasUC = app.get(MarcarVencidasUseCase);

    // ── Generate IDs ─────────────────────────────────────
    tenantId = randomUUID();
    conjuntoId = randomUUID();
    etapaId = randomUUID();
    casaId = randomUUID();
    propietarioId = randomUUID();
    propietarioSinCuentaId = randomUUID();
    const tenenciaId = randomUUID();
    const adminUserId = randomUUID();
    const cobradorUserId = randomUUID();
    const propietarioUserId = randomUUID();

    // ── Seed community data ──────────────────────────────
    await dataSource.query(
      `INSERT INTO conjuntos (id, nombre, tenant_id) VALUES ($1, $2, $3)`,
      [conjuntoId, 'Conjunto Pagos Test', tenantId],
    );
    await dataSource.query(
      `INSERT INTO etapas (id, nombre, conjunto_id) VALUES ($1, $2, $3)`,
      [etapaId, 'Etapa Pagos Test', conjuntoId],
    );
    await dataSource.query(
      `INSERT INTO casas (id, direccion_interna, etapa_id) VALUES ($1, $2, $3)`,
      [casaId, 'Casa 001 Pagos', etapaId],
    );
    await dataSource.query(
      `INSERT INTO propietarios (id, nombre, telefono, tenant_id) VALUES ($1, $2, $3, $4)`,
      [propietarioId, 'Propietario Pagos Test', '555-1111', tenantId],
    );
    await dataSource.query(
      `INSERT INTO tenencias (id, propietario_id, casa_id, fecha_inicio) VALUES ($1, $2, $3, $4)`,
      [tenenciaId, propietarioId, casaId, '2026-01-01'],
    );

    // Second propietario (without CuentaDeCartera — for validation tests)
    await dataSource.query(
      `INSERT INTO propietarios (id, nombre, telefono, tenant_id) VALUES ($1, $2, $3, $4)`,
      [propietarioSinCuentaId, 'Propietario Sin Cuenta', '555-2222', tenantId],
    );

    // ── Seed users with hashed passwords ──────────────────
    const adminHash = bcryptHashSync('admin123', 10);
    const cobradorHash = bcryptHashSync('cobrador123', 10);
    const propHash = bcryptHashSync('prop123', 10);

    await dataSource.query(
      `INSERT INTO usuarios (id, email, password_hash, nombre, rol, propietario_id, tenant_id, activo)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [adminUserId, 'admin-pagos@test.com', adminHash, 'Admin Pagos', 'ADMIN', null, tenantId, true],
    );
    await dataSource.query(
      `INSERT INTO usuarios (id, email, password_hash, nombre, rol, propietario_id, tenant_id, activo)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [cobradorUserId, 'cobrador-pagos@test.com', cobradorHash, 'Cobrador Pagos', 'COBRADOR', null, tenantId, true],
    );
    await dataSource.query(
      `INSERT INTO usuarios (id, email, password_hash, nombre, rol, propietario_id, tenant_id, activo)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [propietarioUserId, 'prop-pagos@test.com', propHash, 'Prop Pagos', 'PROPIETARIO', propietarioId, tenantId, true],
    );

    // ── Login to get admin token ──────────────────────────
    const adminLoginRes = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: 'admin-pagos@test.com', password: 'admin123' })
      .expect(201);
    adminToken = adminLoginRes.body.accessToken;

    // ── Login to get cobrador token ───────────────────────
    const cobradorLoginRes = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: 'cobrador-pagos@test.com', password: 'cobrador123' })
      .expect(201);
    cobradorToken = cobradorLoginRes.body.accessToken;

    // ── Login to get propietario token ────────────────────
    const propLoginRes = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: 'prop-pagos@test.com', password: 'prop123' })
      .expect(201);
    propietarioToken = propLoginRes.body.accessToken;

    // ── Create CuentaDeCartera for main propietario ───────
    await request(app.getHttpServer())
      .post('/cuentas-cartera')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        propietarioId,
        conjuntoId,
        frecuencia: 'MENSUAL',
        fechaActivacion: '2026-01-01',
      })
      .expect(201);
  });

  afterAll(async () => {
    // Clean up in FK-safe order
    await dataSource.query(`DELETE FROM pagos WHERE tenant_id = $1`, [tenantId]);
    await dataSource.query(`DELETE FROM cuotas WHERE tenant_id = $1`, [tenantId]);
    await dataSource.query(`DELETE FROM cuentas_cartera WHERE tenant_id = $1`, [tenantId]);
    await dataSource.query(`DELETE FROM tarifas WHERE tenant_id = $1`, [tenantId]);
    await dataSource.query(`DELETE FROM montos_predefinidos WHERE tenant_id = $1`, [tenantId]);
    await dataSource.query(`DELETE FROM asignaciones_etapa WHERE tenant_id = $1`, [tenantId]);
    await dataSource.query(`DELETE FROM tenencias WHERE propietario_id = $1`, [propietarioId]);
    await dataSource.query(`DELETE FROM usuarios WHERE tenant_id = $1`, [tenantId]);
    await dataSource.query(`DELETE FROM propietarios WHERE tenant_id = $1`, [tenantId]);
    await dataSource.query(`DELETE FROM casas WHERE id = $1`, [casaId]);
    await dataSource.query(`DELETE FROM etapas WHERE id = $1`, [etapaId]);
    await dataSource.query(`DELETE FROM conjuntos WHERE id = $1`, [conjuntoId]);

    await app.close();
  });

  // ═══════════════════════════════════════════════════════════════
  // 1. FIFO Distribution — Registrar Pago
  // ═══════════════════════════════════════════════════════════════

  describe('FIFO Distribution — Registrar Pago', () => {
    // Each FIFO scenario starts with a clean slate for this propietario
    beforeEach(async () => {
      await dataSource.query(`DELETE FROM pagos WHERE propietario_id = $1`, [propietarioId]);
      await dataSource.query(`DELETE FROM cuotas WHERE propietario_id = $1`, [propietarioId]);
    });

    it('1.1 Pago parcial contra cuota más antigua', async () => {
      // Create 2 cuotas, same amount, ordered by periodoInicio
      // Cuota1: vence 2026-01-15 (más antigua)
      // Cuota2: vence 2026-02-15
      const cuota1 = Cuota.crear(
        propietarioId, tenantId, 'Cuota Ene 2026',
        Money.ofCOP(40000), '2026-01-01', '2026-02-01', '2026-01-15',
      );
      const cuota2 = Cuota.crear(
        propietarioId, tenantId, 'Cuota Feb 2026',
        Money.ofCOP(40000), '2026-02-01', '2026-03-01', '2026-02-15',
      );
      const saved1 = await cuotaRepository.save(cuota1);
      await cuotaRepository.save(cuota2);

      // Pago parcial de 10,000 centavos — should hit Cuota1 (oldest)
      const res = await request(app.getHttpServer())
        .post('/pagos')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          clientPaymentId: `fifo-partial-${randomUUID()}`,
          monto: 10000,
          fechaPago: '2026-01-20',
          propietarioId,
        })
        .expect(201);

      expect(res.body).toHaveProperty('pago');
      expect(res.body).toHaveProperty('cuotasAfectadas');
      expect(res.body.pago.monto).toBe(10000);
      expect(res.body.pago.cuotaId).toBe(saved1.id); // linked to first affected

      const afectadas = res.body.cuotasAfectadas;
      expect(afectadas.length).toBe(1);
      expect(afectadas[0].id).toBe(saved1.id);
      expect(afectadas[0].estado).toBe('PARCIAL');
      expect(afectadas[0].montoPagado).toBe(10000);
      // saldo = monto - montoPagado = 40000 - 10000 = 30000

      // Verify Cuota2 is unchanged via DB reload
      const reloaded = await cuotaOrmRepo.findOne({ where: { id: saved1.id } });
      expect(reloaded).not.toBeNull();
      expect(reloaded!.estado).toBe('PARCIAL');
      expect(reloaded!.montoPagado).toBe(10000);

      const allCuotas = await cuotaRepository.findByPropietario(propietarioId);
      const c2 = allCuotas.find(c => c.estado === 'PENDIENTE');
      expect(c2).toBeDefined();
      expect(c2!.montoPagado).toBe(0);
    });

    it('1.2 Pago exacto contra cuota más antigua (FIFO)', async () => {
      // Simulate prior state: Cuota1 is PARCIAL (10k paid), Cuota2 is PENDIENTE
      const cuota1 = Cuota.crear(
        propietarioId, tenantId, 'Cuota Ene 2026',
        Money.ofCOP(40000), '2026-01-01', '2026-02-01', '2026-01-15',
      );
      const cuota2 = Cuota.crear(
        propietarioId, tenantId, 'Cuota Feb 2026',
        Money.ofCOP(40000), '2026-02-01', '2026-03-01', '2026-02-15',
      );
      const saved1 = await cuotaRepository.save(cuota1);
      const saved2 = await cuotaRepository.save(cuota2);

      // Apply 10k partial to Cuota1 (simulating previous payment)
      saved1.aplicarPago(Money.ofCOP(10000));
      await cuotaRepository.save(saved1);

      // Now pay the remaining 30,000 — should complete Cuota1 (oldest with saldo)
      const res = await request(app.getHttpServer())
        .post('/pagos')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          clientPaymentId: `fifo-exact-${randomUUID()}`,
          monto: 30000,
          fechaPago: '2026-01-25',
          propietarioId,
        })
        .expect(201);

      const afectadas = res.body.cuotasAfectadas;
      expect(afectadas.length).toBe(1);
      expect(afectadas[0].id).toBe(saved1.id);
      expect(afectadas[0].estado).toBe('PAGADA');
      expect(afectadas[0].montoPagado).toBe(40000); // 10k + 30k = 40k total

      // Cuota2 must still be PENDIENTE
      const c2Reloaded = await cuotaOrmRepo.findOne({ where: { id: saved2.id } });
      expect(c2Reloaded!.estado).toBe('PENDIENTE');
      expect(c2Reloaded!.montoPagado).toBe(0);
    });

    it('1.3 Pago grande FIFO que cruza 2 cuotas', async () => {
      // 3 cuotas at 40k each, all PENDIENTE
      const cuota1 = Cuota.crear(
        propietarioId, tenantId, 'Cuota Ene 2026',
        Money.ofCOP(40000), '2026-01-01', '2026-02-01', '2026-01-15',
      );
      const cuota2 = Cuota.crear(
        propietarioId, tenantId, 'Cuota Feb 2026',
        Money.ofCOP(40000), '2026-02-01', '2026-03-01', '2026-02-15',
      );
      const cuota3 = Cuota.crear(
        propietarioId, tenantId, 'Cuota Mar 2026',
        Money.ofCOP(40000), '2026-03-01', '2026-04-01', '2026-03-15',
      );
      const saved1 = await cuotaRepository.save(cuota1);
      const saved2 = await cuotaRepository.save(cuota2);
      await cuotaRepository.save(cuota3);

      // Pago de 60,000: debe pagar Cuota1 completa (40k) + parcial Cuota2 (20k)
      const res = await request(app.getHttpServer())
        .post('/pagos')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          clientPaymentId: `fifo-cross-${randomUUID()}`,
          monto: 60000,
          fechaPago: '2026-01-30',
          propietarioId,
        })
        .expect(201);

      const afectadas = res.body.cuotasAfectadas;
      expect(afectadas.length).toBe(2);

      // Cuota1 debe estar PAGADA
      const c1Afectada = afectadas.find((c: any) => c.id === saved1.id);
      expect(c1Afectada).toBeDefined();
      expect(c1Afectada.estado).toBe('PAGADA');
      expect(c1Afectada.montoPagado).toBe(40000);

      // Cuota2 debe estar PARCIAL con 20k pagados
      const c2Afectada = afectadas.find((c: any) => c.id === saved2.id);
      expect(c2Afectada).toBeDefined();
      expect(c2Afectada.estado).toBe('PARCIAL');
      expect(c2Afectada.montoPagado).toBe(20000);

      // Cuota3 debe seguir PENDIENTE (no afectada)
      const allCuotas = await cuotaRepository.findByPropietario(propietarioId);
      const c3 = allCuotas.find(c => c.monto === 40000 && c.montoPagado === 0);
      expect(c3).toBeDefined();
      expect(c3!.estado).toBe('PENDIENTE');
    });

    it('1.4 Pago exacto que paga TODAS las cuotas', async () => {
      // 2 cuotas at 40k each, all PENDIENTE
      const cuota1 = Cuota.crear(
        propietarioId, tenantId, 'Cuota Ene 2026',
        Money.ofCOP(40000), '2026-01-01', '2026-02-01', '2026-01-15',
      );
      const cuota2 = Cuota.crear(
        propietarioId, tenantId, 'Cuota Feb 2026',
        Money.ofCOP(40000), '2026-02-01', '2026-03-01', '2026-02-15',
      );
      const saved1 = await cuotaRepository.save(cuota1);
      const saved2 = await cuotaRepository.save(cuota2);

      // Pago exacto de 80,000 = ambas cuotas
      const res = await request(app.getHttpServer())
        .post('/pagos')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          clientPaymentId: `fifo-full-${randomUUID()}`,
          monto: 80000,
          fechaPago: '2026-02-01',
          propietarioId,
        })
        .expect(201);

      const afectadas = res.body.cuotasAfectadas;
      expect(afectadas.length).toBe(2);

      const c1Afectada = afectadas.find((c: any) => c.id === saved1.id);
      expect(c1Afectada).toBeDefined();
      expect(c1Afectada.estado).toBe('PAGADA');

      const c2Afectada = afectadas.find((c: any) => c.id === saved2.id);
      expect(c2Afectada).toBeDefined();
      expect(c2Afectada.estado).toBe('PAGADA');

      // Verify both paid in DB
      const reloaded1 = await cuotaOrmRepo.findOne({ where: { id: saved1.id } });
      expect(reloaded1!.estado).toBe('PAGADA');
      expect(reloaded1!.montoPagado).toBe(40000);

      const reloaded2 = await cuotaOrmRepo.findOne({ where: { id: saved2.id } });
      expect(reloaded2!.estado).toBe('PAGADA');
      expect(reloaded2!.montoPagado).toBe(40000);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 2. Idempotencia
  // ═══════════════════════════════════════════════════════════════

  describe('Idempotencia', () => {
    beforeEach(async () => {
      await dataSource.query(`DELETE FROM pagos WHERE propietario_id = $1`, [propietarioId]);
      await dataSource.query(`DELETE FROM cuotas WHERE propietario_id = $1`, [propietarioId]);
    });

    it('Mismo clientPaymentId debe retornar mismo resultado sin duplicar cargos', async () => {
      const cuota = Cuota.crear(
        propietarioId, tenantId, 'Cuota Idempotencia',
        Money.ofCOP(40000), '2026-01-01', '2026-02-01', '2026-01-15',
      );
      const saved = await cuotaRepository.save(cuota);
      const clientPaymentId = `idempotent-${randomUUID()}`;

      // First call — pay full 40k
      const res1 = await request(app.getHttpServer())
        .post('/pagos')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          clientPaymentId,
          monto: 40000,
          fechaPago: '2026-01-20',
          propietarioId,
        })
        .expect(201);

      expect(res1.body.cuotasAfectadas.length).toBe(1);
      expect(res1.body.cuotasAfectadas[0].estado).toBe('PAGADA');

      // Second call with SAME clientPaymentId — must return same result
      const res2 = await request(app.getHttpServer())
        .post('/pagos')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          clientPaymentId,
          monto: 40000,
          fechaPago: '2026-01-20',
          propietarioId,
        })
        .expect(201);

      // Response should match (idempotent)
      expect(res2.body.pago.id).toBe(res1.body.pago.id);
      expect(res2.body.pago.monto).toBe(40000);

      // Cuota should NOT have been double-charged
      const reloaded = await cuotaOrmRepo.findOne({ where: { id: saved.id } });
      expect(reloaded!.montoPagado).toBe(40000); // Not 80000
      expect(reloaded!.estado).toBe('PAGADA');
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 3. Validation
  // ═══════════════════════════════════════════════════════════════

  describe('Validation', () => {
    it('Propietario sin CuentaDeCartera activa → 400', async () => {
      const res = await request(app.getHttpServer())
        .post('/pagos')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          clientPaymentId: `no-cuenta-${randomUUID()}`,
          monto: 10000,
          fechaPago: '2026-01-20',
          propietarioId: propietarioSinCuentaId,
        })
        .expect(400);

      expect(res.body).toHaveProperty('message');
      expect(res.body.message).toMatch(/no tiene una CuentaDeCartera/i);
    });

    it('Propietario sin cuotas pendientes → 400', async () => {
      // Create a single cuota and pay it in full first
      const cuota = Cuota.crear(
        propietarioId, tenantId, 'Cuota única',
        Money.ofCOP(40000), '2026-01-01', '2026-02-01', '2026-01-15',
      );
      await cuotaRepository.save(cuota);

      // Pay it
      await request(app.getHttpServer())
        .post('/pagos')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          clientPaymentId: `pay-once-${randomUUID()}`,
          monto: 40000,
          fechaPago: '2026-01-20',
          propietarioId,
        })
        .expect(201);

      // Now try another payment
      const res = await request(app.getHttpServer())
        .post('/pagos')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          clientPaymentId: `no-pendientes-${randomUUID()}`,
          monto: 10000,
          fechaPago: '2026-01-25',
          propietarioId,
        })
        .expect(400);

      expect(res.body).toHaveProperty('message');
      expect(res.body.message).toMatch(/no hay cuotas pendientes/i);
    });

    it('POST /pagos sin JWT → 401', async () => {
      const res = await request(app.getHttpServer())
        .post('/pagos')
        .send({
          clientPaymentId: 'no-jwt',
          monto: 10000,
          fechaPago: '2026-01-20',
          propietarioId,
        })
        .expect(401);

      expect(res.body).toHaveProperty('message');
    });

    it('POST /pagos con rol PROPIETARIO → 403', async () => {
      const res = await request(app.getHttpServer())
        .post('/pagos')
        .set('Authorization', `Bearer ${propietarioToken}`)
        .send({
          clientPaymentId: `role-prop-${randomUUID()}`,
          monto: 10000,
          fechaPago: '2026-01-20',
          propietarioId,
        })
        .expect(403);

      expect(res.body).toHaveProperty('message');
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 4. Marcar Vencidas (direct use case)
  // ═══════════════════════════════════════════════════════════════

  describe('MarcarVencidasUseCase', () => {
    beforeEach(async () => {
      await dataSource.query(`DELETE FROM pagos WHERE propietario_id = $1`, [propietarioId]);
      await dataSource.query(`DELETE FROM cuotas WHERE propietario_id = $1`, [propietarioId]);
    });

    it('Debe marcar cuotas PENDIENTE vencidas como VENCIDA', async () => {
      // Create a cuota con fechaVencimiento = ayer
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      const yesterdayStr = yesterday.toISOString().split('T')[0];

      const cuota = Cuota.crear(
        propietarioId, tenantId, 'Cuota vencida test',
        Money.ofCOP(40000), '2026-01-01', '2026-02-01', yesterdayStr,
      );
      const saved = await cuotaRepository.save(cuota);
      expect(saved.estado).toBe('PENDIENTE');

      // Execute marcarVencidas use case — uses today's date by default
      const result = await marcarVencidasUC.execute();
      expect(result.marcadas).toBeGreaterThanOrEqual(1);

      // Verify cuota was marked as VENCIDA
      const reloaded = await cuotaOrmRepo.findOne({ where: { id: saved.id } });
      expect(reloaded!.estado).toBe('VENCIDA');
    });

    it('No debe marcar cuotas PAGADA como VENCIDA', async () => {
      const cuota = Cuota.crear(
        propietarioId, tenantId, 'Cuota pagada no vence',
        Money.ofCOP(40000), '2026-01-01', '2026-02-01', '2020-01-01', // very old date
      );
      const saved = await cuotaRepository.save(cuota);
      saved.aplicarPago(Money.ofCOP(40000));
      await cuotaRepository.save(saved);
      expect(saved.estado).toBe('PAGADA');

      const result = await marcarVencidasUC.execute();
      // The PAGADA cuota should NOT be marked as VENCIDA
      const reloaded = await cuotaOrmRepo.findOne({ where: { id: saved.id } });
      expect(reloaded!.estado).toBe('PAGADA');
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 5. GET /pagos
  // ═══════════════════════════════════════════════════════════════

  describe('GET /pagos', () => {
    let registeredPagoId: string;

    beforeEach(async () => {
      await dataSource.query(`DELETE FROM pagos WHERE propietario_id = $1`, [propietarioId]);
      await dataSource.query(`DELETE FROM cuotas WHERE propietario_id = $1`, [propietarioId]);

      // Create a cuota and register a payment so we have data to query
      const cuota = Cuota.crear(
        propietarioId, tenantId, 'Cuota GET test',
        Money.ofCOP(40000), '2026-01-01', '2026-02-01', '2026-01-15',
      );
      await cuotaRepository.save(cuota);

      const res = await request(app.getHttpServer())
        .post('/pagos')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          clientPaymentId: `get-test-${randomUUID()}`,
          monto: 40000,
          fechaPago: '2026-01-20',
          propietarioId,
        })
        .expect(201);

      registeredPagoId = res.body.pago.id;
    });

    it('GET /pagos?propietarioId= debe retornar pagos del propietario', async () => {
      const res = await request(app.getHttpServer())
        .get('/pagos')
        .set('Authorization', `Bearer ${adminToken}`)
        .query({ propietarioId })
        .expect(200);

      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBeGreaterThanOrEqual(1);
      expect(res.body[0].propietarioId).toBe(propietarioId);
      expect(res.body[0].monto).toBe(40000);
    });

    it('GET /pagos/:id debe retornar detalle del pago', async () => {
      const res = await request(app.getHttpServer())
        .get(`/pagos/${registeredPagoId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(res.body).toHaveProperty('id');
      expect(res.body.id).toBe(registeredPagoId);
      expect(res.body.monto).toBe(40000);
      expect(res.body.propietarioId).toBe(propietarioId);
      expect(res.body).toHaveProperty('clientPaymentId');
      expect(res.body).toHaveProperty('fechaPago');
    });

    it('GET /pagos/:id con ID inexistente → 404', async () => {
      const fakeId = '00000000-0000-0000-0000-000000000000';
      const res = await request(app.getHttpServer())
        .get(`/pagos/${fakeId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(404);

      expect(res.body).toHaveProperty('message');
      expect(res.body.message).toContain('no encontrado');
    });
  });
});
