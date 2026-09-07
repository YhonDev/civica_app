import { ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { RolesGuard } from './roles.guard';
import { RolUsuario } from '../../../iam/domain/usuario.entity';

describe('RolesGuard', () => {
  let guard: RolesGuard;
  const reflector = { getAllAndOverride: jest.fn() };

  beforeEach(() => {
    jest.clearAllMocks();
    guard = new RolesGuard(reflector as unknown as Reflector);
  });

  function crearContexto(user: { rol: RolUsuario } | null): ExecutionContext {
    return {
      switchToHttp: () => ({
        getRequest: () => ({ user }),
      }),
      getHandler: () => 'handler',
      getClass: () => 'clase',
    } as unknown as ExecutionContext;
  }

  it('permite el acceso si el endpoint no declara roles', () => {
    reflector.getAllAndOverride.mockReturnValue(undefined);

    expect(guard.canActivate(crearContexto(null))).toBe(true);
  });

  it('permite el acceso si el usuario tiene uno de los roles requeridos', () => {
    reflector.getAllAndOverride.mockReturnValue([
      RolUsuario.ADMIN,
      RolUsuario.COBRADOR,
    ]);

    const resultado = guard.canActivate(
      crearContexto({ rol: RolUsuario.COBRADOR }),
    );

    expect(resultado).toBe(true);
    expect(reflector.getAllAndOverride).toHaveBeenCalledWith('roles', [
      'handler',
      'clase',
    ]);
  });

  it('deniega el acceso si el rol del usuario no está en los requeridos', () => {
    reflector.getAllAndOverride.mockReturnValue([RolUsuario.ADMIN]);

    const resultado = guard.canActivate(
      crearContexto({ rol: RolUsuario.RESIDENTE }),
    );

    expect(resultado).toBe(false);
  });

  it('deniega el acceso anónimo (sin usuario) cuando se requieren roles', () => {
    reflector.getAllAndOverride.mockReturnValue([RolUsuario.ADMIN]);

    expect(guard.canActivate(crearContexto(null))).toBe(false);
  });
});
