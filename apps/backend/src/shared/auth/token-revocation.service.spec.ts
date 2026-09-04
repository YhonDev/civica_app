import { TokenRevocationService } from './token-revocation.service';

describe('TokenRevocationService', () => {
  const originalEnabled = process.env.REDIS_ENABLED;
  const originalUrl = process.env.REDIS_URL;

  afterEach(() => {
    if (originalEnabled === undefined) delete process.env.REDIS_ENABLED;
    else process.env.REDIS_ENABLED = originalEnabled;
    if (originalUrl === undefined) delete process.env.REDIS_URL;
    else process.env.REDIS_URL = originalUrl;
  });

  it('does not connect to Redis when disabled and uses memory fallback', async () => {
    process.env.REDIS_ENABLED = 'false';
    delete process.env.REDIS_URL;

    const service = new TokenRevocationService();

    expect(service.getRedisStatus()).toEqual({
      status: 'disabled',
      connected: false,
      usingFallback: true,
    });
    await service.revoke('token');
    await expect(service.isRevoked('token')).resolves.toBe(true);
    await service.onModuleDestroy();
  });

  it('reports unavailable when enabled without a Redis URL', async () => {
    process.env.REDIS_ENABLED = 'true';
    delete process.env.REDIS_URL;

    const service = new TokenRevocationService();

    expect(service.getRedisStatus()).toEqual({
      status: 'unavailable',
      connected: false,
      usingFallback: true,
    });
    await service.onModuleDestroy();
  });
});
