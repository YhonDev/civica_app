import { MetricsService } from './metrics.service';

describe('MetricsService', () => {
  it('calculates latency percentiles and error totals', () => {
    const service = new MetricsService();

    [10, 20, 30, 40, 100].forEach((durationMs) => {
      service.record({ route: '/health', statusCode: 200, durationMs });
    });
    service.record({
      route: '/auth/login',
      statusCode: 401,
      durationMs: 50,
    });
    service.record({
      route: '/pagos',
      statusCode: 500,
      durationMs: 200,
    });

    expect(service.snapshot()).toEqual({
      requests: 7,
      errors: { total: 2, client: 1, server: 1 },
      latencyMs: { p50: 40, p95: 200, p99: 200 },
      slowestRoutes: [
        { route: '/pagos', requests: 1, p95: 200 },
        { route: '/health', requests: 5, p95: 100 },
        { route: '/auth/login', requests: 1, p95: 50 },
      ],
    });
  });

  it('returns zero values before receiving requests', () => {
    expect(new MetricsService().snapshot()).toEqual({
      requests: 0,
      errors: { total: 0, client: 0, server: 0 },
      latencyMs: { p50: 0, p95: 0, p99: 0 },
      slowestRoutes: [],
    });
  });
});
