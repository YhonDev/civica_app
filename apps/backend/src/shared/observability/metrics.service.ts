import { Injectable } from '@nestjs/common';

export interface RequestMetric {
  route: string;
  statusCode: number;
  durationMs: number;
}

export interface MetricsSnapshot {
  requests: number;
  errors: {
    total: number;
    client: number;
    server: number;
  };
  latencyMs: {
    p50: number;
    p95: number;
    p99: number;
  };
  slowestRoutes: Array<{
    route: string;
    requests: number;
    p95: number;
  }>;
}

interface RouteMetrics {
  durations: number[];
}

@Injectable()
export class MetricsService {
  private static readonly maxSamplesPerRoute = 1000;
  private readonly routes = new Map<string, RouteMetrics>();
  private requests = 0;
  private clientErrors = 0;
  private serverErrors = 0;

  record(metric: RequestMetric): void {
    this.requests += 1;
    if (metric.statusCode >= 400 && metric.statusCode < 500) {
      this.clientErrors += 1;
    } else if (metric.statusCode >= 500) {
      this.serverErrors += 1;
    }

    const route = this.routes.get(metric.route) ?? { durations: [] };
    route.durations.push(metric.durationMs);
    if (route.durations.length > MetricsService.maxSamplesPerRoute) {
      route.durations.shift();
    }
    this.routes.set(metric.route, route);
  }

  snapshot(): MetricsSnapshot {
    const allDurations = [...this.routes.values()].flatMap(
      (route) => route.durations,
    );
    const slowestRoutes = [...this.routes.entries()]
      .map(([route, data]) => ({
        route,
        requests: data.durations.length,
        p95: this.percentile(data.durations, 0.95),
      }))
      .sort((a, b) => b.p95 - a.p95)
      .slice(0, 10);

    return {
      requests: this.requests,
      errors: {
        total: this.clientErrors + this.serverErrors,
        client: this.clientErrors,
        server: this.serverErrors,
      },
      latencyMs: {
        p50: this.percentile(allDurations, 0.5),
        p95: this.percentile(allDurations, 0.95),
        p99: this.percentile(allDurations, 0.99),
      },
      slowestRoutes,
    };
  }

  private percentile(values: number[], quantile: number): number {
    if (values.length === 0) return 0;
    const sorted = [...values].sort((a, b) => a - b);
    const index = Math.min(
      sorted.length - 1,
      Math.ceil(quantile * sorted.length) - 1,
    );
    return sorted[index];
  }
}
