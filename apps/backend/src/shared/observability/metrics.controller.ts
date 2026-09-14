import { Controller, Get } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { MetricsService } from './metrics.service';

@ApiTags('Metrics')
@Controller('metrics')
export class MetricsController {
  constructor(private readonly metrics: MetricsService) {}

  @Get()
  @ApiOperation({ summary: 'Métricas agregadas de rendimiento HTTP' })
  getMetrics() {
    return {
      timestamp: new Date().toISOString(),
      ...this.metrics.snapshot(),
    };
  }
}
