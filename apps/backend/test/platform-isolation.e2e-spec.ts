import {
  ClassSerializerInterceptor,
  INestApplication,
  ValidationPipe,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { Reflector } from '@nestjs/core';
import { JwtService } from '@nestjs/jwt';
import { DataSource } from 'typeorm';
import { hashSync } from 'bcrypt';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { AppModule } from '../src/app.module';

jest.setTimeout(45000);

describe('Platform isolation — E2E', () => {
  let app: INestApplication;
  let jwtService: JwtService;
  let dataSource: DataSource;
  const platformAdminEmail = 'platform-admin-e2e@test.local';

  beforeAll(async () => {
    const moduleFixture = await Test.createTestingModule({
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
    jwtService = app.get(JwtService);
    dataSource = app.get(DataSource);
    await dataSource.query('DELETE FROM platform_admins WHERE email = $1', [
      platformAdminEmail,
    ]);
    await dataSource.query(
      `INSERT INTO platform_admins (id, email, name, password_hash)
       VALUES ($1, $2, $3, $4)`,
      [
        randomUUID(),
        platformAdminEmail,
        'Platform E2E',
        hashSync('PlatformPass123!', 10),
      ],
    );
  });

  afterAll(async () => {
    await dataSource.query('DELETE FROM platform_admins WHERE email = $1', [
      platformAdminEmail,
    ]);
    await app.close();
  });

  it.each(['ADMIN', 'COBRADOR', 'RESIDENTE'])(
    'rechaza un token operativo %s con 403',
    async (rol) => {
      const token = jwtService.sign({
        sub: `${rol.toLowerCase()}-user`,
        rol,
        tenantId: 'tenant-operativo',
      });

      await request(app.getHttpServer())
        .get('/platform/health')
        .set('Authorization', `Bearer ${token}`)
        .expect(403);
    },
  );

  it('rechaza una petición anónima con 401', async () => {
    await request(app.getHttpServer()).get('/platform/health').expect(401);
  });

  it('permite un token sintético válido de plataforma', async () => {
    const token = jwtService.sign({
      sub: 'platform-user',
      scope: 'PLATFORM',
      platformRole: 'SUPERADMIN',
      mfaLevel: 'NONE',
    });

    await request(app.getHttpServer())
      .get('/platform/health')
      .set('Authorization', `Bearer ${token}`)
      .expect(200)
      .expect({ status: 'ok', scope: 'PLATFORM' });
  });

  it('expone el overview global y el inventario paginado de tenants', async () => {
    const token = jwtService.sign({
      sub: 'platform-user',
      scope: 'PLATFORM',
      platformRole: 'SUPERADMIN',
      mfaLevel: 'NONE',
    });

    await request(app.getHttpServer())
      .get('/platform/overview')
      .set('Authorization', `Bearer ${token}`)
      .expect(200)
      .expect((response) => {
        expect(response.body).toEqual(
          expect.objectContaining({
            tenants: expect.objectContaining({
              total: expect.any(Number),
              byStatus: expect.any(Array),
            }),
            activeUsers: expect.any(Number),
            projects: expect.any(Number),
            residents: expect.any(Number),
          }),
        );
      });

    await request(app.getHttpServer())
      .get('/platform/tenants?page=1&limit=1')
      .set('Authorization', `Bearer ${token}`)
      .expect(200)
      .expect((response) => {
        expect(response.body).toEqual(
          expect.objectContaining({
            data: expect.any(Array),
            total: expect.any(Number),
            page: 1,
            limit: 1,
          }),
        );
        expect(response.body.data.length).toBeLessThanOrEqual(1);
      });
  });

  it('valida el estado solicitado para filtrar tenants', async () => {
    const token = jwtService.sign({
      sub: 'platform-user',
      scope: 'PLATFORM',
      platformRole: 'SUPERADMIN',
      mfaLevel: 'NONE',
    });

    await request(app.getHttpServer())
      .get('/platform/tenants?status=UNKNOWN')
      .set('Authorization', `Bearer ${token}`)
      .expect(400);
  });

  it('expone la auditoría durable con filtros y paginación', async () => {
    const token = jwtService.sign({
      sub: 'platform-user',
      scope: 'PLATFORM',
      platformRole: 'SUPERADMIN',
      mfaLevel: 'NONE',
    });

    await request(app.getHttpServer())
      .get('/platform/health')
      .set('Authorization', `Bearer ${token}`)
      .set('x-request-id', 'platform-audit-e2e')
      .expect(200);

    await request(app.getHttpServer())
      .get('/platform/audit?action=PLATFORM_HEALTH_READ&page=1&limit=10')
      .set('Authorization', `Bearer ${token}`)
      .expect(200)
      .expect((response) => {
        expect(response.body.total).toBeGreaterThanOrEqual(1);
        expect(response.body.data).toEqual(
          expect.arrayContaining([
            expect.objectContaining({
              actorId: 'platform-user',
              action: 'PLATFORM_HEALTH_READ',
              resource: 'platform',
              requestId: 'platform-audit-e2e',
              result: 'SUCCESS',
            }),
          ]),
        );
      });
  });

  it('autentica administradores de plataforma y revoca su sesión', async () => {
    const login = await request(app.getHttpServer())
      .post('/platform/auth/login')
      .send({ email: platformAdminEmail, password: 'PlatformPass123!' })
      .expect(201);
    const token = login.body.accessToken as string;

    await request(app.getHttpServer())
      .get('/platform/health')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);

    const sessions = await dataSource.query(
      `SELECT jti FROM platform_sessions
       WHERE admin_id = (SELECT id FROM platform_admins WHERE email = $1)
       ORDER BY created_at DESC LIMIT 1`,
      [platformAdminEmail],
    );
    expect(sessions).toHaveLength(1);

    await dataSource.query(
      'UPDATE platform_sessions SET revoked_at = now() WHERE jti = $1',
      [sessions[0].jti],
    );

    await request(app.getHttpServer())
      .get('/platform/health')
      .set('Authorization', `Bearer ${token}`)
      .expect(401);
  });

  it('gestiona el ciclo de vida completo de un tenant (crear, consultar detalle, suspender y reactivar)', async () => {
    const token = jwtService.sign({
      sub: 'platform-user',
      scope: 'PLATFORM',
      platformRole: 'SUPERADMIN',
      mfaLevel: 'NONE',
    });

    // 1. Crear tenant
    const createRes = await request(app.getHttpServer())
      .post('/platform/tenants')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Tenant E2E Lifecycle' })
      .expect(201);

    expect(createRes.body).toEqual(
      expect.objectContaining({
        id: expect.any(String),
        name: 'Tenant E2E Lifecycle',
        status: 'ACTIVE',
      }),
    );
    const createdTenantId = createRes.body.id as string;

    // 2. Consultar detalle del tenant
    const detailRes = await request(app.getHttpServer())
      .get(`/platform/tenants/${createdTenantId}`)
      .set('Authorization', `Bearer ${token}`)
      .expect(200);

    expect(detailRes.body).toEqual(
      expect.objectContaining({
        tenant: expect.objectContaining({
          id: createdTenantId,
          name: 'Tenant E2E Lifecycle',
          status: 'ACTIVE',
        }),
        projects: expect.any(Array),
        administrators: expect.any(Array),
        summary: expect.objectContaining({
          users: 0,
          residents: 0,
          projects: 0,
        }),
      }),
    );

    // 3. Suspender tenant
    const suspendRes = await request(app.getHttpServer())
      .patch(`/platform/tenants/${createdTenantId}/status`)
      .set('Authorization', `Bearer ${token}`)
      .send({ status: 'SUSPENDED' })
      .expect(200);

    expect(suspendRes.body.status).toBe('SUSPENDED');

    // 4. Reactivar tenant
    const reactivateRes = await request(app.getHttpServer())
      .patch(`/platform/tenants/${createdTenantId}/status`)
      .set('Authorization', `Bearer ${token}`)
      .send({ status: 'ACTIVE' })
      .expect(200);

    expect(reactivateRes.body.status).toBe('ACTIVE');

    // 5. 404 para tenant inexistente
    await request(app.getHttpServer())
      .get('/platform/tenants/00000000-0000-0000-0000-999999999999')
      .set('Authorization', `Bearer ${token}`)
      .expect(404);

    // Limpieza
    await dataSource.query('DELETE FROM tenants WHERE id = $1', [createdTenantId]);
  });

  it('gestiona el flujo completo de invitación y activación segura de administradores de tenant', async () => {
    const platformToken = jwtService.sign({
      sub: 'platform-user',
      scope: 'PLATFORM',
      platformRole: 'SUPERADMIN',
      mfaLevel: 'NONE',
    });

    // 1. Crear tenant temporal
    const tenantRes = await request(app.getHttpServer())
      .post('/platform/tenants')
      .set('Authorization', `Bearer ${platformToken}`)
      .send({ name: 'Tenant Invitations E2E' })
      .expect(201);
    const tenantId = tenantRes.body.id as string;

    const inviteeEmail = 'invited-admin-e2e@test.local';

    // Limpieza preventiva
    await dataSource.query('DELETE FROM usuarios WHERE email = $1', [inviteeEmail]);

    // 2. Intentar invitar con token operativo de ADMIN -> 403 Forbidden
    const operationalAdminToken = jwtService.sign({
      sub: 'op-admin-user',
      rol: 'ADMIN',
      tenantId,
    });
    await request(app.getHttpServer())
      .post(`/platform/tenants/${tenantId}/invitations`)
      .set('Authorization', `Bearer ${operationalAdminToken}`)
      .send({ email: inviteeEmail, name: 'Invited Admin' })
      .expect(403);

    // 3. Emitir invitación válida como SUPERADMIN
    const inviteRes = await request(app.getHttpServer())
      .post(`/platform/tenants/${tenantId}/invitations`)
      .set('Authorization', `Bearer ${platformToken}`)
      .send({ email: inviteeEmail, name: 'Invited Admin' })
      .expect(201);

    expect(inviteRes.body).toEqual(
      expect.objectContaining({
        id: expect.any(String),
        tenantId,
        email: inviteeEmail,
        name: 'Invited Admin',
        status: 'PENDING',
        invitationToken: expect.any(String),
      }),
    );
    const rawInvitationToken = inviteRes.body.invitationToken as string;
    const invitationId = inviteRes.body.id as string;

    // 4. Listar invitaciones del tenant
    const listRes = await request(app.getHttpServer())
      .get(`/platform/tenants/${tenantId}/invitations`)
      .set('Authorization', `Bearer ${platformToken}`)
      .expect(200);

    expect(listRes.body).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          id: invitationId,
          email: inviteeEmail,
          status: 'PENDING',
        }),
      ]),
    );

    // 5. Intentar aceptar con token falso -> 400 Bad Request
    await request(app.getHttpServer())
      .post('/platform/auth/accept-invitation')
      .send({ token: 'token-invalido-o-falso', password: 'PasswordSegura2026!' })
      .expect(400);

    // 6. Aceptar invitación válida y definir contraseña
    const acceptRes = await request(app.getHttpServer())
      .post('/platform/auth/accept-invitation')
      .send({ token: rawInvitationToken, password: 'PasswordSegura2026!' })
      .expect(201);

    expect(acceptRes.body).toEqual(
      expect.objectContaining({
        success: true,
        email: inviteeEmail,
        tenantId,
      }),
    );

    // 7. Verificar que el usuario ahora existe en usuarios como ADMIN activo
    const userRows = await dataSource.query(
      'SELECT id, email, rol, tenant_id, activo FROM usuarios WHERE email = $1',
      [inviteeEmail],
    );
    expect(userRows).toHaveLength(1);
    expect(userRows[0].rol).toBe('ADMIN');
    expect(userRows[0].tenant_id).toBe(tenantId);
    expect(userRows[0].activo).toBe(true);

    // 8. Intentar reutilizar el token quemado -> 400 Bad Request
    await request(app.getHttpServer())
      .post('/platform/auth/accept-invitation')
      .send({ token: rawInvitationToken, password: 'PasswordSegura2026!' })
      .expect(400);

    // 9. Probar revocación de invitaciones
    const secondEmail = 'second-invited@test.local';
    const secondInviteRes = await request(app.getHttpServer())
      .post(`/platform/tenants/${tenantId}/invitations`)
      .set('Authorization', `Bearer ${platformToken}`)
      .send({ email: secondEmail, name: 'Second Admin' })
      .expect(201);
    const secondInviteId = secondInviteRes.body.id as string;
    const secondRawToken = secondInviteRes.body.invitationToken as string;

    await request(app.getHttpServer())
      .post(`/platform/invitations/${secondInviteId}/revoke`)
      .set('Authorization', `Bearer ${platformToken}`)
      .expect(201);

    // Intentar aceptar la invitación revocada -> 400 Bad Request
    await request(app.getHttpServer())
      .post('/platform/auth/accept-invitation')
      .send({ token: secondRawToken, password: 'PasswordSegura2026!' })
      .expect(400);

    // Limpieza
    await dataSource.query('DELETE FROM usuarios WHERE email IN ($1, $2)', [
      inviteeEmail,
      secondEmail,
    ]);
    await dataSource.query('DELETE FROM tenants WHERE id = $1', [tenantId]);
  });
});

