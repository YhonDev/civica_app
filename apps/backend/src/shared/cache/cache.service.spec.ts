import { Test, TestingModule } from '@nestjs/testing';
import { CacheService } from './cache.service';

describe('CacheService', () => {
  let service: CacheService;

  beforeEach(async () => {
    delete process.env.REDIS_ENABLED;
    delete process.env.REDIS_URL;

    const module: TestingModule = await Test.createTestingModule({
      providers: [CacheService],
    }).compile();

    service = module.get<CacheService>(CacheService);
  });

  afterEach(() => {
    service.onModuleDestroy();
  });

  it('should return null for non-existing key', async () => {
    const value = await service.get('non-existent');
    expect(value).toBeNull();
  });

  it('should store and retrieve value from cache', async () => {
    await service.set('test-key', { foo: 'bar' }, 60);
    const value = await service.get<{ foo: string }>('test-key');
    expect(value).toEqual({ foo: 'bar' });
  });

  it('should expire keys after TTL', async () => {
    // Set with 0 TTL (or expired in the past)
    await service.set('expired-key', 'data', -1);
    const value = await service.get('expired-key');
    expect(value).toBeNull();
  });

  it('should wrap async calls and cache results', async () => {
    const factory = jest.fn().mockResolvedValue({ id: 1, name: 'Tarifa A' });

    // First call: cache miss, calls factory
    const res1 = await service.wrap('wrap-key', 60, factory);
    expect(res1).toEqual({ id: 1, name: 'Tarifa A' });
    expect(factory).toHaveBeenCalledTimes(1);

    // Second call: cache hit, factory not called again
    const res2 = await service.wrap('wrap-key', 60, factory);
    expect(res2).toEqual({ id: 1, name: 'Tarifa A' });
    expect(factory).toHaveBeenCalledTimes(1);
  });

  it('should delete a specific key with del()', async () => {
    await service.set('to-delete', 'value', 60);
    await service.del('to-delete');
    const value = await service.get('to-delete');
    expect(value).toBeNull();
  });

  it('should delete keys by prefix with delByPrefix()', async () => {
    await service.set('tarifas:tenant1:1', 'val1', 60);
    await service.set('tarifas:tenant1:2', 'val2', 60);
    await service.set('montos:tenant1:1', 'val3', 60);

    await service.delByPrefix('tarifas:tenant1');

    expect(await service.get('tarifas:tenant1:1')).toBeNull();
    expect(await service.get('tarifas:tenant1:2')).toBeNull();
    expect(await service.get('montos:tenant1:1')).toBe('val3');
  });

  it('should clear all keys with clear()', async () => {
    await service.set('k1', 'v1', 60);
    await service.set('k2', 'v2', 60);

    await service.clear();

    expect(await service.get('k1')).toBeNull();
    expect(await service.get('k2')).toBeNull();
  });
});
