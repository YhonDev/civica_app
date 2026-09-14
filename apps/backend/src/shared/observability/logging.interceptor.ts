import {
  CallHandler,
  ExecutionContext,
  Injectable,
  Logger,
  NestInterceptor,
} from '@nestjs/common';
import { Request, Response } from 'express';
import { Observable, tap } from 'rxjs';
import { MetricsService } from './metrics.service';

@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger('HTTP');

  constructor(private readonly metrics: MetricsService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const request = context.switchToHttp().getRequest<Request>();
    const response = context.switchToHttp().getResponse<Response>();
    const startedAt = process.hrtime.bigint();
    const requestId = request.header('x-request-id') ?? 'unknown';

    return next.handle().pipe(
      tap({
        next: () => this.record(request, response, startedAt, requestId),
        error: (error: unknown) =>
          this.record(
            request,
            response,
            startedAt,
            requestId,
            error instanceof Error && 'getStatus' in error
              ? (error as { getStatus: () => number }).getStatus()
              : 500,
          ),
      }),
    );
  }

  private record(
    request: Request,
    response: Response,
    startedAt: bigint,
    requestId: string,
    errorStatus?: number,
  ): void {
    const durationMs = Number(process.hrtime.bigint() - startedAt) / 1e6;
    const route = request.route?.path ?? 'unmatched';
    const statusCode = errorStatus ?? response.statusCode;
    this.metrics.record({ route, statusCode, durationMs });
    this.logger.log(
      JSON.stringify({
        requestId,
        method: request.method,
        route,
        statusCode,
        durationMs: Math.round(durationMs * 100) / 100,
        tenantId: this.safeRequestIdentifier(request, 'tenantId'),
        userId: this.safeRequestIdentifier(request, 'id'),
      }),
    );
  }

  private safeIdentifier(value: unknown): string | undefined {
    return typeof value === 'string' && value.length > 0 ? value : undefined;
  }

  private safeRequestIdentifier(
    request: Request,
    key: 'tenantId' | 'id',
  ): string | undefined {
    const user = request.user;
    if (!user || typeof user !== 'object') return undefined;
    return this.safeIdentifier(Reflect.get(user, key));
  }
}
