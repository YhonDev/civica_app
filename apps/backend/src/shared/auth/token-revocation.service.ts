import { Injectable, Logger, OnModuleDestroy } from '@nestjs/common';
import Redis from 'ioredis';

/**
 * Persistent token revocation store backed by Redis.
 *
 * When Redis is unavailable (local dev without Redis), falls back to
 * an in-memory Set so the application still works — but with the caveat
 * that revocations are lost on restart. This fallback is logged clearly.
 *
 * TTL is set to 31 days (refresh token max lifetime + 1 day buffer)
 * so expired tokens are automatically cleaned by Redis.
 */
@Injectable()
export class TokenRevocationService implements OnModuleDestroy {
  private readonly logger = new Logger(TokenRevocationService.name);
  private readonly REVOCATION_PREFIX = 'revoked:';
  private readonly TTL_SECONDS = 31 * 24 * 60 * 60; // 31 days

  private redis: Redis | null = null;
  private readonly memoryFallback = new Set<string>();
  private usingFallback = false;

  constructor() {
    this.connect();
  }

  private connect(): void {
    const host = process.env.REDIS_HOST || '127.0.0.1';
    const port = parseInt(process.env.REDIS_PORT || '6379', 10);
    const password = process.env.REDIS_PASSWORD;
    const db = parseInt(process.env.REDIS_DB || '0', 10);

    try {
      this.redis = new Redis({
        host,
        port,
        password: password || undefined,
        db,
        maxRetriesPerRequest: 3,
        retryStrategy(times: number) {
          if (times > 3) return null; // Stop retrying after 3 attempts
          return Math.min(times * 200, 2000);
        },
        lazyConnect: true,
        connectTimeout: 3000,
      });

      this.redis.on('connect', () => {
        this.usingFallback = false;
        this.logger.log('✅ Redis conectado para revocación de tokens');
      });

      this.redis.on('error', (err) => {
        if (!this.usingFallback) {
          this.usingFallback = true;
          this.logger.warn(
            `⚠️ Redis no disponible, usando fallback en memoria para revocación de tokens: ${err.message}`,
          );
        }
      });

      // Non-blocking connect
      this.redis.connect().catch(() => {
        this.usingFallback = true;
        this.logger.warn(
          '⚠️ Redis no disponible al inicio, usando fallback en memoria para revocación de tokens',
        );
      });
    } catch {
      this.usingFallback = true;
      this.logger.warn(
        '⚠️ No se pudo crear conexión Redis, usando fallback en memoria',
      );
    }
  }

  /**
   * Revoca un refresh token. Idempotente.
   * Stores with TTL so Redis auto-cleans expired entries.
   */
  async revoke(token: string): Promise<void> {
    if (this.redis && !this.usingFallback) {
      try {
        await this.redis.setex(
          `${this.REVOCATION_PREFIX}${token}`,
          this.TTL_SECONDS,
          '1',
        );
        return; // Redis succeeded — no memory fallback needed
      } catch (err) {
        this.logger.warn(`Redis revoke failed, memory fallback active: ${err}`);
        this.memoryFallback.add(token);
      }
    } else {
      this.memoryFallback.add(token);
    }
  }

  /**
   * Checks if a token has been revoked.
   * Checks memory first (fast path), then Redis.
   */
  async isRevoked(token: string): Promise<boolean> {
    // Fast path: memory check
    if (this.memoryFallback.has(token)) {
      return true;
    }

    // Slow path: Redis check
    if (this.redis && !this.usingFallback) {
      try {
        const result = await this.redis.exists(
          `${this.REVOCATION_PREFIX}${token}`,
        );
        if (result === 1) {
          // Also add to memory cache for faster future lookups
          this.memoryFallback.add(token);
          return true;
        }
        return false;
      } catch {
        return this.memoryFallback.has(token);
      }
    }

    return false;
  }



  /**
   * Returns the current Redis connection status for health checks.
   */
  getRedisStatus(): { connected: boolean; usingFallback: boolean; host: string; port: number } {
    return {
      connected: this.redis !== null && !this.usingFallback,
      usingFallback: this.usingFallback,
      host: process.env.REDIS_HOST || '127.0.0.1',
      port: parseInt(process.env.REDIS_PORT || '6379', 10),
    };
  }

  async onModuleDestroy(): Promise<void> {
    if (this.redis) {
      await this.redis.quit().catch(() => {});
    }
  }
}
