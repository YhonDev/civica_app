import { Injectable, ExecutionContext } from '@nestjs/common';
import { Request } from 'express';

@Injectable()
export class TenantService {
  /**
   * Extrae el tenantId del usuario autenticado en la request.
   */
  getTenantIdFromRequest(request: Request): string | null {
    const user = (request as any).user;
    return user?.tenantId ?? null;
  }

  /**
   * Extrae el tenantId del contexto de ejecución de NestJS.
   */
  getTenantIdFromExecutionContext(context: ExecutionContext): string | null {
    const request = context.switchToHttp().getRequest<Request>();
    return this.getTenantIdFromRequest(request);
  }
}
