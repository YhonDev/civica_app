import { createParamDecorator, ExecutionContext } from '@nestjs/common';

/**
 * Decorador para inyectar el tenantId del usuario autenticado.
 * Uso: @CurrentTenant() tenantId: string
 */
export const CurrentTenant = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): string | null => {
    const request = ctx.switchToHttp().getRequest();
    return request.user?.tenantId ?? null;
  },
);
