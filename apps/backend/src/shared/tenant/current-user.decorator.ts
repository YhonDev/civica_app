import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { Usuario } from '../../iam/domain/usuario.entity';

/**
 * Decorador para inyectar el usuario autenticado en los controladores.
 * Uso: @CurrentUser() usuario: Usuario
 */
export const CurrentUser = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): Usuario => {
    const request = ctx.switchToHttp().getRequest();
    return request.user;
  },
);
