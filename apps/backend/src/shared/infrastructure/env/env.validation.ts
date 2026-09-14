import 'reflect-metadata';
import { plainToInstance, Type } from 'class-transformer';
import {
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  Min,
  MinLength,
  ValidateIf,
  validateSync,
} from 'class-validator';

export enum Environment {
  Development = 'development',
  Production = 'production',
  Test = 'test',
  Provisioning = 'provisioning',
}

export class EnvironmentVariables {
  @IsEnum(Environment)
  @IsOptional()
  NODE_ENV: Environment = Environment.Development;

  @IsNumber()
  @Min(1)
  @Max(65535)
  @IsOptional()
  @Type(() => Number)
  PORT?: number = 3000;

  @IsNumber()
  @Min(1)
  @Max(65535)
  @IsOptional()
  @Type(() => Number)
  APP_PORT?: number = 3000;

  @IsString()
  @IsOptional()
  DATABASE_HOST?: string = '127.0.0.1';

  @IsInt()
  @Min(1)
  @Max(65535)
  @IsOptional()
  @Type(() => Number)
  DATABASE_PORT?: number = 54322;

  @IsString()
  @IsOptional()
  DATABASE_USER?: string = 'postgres';

  @IsString()
  @IsNotEmpty({ message: 'DATABASE_PASSWORD is required for database connection' })
  DATABASE_PASSWORD!: string;

  @IsString()
  @IsOptional()
  DATABASE_NAME?: string = 'postgres';

  @IsString()
  @IsOptional()
  DATABASE_SSL?: string;

  @IsString()
  @IsOptional()
  DATABASE_SSL_REJECT_UNAUTHORIZED?: string;

  @IsNumber()
  @IsOptional()
  @Type(() => Number)
  DATABASE_MAX_QUERY_TIME_MS?: number = 150;

  @IsString()
  @IsNotEmpty({ message: 'JWT_SECRET is required to sign access tokens' })
  @MinLength(8, { message: 'JWT_SECRET must be at least 8 characters long' })
  JWT_SECRET!: string;

  @IsString()
  @IsOptional()
  JWT_REFRESH_SECRET?: string;

  @IsString()
  @IsOptional()
  REDIS_ENABLED?: string = 'false';

  @ValidateIf((o: EnvironmentVariables) => o.REDIS_ENABLED?.toLowerCase() === 'true')
  @IsString()
  @IsNotEmpty({ message: 'REDIS_URL is required when REDIS_ENABLED is true' })
  REDIS_URL?: string;

  @IsString()
  @IsOptional()
  CORS_ORIGIN?: string;

  @IsNumber()
  @Min(1)
  @IsOptional()
  @Type(() => Number)
  THROTTLE_LIMIT?: number = 30;

  @IsString()
  @IsOptional()
  ENABLE_SWAGGER?: string;

  @IsString()
  @IsOptional()
  FIREBASE_CREDENTIALS?: string;
}

export function validateEnv(config: Record<string, unknown>): EnvironmentVariables {
  // En entorno de test, inyectar defaults seguros solo si el entorno configurado es test
  const targetEnv = config.NODE_ENV ?? process.env.NODE_ENV;
  const isTest = targetEnv === 'test' || targetEnv === Environment.Test;
  const effectiveConfig = { ...config };

  if (isTest) {
    if (!effectiveConfig.DATABASE_PASSWORD) {
      effectiveConfig.DATABASE_PASSWORD = process.env.DATABASE_PASSWORD || 'postgres';
    }
    if (!effectiveConfig.JWT_SECRET) {
      effectiveConfig.JWT_SECRET = process.env.JWT_SECRET || 'test-jwt-secret-min-8-chars';
    }
  }

  const validatedConfig = plainToInstance(EnvironmentVariables, effectiveConfig, {
    enableImplicitConversion: true,
  });

  const errors = validateSync(validatedConfig, {
    skipMissingProperties: false,
  });

  if (errors.length > 0) {
    const formattedErrors = errors
      .map((err) => {
        const constraints = err.constraints ? Object.values(err.constraints).join(', ') : 'Invalid';
        return `  - ${err.property}: ${constraints} (recibido: ${JSON.stringify(err.value)})`;
      })
      .join('\n');

    throw new Error(
      `❌ Configuración de entorno inválida (Fail-Fast al arranque):\n${formattedErrors}\n` +
        `Por favor, verifica tu archivo .env o las variables de entorno del servidor.`,
    );
  }

  return validatedConfig;
}
