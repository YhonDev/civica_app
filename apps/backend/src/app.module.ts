import { Module } from '@nestjs/common';
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

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
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

    AuthModule,
    TenantModule,
    CommunityModule,
    IamModule,
    LedgerModule,
    NotificationsModule,
  ],
  controllers: [],
  providers: [
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule {}
