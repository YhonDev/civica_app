import { Module } from '@nestjs/common';
import { AuthModule } from '../shared/auth/auth.module';
import { PlatformAdminController } from './infrastructure/controllers/platform-admin.controller';
import { PlatformAdminGuard } from './guards/platform-admin.guard';
import { PlatformOverviewService } from './application/platform-overview.service';
import { PlatformAuditService } from './domain/platform-audit.service';
import { PlatformAuthService } from './application/platform-auth.service';
import { PlatformAuthController } from './infrastructure/controllers/platform-auth.controller';
import { PlatformInvitationService } from './application/platform-invitation.service';

@Module({
  imports: [AuthModule],
  controllers: [PlatformAdminController, PlatformAuthController],
  providers: [
    PlatformAdminGuard,
    PlatformOverviewService,
    PlatformAuditService,
    PlatformAuthService,
    PlatformInvitationService,
  ],
  exports: [PlatformInvitationService],
})
export class PlatformModule {}
