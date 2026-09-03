import {
  Controller,
  Get,
  Post,
  Param,
  Body,
  Delete,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../../shared/auth/jwt-auth.guard';
import { RolesGuard } from '../../../shared/auth/guards/roles.guard';
import { Roles } from '../../../shared/auth/decorators/roles.decorator';
import { CurrentTenant } from '../../../shared/tenant/current-tenant.decorator';
import { RolUsuario } from '../../../iam/domain/usuario.entity';
import { PlanDeCobroRepository } from '../../infrastructure/persistence/plan-de-cobro.repository';

@ApiTags('Dashboard')
@ApiBearerAuth('jwt-auth')
@Controller('planes-de-cobro')
@UseGuards(JwtAuthGuard)
export class PlanesDeCobroController {
  constructor(private readonly planDeCobroRepository: PlanDeCobroRepository) {}

  @Get()
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async listar(@CurrentTenant() tenantId: string) {
    if (!tenantId) return [];
    return this.planDeCobroRepository.findActivosByTenant(tenantId);
  }
}
