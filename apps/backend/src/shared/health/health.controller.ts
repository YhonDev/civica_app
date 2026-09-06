import {
  Controller,
  Get,
  HttpException,
  HttpStatus,
  UseGuards,
} from '@nestjs/common';
import { DataSource } from 'typeorm';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { TokenRevocationService } from '../auth/token-revocation.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@ApiTags('Health')
@Controller('health')
export class HealthController {
  constructor(
    private readonly dataSource: DataSource,
    private readonly tokenRevocation: TokenRevocationService,
  ) {}

  @Get()
  @ApiOperation({
    summary: 'Health check',
    description:
      'Verifica que la aplicación y la base de datos estén disponibles',
  })
  async check() {
    const dbConnected = this.dataSource.isInitialized;
    const redisStatus = this.tokenRevocation.getRedisStatus();
    const result = {
      status: dbConnected ? 'ok' : 'unhealthy',
      timestamp: new Date().toISOString(),
      database: dbConnected ? 'connected' : 'disconnected',
      redis: redisStatus.status,
    };

    if (!dbConnected) {
      throw new HttpException(result, HttpStatus.SERVICE_UNAVAILABLE);
    }

    return result;
  }

  @Get('dependencies')
  @UseGuards(JwtAuthGuard)
  @ApiOperation({
    summary: 'Dependency diagnostics',
    description:
      'Muestra el estado de dependencias sin exponer datos de conexión',
  })
  dependencies() {
    const dbConnected = this.dataSource.isInitialized;
    const redisStatus = this.tokenRevocation.getRedisStatus();

    return {
      status: dbConnected ? 'ok' : 'unhealthy',
      timestamp: new Date().toISOString(),
      dependencies: {
        database: dbConnected ? 'connected' : 'disconnected',
        redis: redisStatus.status,
        fallback: redisStatus.usingFallback ? 'memory' : 'none',
      },
    };
  }
}
