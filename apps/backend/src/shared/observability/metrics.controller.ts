import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { MetricsService } from './metrics.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { RolUsuario } from '../../iam/domain/usuario.entity';

@ApiTags('Metrics')
@ApiBearerAuth('jwt-auth')
@Controller('metrics')
@UseGuards(JwtAuthGuard, RolesGuard)
export class MetricsController {
  constructor(private readonly metrics: MetricsService) {}

  @Get()
  @Roles(RolUsuario.ADMIN)
  @ApiOperation({ summary: 'Métricas agregadas de rendimiento HTTP (solo ADMIN)' })
  getMetrics() {
    return {
      timestamp: new Date().toISOString(),
      ...this.metrics.snapshot(),
    };
  }
}
