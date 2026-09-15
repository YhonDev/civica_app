import {
  ExecutionContext,
  ForbiddenException,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Reflector } from '@nestjs/core';
import { PlatformAdminGuard } from './platform-admin.guard';
import { AccessScope } from '../domain/access-scope.enum';
import { DataSource } from 'typeorm';

describe('PlatformAdminGuard', () => {
  const jwtService = new JwtService({ secret: 'test-platform-secret' });
  const reflector = {
    getAllAndOverride: jest.fn().mockReturnValue(AccessScope.PLATFORM),
  } as unknown as Reflector;
  const dataSource = {
    query: jest.fn().mockResolvedValue([]),
  } as unknown as DataSource;
  const guard = new PlatformAdminGuard(jwtService, reflector, dataSource);

  const contextFor = (authorization?: string): ExecutionContext =>
    ({
      getHandler: () => undefined,
      getClass: () => undefined,
      switchToHttp: () => ({
        getRequest: () => ({
          header: () => authorization,
        }),
      }),
    }) as unknown as ExecutionContext;

  it('permite un principal de plataforma válido', async () => {
    const token = jwtService.sign({
      sub: 'platform-user',
      scope: AccessScope.PLATFORM,
      platformRole: 'SUPERADMIN',
      mfaLevel: 'PASSKEY',
    });

    await expect(
      guard.canActivate(contextFor(`Bearer ${token}`)),
    ).resolves.toBe(true);
  });

  it.each(['ADMIN', 'COBRADOR', 'RESIDENTE'])(
    'bloquea con 403 el rol operativo %s',
    async (rol) => {
      const token = jwtService.sign({
        sub: 'operational-user',
        rol,
        tenantId: 'tenant-1',
      });

      await expect(
        guard.canActivate(contextFor(`Bearer ${token}`)),
      ).rejects.toThrow(ForbiddenException);
    },
  );

  it('bloquea con 401 la ausencia de credenciales', async () => {
    await expect(guard.canActivate(contextFor())).rejects.toThrow(
      UnauthorizedException,
    );
  });

  it('bloquea con 401 un token inválido', async () => {
    await expect(
      guard.canActivate(contextFor('Bearer invalid')),
    ).rejects.toThrow(UnauthorizedException);
  });
});
