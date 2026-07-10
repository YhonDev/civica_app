import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
  SetMetadata,
  Logger,
} from '@nestjs/common';
import { Observable, tap } from 'rxjs';
import { Reflector } from '@nestjs/core';
import { ActividadRepository } from '../../../notifications/domain/actividad.repository';
import { Actividad } from '../../../notifications/domain/actividad.entity';

export const REGISTRAR_ACTIVIDAD_KEY = 'registrar_actividad';

export interface RegistrarActividadOptions {
  tipo: string;
  descripcionFn: (result: any) => string;
}

/**
 * Decorator to automatically log an Actividad record after a
 * successful use case execution.
 *
 * Usage:
 * @RegistrarActividad({ tipo: 'PAGO', descripcionFn: (r) => `${r.usuarioNombre} registró un pago` })
 */
export const RegistrarActividad = (
  options: RegistrarActividadOptions,
) => SetMetadata(REGISTRAR_ACTIVIDAD_KEY, options);

@Injectable()
export class ActividadInterceptor implements NestInterceptor {
  private readonly logger = new Logger(ActividadInterceptor.name);

  constructor(
    private readonly reflector: Reflector,
    private readonly actividadRepo: ActividadRepository,
  ) {}

  intercept(
    context: ExecutionContext,
    next: CallHandler,
  ): Observable<any> {
    const options = this.reflector.get<RegistrarActividadOptions>(
      REGISTRAR_ACTIVIDAD_KEY,
      context.getHandler(),
    );

    if (!options) {
      return next.handle();
    }

    const request = context.switchToHttp().getRequest();

    return next.handle().pipe(
      tap((result) => {
        const user = request.user;
        if (!user) return;

        try {
          const descripcion = options.descripcionFn(result);
          const actividad = Actividad.crear(
            user.tenantId,
            options.tipo,
            descripcion,
            user.nombre ?? 'Sistema',
            user.id,
          );

          // Fire-and-forget: persist without blocking the response
          this.actividadRepo.save(actividad).catch((err) =>
            this.logger.error(`Error registrando actividad: ${err.message}`),
          );
        } catch (err) {
          this.logger.error(
            `Error registrando actividad: ${err instanceof Error ? err.message : err}`,
          );
        }
      }),
    );
  }
}
