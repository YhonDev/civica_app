import { Test, TestingModule } from '@nestjs/testing';
import {
  INestApplication,
  ValidationPipe,
  ClassSerializerInterceptor,
} from '@nestjs/common';
import { HttpAdapterHost, Reflector } from '@nestjs/core';
import { Express } from 'express';
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
 * Enumerador automático de IDOR en endpoints GET
 * ═══════════════════════════════════════════════════════════════
 *
 * A diferencia de los specs dirigidos (C5, tenant-isolation), este suite NO
 * lista endpoints a mano: descubre en runtime TODAS las rutas GET registradas
 * en el router de Express (incluyendo rutas con arrays de paths) y sondea cada
 * una como RESIDENTE con:
 *
 *   1. Una batería de query params falsificados (residenteId/pagoId/cobroId/
 *      cuotaId/proyectoId de la víctima y UUIDs al azar).
 *   2. Path params rellenados con IDs que pertenecen a la víctima.
 *
 * Después escanea recursivamente cada respuesta buscando los IDs de la
 * víctima. Si UNO solo aparece en cualquier endpoint, el suite falla señalando
 * ruta, query y marcador exactos. Un endpoint futuro con un filtro IDOR
 * olvidado queda atrapado aquí sin necesidad de escribir un spec nuevo.
 *
 * Marcadores separados en dos niveles:
 *   - personMarkers: datos personales/financieros de la víctima (residente,
 *     cobro, pago, casa). PROHIBIDOS en toda respuesta para RESIDENTE A.
 *   - tenantConfigMarkers: configuración a nivel tenant (tarifas, montos
 *     predefinidos) que los residentes SÍ pueden ver legítimamente; solo se
 *     exige ausencia fuera de los endpoints de configuración.
 */
jest.setTimeout(90000);

/** Rutas de configuración del tenant: el RESIDENTE puede leerlas por diseño. */
const RUTAS_CONFIG_TENANT = new Set([
  '/tarifas',
  '/tarifas/vigentes',
  '/tarifas/:id',
  '/montos-predefinidos',
  '/proyectos',
  '/proyectos/actual',
]);

