import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';
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
    AuthModule,
    TenantModule,
    CommunityModule,
    IamModule,
    LedgerModule,
    NotificationsModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
