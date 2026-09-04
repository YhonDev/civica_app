import { Injectable, Logger, OnModuleDestroy } from '@nestjs/common';
import Redis from 'ioredis';
import { createHash } from 'node:crypto';

export type RedisStatus = 'disabled' | 'connected' | 'unavailable';

export interface RedisHealthStatus {
  status: RedisStatus;
  connected: boolean;
  usingFallback: boolean;
}

/**
 * Persistent token revocation store backed by Redis when explicitly enabled.
 *
 * Redis is optional for local development. When it is disabled or unavailable,
 * revocations are kept in memory; they are lost when the process restarts.
 */
@Injectable()
export class TokenRevocationService implements OnModuleDestroy {
  private readonly logger = new Logger(TokenRevocationService.name);
  private readonly REVOCATION_PREFIX = 'revoked:';
  private readonly TTL_SECONDS = 31 * 24 * 60 * 60;
  private readonly redisEnabled = this.isRedisEnabled();

  private redis: Redis | null = null;
  private readonly memoryFallback = new Set<string>();
  private usingFallback = false;
  private redisStatus: RedisStatus = this.redisEnabled
    ? 'unavailable'
    : 'disabled';

  constructor() {
    if (this.redisEnabled) {
      this.connect();
    } else {
      this.usingFallback = true;
      this.logger.log(
        'Redis deshabilitado; usando fallback en memoria para desarrollo',
      );
    }
  }

  private isRedisEnabled(): boolean {
    return process.env.REDIS_ENABLED?.toLowerCase() === 'true';
  }

  private connect(): void {
    const redisUrl = process.env.REDIS_URL;
    if (!redisUrl) {
      this.usingFallback = true;
      this.redisStatus = 'unavailable';
      this.logger.warn(
        'REDIS_ENABLED=true pero REDIS_URL no está configurada; usando fallback en memoria',
      );
      return;
    }

    try {
      this.redis = new Redis(redisUrl, {
        maxRetriesPerRequest: 3,
        retryStrategy(times: number) {
          if (times > 3) return null;
          return Math.min(times * 200, 2000);
        },
        lazyConnect: true,
        connectTimeout: 3000,
      });

      this.redis.on('connect', () => {
        this.usingFallback = false;
        this.redisStatus = 'connected';
        this.logger.log('Redis conectado para revocación de tokens');
      });

      this.redis.on('error', (err) => {
        this.redisStatus = 'unavailable';
        this.usingFallback = true;
        this.logger.warn(
          `Redis no disponible, usando fallback en memoria para revocación de tokens: ${err.message}`,
        );
      });

      void this.redis.connect().catch(() => {
        this.redisStatus = 'unavailable';
        this.usingFallback = true;
        this.logger.warn(
          'Redis no disponible al inicio, usando fallback en memoria para revocación de tokens',
        );
      });
    } catch {
      this.redis = null;
      this.redisStatus = 'unavailable';
      this.usingFallback = true;
      this.logger.warn(
        'No se pudo crear conexión Redis, usando fallback en memoria',
      );
    }
  }

  private key(token: string): string {
    return `${this.REVOCATION_PREFIX}${createHash('sha256').update(token).digest('hex')}`;
  }

  /** Revoca un refresh token. Idempotente. */
  async revoke(token: string): Promise<void> {
    const key = this.key(token);
    if (this.redis && !this.usingFallback) {
      try {
        await this.redis.setex(key, this.TTL_SECONDS, '1');
        return;
      } catch (err) {
        this.redisStatus = 'unavailable';
        this.usingFallback = true;
        this.logger.warn(`Redis revoke failed, memory fallback active: ${err}`);
      }
    }
    this.memoryFallback.add(key);
  }

  /** Checks whether a token has been revoked. */
  async isRevoked(token: string): Promise<boolean> {
    const key = this.key(token);
    if (this.memoryFallback.has(key)) {
      return true;
    }

    if (this.redis && !this.usingFallback) {
      try {
        const result = await this.redis.exists(key);
        if (result === 1) {
          this.memoryFallback.add(key);
          return true;
        }
        return false;
      } catch {
        this.redisStatus = 'unavailable';
        this.usingFallback = true;
        return this.memoryFallback.has(key);
      }
    }

    return false;
  }

  /** Returns Redis state without exposing connection details. */
  getRedisStatus(): RedisHealthStatus {
    return {
      status: this.redisStatus,
      connected: this.redisStatus === 'connected',
      usingFallback: this.usingFallback,
    };
  }

  async onModuleDestroy(): Promise<void> {
    if (this.redis) {
      await this.redis.quit().catch(() => {});
    }
  }
}
