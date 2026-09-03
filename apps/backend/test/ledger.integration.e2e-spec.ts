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

jest.setTimeout(30000);

describe('Ledger API Integration (Sprint 3)', () => {
  let app: INestApplication;
  let dataSource: DataSource;
  let cobroRepository: CobroRepository;

  // ── Shared IDs ───────────────────────────────────────────
  let tenantId: string;
  let proyectoId: string;
  let etapaId: string;
  let casaId: string;
  let residenteId: string;

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
    app.useGlobalInterceptors(
      new ClassSerializerInterceptor(app.get(Reflector)),
    );
    await app.init();

    dataSource = app.get(DataSource);
    cobroRepository = app.get(CobroRepository);

    // ── Generate IDs ─────────────────────────────────────
    tenantId = randomUUID();
    proyectoId = randomUUID();
    etapaId = randomUUID();
    casaId = randomUUID();
    residenteId = randomUUID();
    const tenenciaId = randomUUID();
    const adminUserId = randomUUID();
    const cobradorUserId = randomUUID();

    // ── Seed community data ──────────────────────────────
    await dataSource.query(
      `INSERT INTO proyectos (id, nombre, tenant_id) VALUES ($1, $2, $3)`,
      [proyectoId, 'Proyecto Ledger Test', tenantId],
    );
    await dataSource.query(
      `INSERT INTO etapas (id, nombre, proyecto_id) VALUES ($1, $2, $3)`,
      [etapaId, 'Etapa Ledger Test', proyectoId],
    );
    await dataSource.query(
      `INSERT INTO casas (id, direccion_interna, manzana_id)
       VALUES ($1, $2, (SELECT id FROM manzanas LIMIT 1))`,
      [casaId, 'Casa 001 Ledger'],
    );
    // Update direct etapa reference for test simplicity
    await dataSource.query(
      `UPDATE casas SET manzana_id = (SELECT id FROM manzanas WHERE etapa_id = $1 LIMIT 1) WHERE id = $2`,
      [etapaId, casaId],
    );

    // ── Seed users with hashed passwords ──────────────────
    const adminHash = bcryptHashSync('admin123', 10);
    const cobradorHash = bcryptHashSync('cobrador123', 10);

    await dataSource.query(
      `INSERT INTO usuarios (id, email, password_hash, nombre, rol, tenant_id, activo)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [
        adminUserId,
        'admin-ledger@test.com',
        adminHash,
        'Admin Ledger',
        'ADMIN',
        tenantId,
        true,
      ],
    );
    await dataSource.query(
      `INSERT INTO usuarios (id, email, password_hash, nombre, rol, tenant_id, activo)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [
        cobradorUserId,
        'cobrador-ledger@test.com',
        cobradorHash,
        'Cobrador Ledger',
        'COBRADOR',
        tenantId,
        true,
      ],
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
    await dataSource.query(`DELETE FROM cobros WHERE tenant_id = $1`, [
      tenantId,
    ]);
    await dataSource.query(`DELETE FROM planes_de_cobro WHERE tenant_id = $1`, [
      tenantId,
    ]);
    await dataSource.query(`DELETE FROM tarifas WHERE tenant_id = $1`, [
      tenantId,
    ]);
    await dataSource.query(
      `DELETE FROM montos_predefinidos WHERE tenant_id = $1`,
      [tenantId],
    );
    await dataSource.query(
      `DELETE FROM asignaciones_etapa WHERE tenant_id = $1`,
      [tenantId],
    );
    await dataSource.query(`DELETE FROM usuarios WHERE tenant_id = $1`, [
      tenantId,
    ]);
    await dataSource.query(`DELETE FROM casas WHERE id = $1`, [casaId]);
    await dataSource.query(`DELETE FROM etapas WHERE id = $1`, [etapaId]);
    await dataSource.query(`DELETE FROM proyectos WHERE id = $1`, [proyectoId]);
    await app.close();
  });

  // ═══════════════════════════════════════════════════════════
  // 1. Cobro Domain Logic
  // ═══════════════════════════════════════════════════════════
  describe('Cobro Domain Logic', () => {
    it('Applying partial payment changes estado to PARCIAL', async () => {
      const cobro = Cobro.crear(
        residenteId,
        tenantId,
        'Cobro test parcial',
        Money.ofCOP(100000),
        '2026-05-01',
        '2026-06-01',
        '2026-06-15',
      );
      const saved = await cobroRepository.save(cobro);

      expect(saved.estado).toBe('PENDIENTE');
      expect(saved.montoPagado).toBe(0);

      saved.aplicarPago(Money.ofCOP(30000));
      const updated = await cobroRepository.save(saved);

      expect(updated.estado).toBe('PARCIAL');
      expect(updated.montoPagado).toBe(30000);
    });

    it('Applying full payment changes estado to PAGADA', async () => {
      const cobro = Cobro.crear(
        residenteId,
        tenantId,
        'Cobro test completo',
        Money.ofCOP(100000),
        '2026-06-01',
        '2026-07-01',
        '2026-07-15',
      );
      const saved = await cobroRepository.save(cobro);

      saved.aplicarPago(Money.ofCOP(100000));
      const updated = await cobroRepository.save(saved);

      expect(updated.estado).toBe('PAGADA');
      expect(updated.montoPagado).toBe(100000);
    });

    it('marcarVencida() on PENDIENTE changes estado to VENCIDA', async () => {
      const cobro = Cobro.crear(
        residenteId,
        tenantId,
        'Cobro test vencimiento',
        Money.ofCOP(100000),
        '2026-07-01',
        '2026-08-01',
        '2026-08-15',
      );
      const saved = await cobroRepository.save(cobro);

      expect(saved.estado).toBe('PENDIENTE');
      saved.marcarVencida();
      const updated = await cobroRepository.save(saved);

      expect(updated.estado).toBe('VENCIDA');
    });

    it('marcarVencida() on PAGADA does nothing', async () => {
      const cobro = Cobro.crear(
        residenteId,
        tenantId,
        'Cobro test no-change',
        Money.ofCOP(100000),
        '2026-08-01',
        '2026-09-01',
        '2026-09-15',
      );
      const saved = await cobroRepository.save(cobro);
      saved.aplicarPago(Money.ofCOP(100000));

      expect(saved.estado).toBe('PAGADA');
      saved.marcarVencida();
      const afterVencida = await cobroRepository.save(saved);

      expect(afterVencida.estado).toBe('PAGADA');
    });
  });
});
