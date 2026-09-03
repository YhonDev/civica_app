import { Injectable } from '@nestjs/common';
import { ThrottlerGuard } from '@nestjs/throttler';

/**
 * Throttler guard that tracks requests by authenticated user ID (when present),
 * falling back to client IP for unauthenticated requests.
 *
 * This prevents the "shared Wi-Fi / CGNAT" problem in residential complexes
 * where multiple neighbors sharing a public IP could exhaust each other's rate limits.
 */
@Injectable()
export class UserAwareThrottlerGuard extends ThrottlerGuard {
  protected async getTracker(req: Record<string, any>): Promise<string> {
    const user = req.user;
    if (user?.id || user?.sub) {
      return `user:${user.id || user.sub}`;
    }

    const clientIp =
      req.ips?.length > 0 ? req.ips[0] : req.ip || req.connection?.remoteAddress;

    return `ip:${clientIp || 'unknown'}`;
  }
}
