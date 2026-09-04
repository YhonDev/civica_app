import { HealthController } from './health.controller';
import { TokenRevocationService } from '../auth/token-revocation.service';
import { HttpException } from '@nestjs/common';

describe('HealthController', () => {
  const originalEnabled = process.env.REDIS_ENABLED;

  afterEach(() => {
    if (originalEnabled === undefined) delete process.env.REDIS_ENABLED;
    else process.env.REDIS_ENABLED = originalEnabled;
  });

  it('reports healthy when the database is initialized and Redis is disabled', () => {
    process.env.REDIS_ENABLED = 'false';
    const tokenRevocation = new TokenRevocationService();
    const controller = new HealthController(
      { isInitialized: true } as never,
      tokenRevocation,
    );

    expect(controller.check()).resolves.toMatchObject({
      status: 'ok',
      database: 'connected',
      redis: 'disabled',
    });
  });

  it('reports unhealthy with 503 when the database is not initialized', () => {
    process.env.REDIS_ENABLED = 'false';
    const tokenRevocation = new TokenRevocationService();
    const controller = new HealthController(
      { isInitialized: false } as never,
      tokenRevocation,
    );

    expect(controller.check()).rejects.toThrow(HttpException);
  });

  it('exposes dependency diagnostics without connection details', () => {
    process.env.REDIS_ENABLED = 'false';
    const tokenRevocation = new TokenRevocationService();
    const controller = new HealthController(
      { isInitialized: true } as never,
      tokenRevocation,
    );

    expect(controller.dependencies()).toMatchObject({
      status: 'ok',
      dependencies: {
        database: 'connected',
        redis: 'disabled',
        fallback: 'memory',
      },
    });
    expect(controller.dependencies()).not.toHaveProperty('host');
    expect(controller.dependencies()).not.toHaveProperty('port');
  });
});
