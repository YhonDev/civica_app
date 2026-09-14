import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';
import { databaseConfig } from './shared/common/database.config';
import { AuthModule } from './shared/auth/auth.module';
import { TenantModule } from './shared/tenant/tenant.module';
import { CommunityModule } from './community/community.module';
import { IamModule } from './iam/iam.module';
import { LedgerModule } from './ledger/ledger.module';
import { NotificationsModule } from './notifications/notifications.module';
import { HealthController } from './shared/health/health.controller';

import { UserAwareThrottlerGuard } from './shared/auth/guards/user-aware-throttler.guard';
import { ObservabilityModule } from './shared/observability/observability.module';
import { RequestIdMiddleware } from './shared/observability/request-id.middleware';
import { CacheModule } from './shared/cache/cache.module';
import { validateEnv } from './shared/infrastructure/env/env.validation';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, validate: validateEnv }),
    TypeOrmModule.forRoot(databaseConfig()),

    // Rate limiting global: 30 requests / 60 segundos por defecto
    ThrottlerModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => [
        {
          ttl: 60000,
          limit: config.get<number>('THROTTLE_LIMIT', 30),
        },
      ],
    }),

    CacheModule,
    AuthModule,
    TenantModule,
    CommunityModule,
    IamModule,
    LedgerModule,
    NotificationsModule,
    ObservabilityModule,
  ],
  controllers: [HealthController],
  providers: [
    {
      provide: APP_GUARD,
      useClass: UserAwareThrottlerGuard,
    },
  ],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(RequestIdMiddleware).forRoutes('*');
  }
}
