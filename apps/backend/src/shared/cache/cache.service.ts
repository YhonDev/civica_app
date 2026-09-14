import { Injectable, Logger, OnModuleDestroy } from '@nestjs/common';
import Redis from 'ioredis';

interface CacheEntry<T> {
  value: T;
  expiresAt: number;
}

@Injectable()
export class CacheService implements OnModuleDestroy {
  private readonly logger = new Logger(CacheService.name);
  private readonly memoryCache = new Map<string, CacheEntry<any>>();
  private readonly redisEnabled = this.isRedisEnabled();
  private redis: Redis | null = null;
  private cleanupInterval: NodeJS.Timeout | null = null;

  constructor() {
    if (this.redisEnabled) {
      this.initRedis();
    } else {
      this.initMemoryCleanup();
    }
  }

  private isRedisEnabled(): boolean {
    return process.env.REDIS_ENABLED?.toLowerCase() === 'true';
  }

  private initRedis(): void {
    const redisUrl = process.env.REDIS_URL;
    if (!redisUrl) {
      this.logger.warn(
        'REDIS_ENABLED=true pero REDIS_URL no está configurada; usando fallback en memoria',
      );
      this.initMemoryCleanup();
      return;
    }

    try {
      this.redis = new Redis(redisUrl, {
        maxRetriesPerRequest: 1,
        connectTimeout: 2000,
        lazyConnect: true,
      });

      this.redis.connect().catch((err) => {
        this.logger.warn(
          `Error conectando a Redis para cache: ${err.message}. Usando memoria.`,
        );
        this.redis = null;
        this.initMemoryCleanup();
      });
    } catch (err: any) {
      this.logger.warn(
        `Fallo al inicializar cliente Redis: ${err.message}. Usando memoria.`,
      );
      this.initMemoryCleanup();
    }
  }

  private initMemoryCleanup(): void {
    if (this.cleanupInterval) return;
    // Limpieza cada 60 segundos de entradas expiradas en memoria
    this.cleanupInterval = setInterval(() => {
      const now = Date.now();
      for (const [key, entry] of this.memoryCache.entries()) {
        if (entry.expiresAt <= now) {
          this.memoryCache.delete(key);
        }
      }
    }, 60000);
    // Unref para no bloquear el cierre del proceso
    if (this.cleanupInterval.unref) {
      this.cleanupInterval.unref();
    }
  }

  async get<T>(key: string): Promise<T | null> {
    try {
      if (this.redis) {
        const raw = await this.redis.get(key);
        if (!raw) return null;
        return JSON.parse(raw) as T;
      }
    } catch (err: any) {
      this.logger.warn(`Error leyendo de Redis [${key}]: ${err.message}`);
    }

    const entry = this.memoryCache.get(key);
    if (!entry) return null;

    if (entry.expiresAt <= Date.now()) {
      this.memoryCache.delete(key);
      return null;
    }

    return entry.value as T;
  }

  async set<T>(key: string, value: T, ttlSeconds: number = 120): Promise<void> {
    try {
      if (this.redis) {
        await this.redis.set(key, JSON.stringify(value), 'EX', ttlSeconds);
        return;
      }
    } catch (err: any) {
      this.logger.warn(`Error escribiendo en Redis [${key}]: ${err.message}`);
    }

    this.memoryCache.set(key, {
      value,
      expiresAt: Date.now() + ttlSeconds * 1000,
    });
  }

  async del(key: string): Promise<void> {
    try {
      if (this.redis) {
        await this.redis.del(key);
      }
    } catch (err: any) {
      this.logger.warn(`Error borrando en Redis [${key}]: ${err.message}`);
    }
    this.memoryCache.delete(key);
  }

  async delByPrefix(prefix: string): Promise<void> {
    try {
      if (this.redis) {
        const keys = await this.redis.keys(`${prefix}*`);
        if (keys.length > 0) {
          await this.redis.del(...keys);
        }
      }
    } catch (err: any) {
      this.logger.warn(
        `Error borrando por prefijo en Redis [${prefix}]: ${err.message}`,
      );
    }

    for (const key of this.memoryCache.keys()) {
      if (key.startsWith(prefix)) {
        this.memoryCache.delete(key);
      }
    }
  }

  async wrap<T>(
    key: string,
    ttlSeconds: number,
    fn: () => Promise<T>,
  ): Promise<T> {
    const cached = await this.get<T>(key);
    if (cached !== null && cached !== undefined) {
      return cached;
    }

    const fresh = await fn();
    await this.set(key, fresh, ttlSeconds);
    return fresh;
  }

  async clear(): Promise<void> {
    try {
      if (this.redis) {
        await this.redis.flushdb();
      }
    } catch (err: any) {
      this.logger.warn(`Error limpiando Redis: ${err.message}`);
    }
    this.memoryCache.clear();
  }

  onModuleDestroy(): void {
    if (this.cleanupInterval) {
      clearInterval(this.cleanupInterval);
      this.cleanupInterval = null;
    }
    if (this.redis) {
      this.redis.disconnect();
      this.redis = null;
    }
    this.memoryCache.clear();
  }
}