describe('Enumerador IDOR — RESIDENTE nunca recibe datos de terceros en GET', () => {
  let app: INestApplication;
  let dataSource: DataSource;

  // ── Identidades ──────────────────────────────────────────
  let tenantId: string;
  let proyectoId: string;
  let residenteAId: string; // atacante (cuenta RESIDENTE)
  let residenteBId: string; // víctima SIN cuenta de usuario

  // ── Datos de la víctima (marcadores de fuga) ─────────────
  let casaIdB: string;
  let cobroIdDeB: string;
  let pagoIdDeB: string;
  let tarifaIdDeB: string;
  let montoIdDeB: string;

  let tokenA: string;
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
    proyectoId = randomUUID();
    residenteAId = randomUUID();
    residenteBId = randomUUID();
    const etapaId = randomUUID();
    const manzanaId = randomUUID();
    const casaIdA = randomUUID();
    casaIdB = randomUUID();
    const adminUserId = randomUUID();
    const userAId = randomUUID();

    await purgarEmails(dataSource, [
      'idor-enum-admin@test.com',
      'idor-enum-a@test.com',
    ]);

    // ── Comunidad ────────────────────────────────────────────
    await dataSource.query(
      `INSERT INTO proyectos (id, nombre, tenant_id) VALUES ($1, $2, $3)`,
      [proyectoId, 'Proyecto Enum IDOR', tenantId],
    );
    await dataSource.query(
      `INSERT INTO etapas (id, nombre, proyecto_id) VALUES ($1, $2, $3)`,
      [etapaId, 'Etapa Enum', proyectoId],
    );
    await dataSource.query(
      `INSERT INTO manzanas (id, nombre, etapa_id) VALUES ($1, $2, $3)`,
      [manzanaId, 'Manzana Enum', etapaId],
    );
    await dataSource.query(
      `INSERT INTO casas (id, direccion_interna, manzana_id) VALUES ($1, $2, $3)`,
      [casaIdA, 'Casa Enum A', manzanaId],
    );
    await dataSource.query(
      `INSERT INTO casas (id, direccion_interna, manzana_id) VALUES ($1, $2, $3)`,
      [casaIdB, 'Casa Enum B (victima)', manzanaId],
    );
    await dataSource.query(
      `INSERT INTO residentes (id, nombre, telefono, tenant_id) VALUES ($1, $2, $3, $4)`,
      [residenteAId, 'Residente Enum Atacante', '556-0001', tenantId],
    );
    await dataSource.query(
      `INSERT INTO residentes (id, nombre, telefono, tenant_id) VALUES ($1, $2, $3, $4)`,
      [residenteBId, 'Residente Enum Victima', '556-0002', tenantId],
    );
    await dataSource.query(
      `INSERT INTO tenencias (id, residente_id, casa_id, fecha_inicio) VALUES ($1, $2, $3, $4)`,
      [randomUUID(), residenteAId, casaIdA, '2026-01-01'],
    );
    await dataSource.query(
      `INSERT INTO tenencias (id, residente_id, casa_id, fecha_inicio) VALUES ($1, $2, $3, $4)`,
      [randomUUID(), residenteBId, casaIdB, '2026-01-01'],
    );

    // ── Usuarios: ADMIN de control + RESIDENTE atacante ─────
    await dataSource.query(
      `INSERT INTO usuarios (id, email, password_hash, nombre, rol, residente_id, tenant_id, activo)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [
        adminUserId,
        'idor-enum-admin@test.com',
        bcryptHashSync('idorpass1', 10),
        'Admin Enum',
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
        'idor-enum-a@test.com',
        bcryptHashSync('idorpass2', 10),
        'Usuario Enum A',
        'RESIDENTE',
        residenteAId,
        tenantId,
        true,
      ],
    );

    const adminLogin = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ username: 'idor-enum-admin@test.com', password: 'idorpass1' })
      .expect(201);
    adminToken = adminLogin.body.accessToken;

    const loginA = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ username: 'idor-enum-a@test.com', password: 'idorpass2' })
      .expect(201);
    tokenA = loginA.body.accessToken;

    // ── Datos financieros de la víctima B ───────────────────
    await dataSource.query(
      `INSERT INTO planes_de_cobro (id, residente_id, tenant_id, proyecto_id, modalidad, valor_mensual, fecha_activacion)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [randomUUID(), residenteBId, tenantId, proyectoId, 'MENSUAL', 4000000, '2026-01-01'],
    );

    const cobro = Cobro.crear(
      residenteBId,
      tenantId,
      'Cobro Enum de la victima',
      Money.ofCOP(40000),
      '2026-01-01',
      '2026-02-01',
      '2026-01-15',
    );
    await app.get(CobroRepository).save(cobro);
    cobroIdDeB = cobro.id;

    const pagoRes = await request(app.getHttpServer())
      .post('/pagos')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        clientPaymentId: `idor-enum-${randomUUID()}`,
        monto: 40000,
        fechaPago: '2026-01-20',
        residenteId: residenteBId,
      })
      .expect(201);
    pagoIdDeB = pagoRes.body.pago.id;

    // Configuración de tenant a nombre del proyecto (marcadores de nivel 2)
    const tarifaRes = await request(app.getHttpServer())
      .post('/tarifas')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        proyectoId,
        modalidad: 'MENSUAL',
        monto: 40000,
        fechaVigencia: '2026-01-01',
      })
      .expect(201);
    tarifaIdDeB = tarifaRes.body.id;

    const montoRes = await request(app.getHttpServer())
      .post('/montos-predefinidos')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        proyectoId,
        monto: 25000,
        descripcion: 'Monto Enum victima',
      })
      .expect(201);
    montoIdDeB = montoRes.body.id;
  });

  afterAll(async () => {
    if (!dataSource || !dataSource.isInitialized) return;
    await limpiarTenant(dataSource, tenantId);
    await app.close();
  });

  // ═══════════════════════════════════════════════════════════════
  // Descubrimiento de rutas GET desde el router de Express
  // ═══════════════════════════════════════════════════════════════

  function descubrirRutasGet(): string[] {
    const httpAdapter = app.get(HttpAdapterHost).httpAdapter;
    const instance = (httpAdapter as unknown as {
      instance: Express;
    }).instance;
    // Express 5: `router`; Express 4: `_router`
    const router = (instance as any).router ?? (instance as any)._router;
    if (!router || !Array.isArray(router.stack)) {
      throw new Error(
        'No se pudo acceder al router de Express: la enumeración de rutas dejó de funcionar',
      );
    }
    const rutas = new Set<string>();
    for (const layer of router.stack) {
      if (!layer.route) continue;
      const methods = layer.route.methods ?? {};
      if (!methods.get) continue;
      const path = layer.route.path;
      for (const p of Array.isArray(path) ? path : [path]) {
        rutas.add(p);
      }
    }
    return [...rutas].sort();
  }

  /** Rellena los path params de una ruta con IDs de la víctima. */
  function materializarRuta(path: string): string {
    const valores: Record<string, string> = {
      id: cobroIdDeB, // recurso propio de la víctima → jamás debe servirlo
      residenteId: residenteBId,
      pagoId: pagoIdDeB,
      numero: 'TKT-2026-000000',
    };
    return path.replace(/:([A-Za-z0-9_]+)/g, (_m, nombre: string) => {
      const valor = valores[nombre] ?? randomUUID();
      return encodeURIComponent(valor);
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // Sonda: colección profunda de IDs en la respuesta
  // ═══════════════════════════════════════════════════════════════

  /** Recolecta TODOS los strings de una estructura arbitraria. */
  function recolectarStrings(valor: unknown, acc: Set<string>): void {
    if (valor == null) return;
    if (typeof valor === 'string') {
      acc.add(valor);
      return;
    }
    if (Array.isArray(valor)) {
      for (const item of valor) recolectarStrings(item, acc);
      return;
    }
    if (typeof valor === 'object') {
      for (const v of Object.values(valor as Record<string, unknown>)) {
        recolectarStrings(v, acc);
      }
    }
  }

  function marcadoresPresentes(
    body: unknown,
    marcadores: string[],
  ): string[] {
    const strings = new Set<string>();
    recolectarStrings(body, strings);
    return marcadores.filter((m) => strings.has(m));
  }

  async function sondear(
    ruta: string,
    query: Record<string, string>,
  ): Promise<{ status: number; body: unknown }> {
    const res = await request(app.getHttpServer())
      .get(ruta)
      .set('Authorization', `Bearer ${tokenA}`)
      .query(query);
    return { status: res.status, body: res.body };
  }

  // ═══════════════════════════════════════════════════════════════
  // Tests
  // ═══════════════════════════════════════════════════════════════

  it('el inventario descubre las rutas GET registradas (sanity de la enumeración)', () => {
    const rutas = descubrirRutasGet();
    // Si esto falla, la introspección de Express se rompió y el suite
    // dejaría de proteger: mejor fallar ruidosamente.
    expect(rutas.length).toBeGreaterThanOrEqual(15);
  });

  it('control de semilla: ADMIN sí puede leer los datos de la víctima B', async () => {
    const res = await request(app.getHttpServer())
      .get('/pagos')
      .set('Authorization', `Bearer ${adminToken}`)
      .query({ residenteId: residenteBId })
      .expect(200);

    expect(res.body.length).toBeGreaterThan(0);
    for (const pago of res.body) {
      expect(pago.residenteId).toBe(residenteBId);
    }
  });

  it('ningún GET devuelve datos personales de terceros para RESIDENTE con queries falsificadas', async () => {
    const rutas = descubrirRutasGet();

    const variantesQuery: Record<string, string>[] = [
      {}, // sin query
      { residenteId: residenteBId },
      { residenteId: randomUUID() },
      { pagoId: pagoIdDeB },
      { cobroId: cobroIdDeB },
      { cuotaId: cobroIdDeB },
      { proyectoId },
    ];

    const personMarkers = [
      residenteBId,
      cobroIdDeB,
      pagoIdDeB,
      casaIdB,
    ].filter(Boolean);
    const tenantConfigMarkers = [tarifaIdDeB, montoIdDeB].filter(Boolean);

    type Sonda = {
      ruta: string;
      queryKey: string;
      status: number;
      fugaPersonas: string[];
      fugaConfig: string[];
    };
    const sondas: Sonda[] = [];

    for (const plantilla of rutas) {
      const rutaConcreta = materializarRuta(plantilla);
      const esRutaConfig = RUTAS_CONFIG_TENANT.has(plantilla);

      for (const query of variantesQuery) {
        const { status, body } = await sondear(rutaConcreta, query);
        sondas.push({
          ruta: plantilla,
          queryKey: JSON.stringify(query),
          status,
          fugaPersonas: marcadoresPresentes(body, personMarkers),
          fugaConfig: esRutaConfig
            ? []
            : marcadoresPresentes(body, tenantConfigMarkers),
        });
      }
    }

    // La enumeración debe haber cubierto una superficie mínima real
    expect(sondas.length).toBeGreaterThanOrEqual(30);

    const fugas = sondas.filter(
      (s) => s.fugaPersonas.length > 0 || s.fugaConfig.length > 0,
    );

    // Resumen útil en el log de CI
    const porEstado = sondas.reduce<Record<string, number>>((acc, s) => {
      acc[s.status] = (acc[s.status] ?? 0) + 1;
      return acc;
    }, {});
    // eslint-disable-next-line no-console
    console.log(
      `[idor-enumeration] ${rutas.length} rutas GET × ${variantesQuery.length} variantes = ${sondas.length} sondas; estados: ${JSON.stringify(porEstado)}`,
    );

    if (fugas.length > 0) {
      const detalle = fugas
        .map(
          (f) =>
            `  ${f.ruta} query=${f.queryKey} → HTTP ${f.status}, marcadores: ${[...f.fugaPersonas, ...f.fugaConfig].join(', ')}`,
        )
        .join('\n');
      throw new Error(
        `FUGA IDOR: endpoints que devuelven datos de terceros a un RESIDENTE:\n${detalle}`,
      );
    }
  });

  it('GET con path param de la víctima (/:id, /residente/:residenteId) nunca sirve datos ajenos', async () => {
    const rutas = descubrirRutasGet();
    const conParams = rutas.filter((r) => r.includes(':'));
    expect(conParams.length).toBeGreaterThan(0);

    const personMarkers = [residenteBId, cobroIdDeB, pagoIdDeB, casaIdB];

    for (const plantilla of conParams) {
      const rutaConcreta = materializarRuta(plantilla);
      const { status, body } = await sondear(rutaConcreta, {});
      const fuga = marcadoresPresentes(body, personMarkers);

      // El único status aceptable frente a un ID ajeno es no-exito (401/403/404/400)
      // o un cuerpo vacío/sin datos de la víctima.
      if (fuga.length > 0) {
        throw new Error(
          `${plantilla} (HTTP ${status}) filtró marcadores de la víctima: ${fuga.join(', ')}`,
        );
      }
    }
  });

  it('GET /tarifas/:id con el id de un cobro ajeno no devuelve 200 con datos', async () => {
    const res = await request(app.getHttpServer())
      .get(`/tarifas/${cobroIdDeB}`)
      .set('Authorization', `Bearer ${tokenA}`)
      .expect((r) => {
        // Puede ser 404/400 según validación; jamás 200 con datos ajenos.
        if (r.status === 200) {
          throw new Error(
            'GET /tarifas/:id devolvió 200 para un id que no es una tarifa',
          );
        }
        expect([400, 404]).toContain(r.status);
      });
    expect(res.body).toBeDefined();
  });
});
