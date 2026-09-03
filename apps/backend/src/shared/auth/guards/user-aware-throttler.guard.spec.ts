import { UserAwareThrottlerGuard } from './user-aware-throttler.guard';

describe('UserAwareThrottlerGuard', () => {
  let guard: UserAwareThrottlerGuard;

  beforeEach(() => {
    // Instantiate guard with minimal mocks for ThrottlerGuard dependencies
    guard = new UserAwareThrottlerGuard(
      {} as any, // options
      {} as any, // storageService
      {} as any, // reflector
    );
  });

  describe('getTracker', () => {
    it('should track by user.id when authenticated', async () => {
      const req: any = {
        user: { id: 'usr-123', email: 'test@mail.com' },
        ip: '192.168.1.50',
      };

      const tracker = await (guard as any).getTracker(req);
      expect(tracker).toBe('user:usr-123');
    });

    it('should track by user.sub when token uses sub claim', async () => {
      const req: any = {
        user: { sub: 'usr-456' },
        ip: '192.168.1.50',
      };

      const tracker = await (guard as any).getTracker(req);
      expect(tracker).toBe('user:usr-456');
    });

    it('should track by first forwarded IP when behind proxy without user', async () => {
      const req: any = {
        ips: ['203.0.113.195', '70.41.3.18'],
        ip: '10.0.0.1',
      };

      const tracker = await (guard as any).getTracker(req);
      expect(tracker).toBe('ip:203.0.113.195');
    });

    it('should track by req.ip when not authenticated and no forwarded ips', async () => {
      const req: any = {
        ip: '198.51.100.22',
      };

      const tracker = await (guard as any).getTracker(req);
      expect(tracker).toBe('ip:198.51.100.22');
    });

    it('should fallback to unknown if no IP is provided', async () => {
      const req: any = {};

      const tracker = await (guard as any).getTracker(req);
      expect(tracker).toBe('ip:unknown');
    });
  });
});
