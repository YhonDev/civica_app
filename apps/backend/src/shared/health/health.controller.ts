import { Controller, Get } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { TokenRevocationService } from '../auth/token-revocation.service';

@ApiTags('Health')
@Controller('health')
export class HealthController {
  constructor(
    private readonly dataSource: DataSource,
    private readonly tokenRevocation: TokenRevocationService,
  ) {}

  @Get()
  @ApiOperation({ summary: 'Health check', description: 'Verifica el estado del servidor, base de datos y Redis' })
  async check() {
    const dbConnected = this.dataSource.isInitialized;
    const redisStatus = this.tokenRevocation.getRedisStatus();

    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      database: dbConnected ? 'connected' : 'disconnected',
      redis: redisStatus,
    };
  }
}
