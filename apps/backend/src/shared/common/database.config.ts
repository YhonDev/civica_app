import { TypeOrmModuleOptions } from '@nestjs/typeorm';

/**
 * Validates critical environment variables at startup.
 * Throws a clear error message if any required variable is missing.
 */
function validateEnv(): void {
  const required = ['DATABASE_PASSWORD', 'JWT_SECRET'];

  const missing = required.filter((key) => !process.env[key]);
  if (missing.length > 0) {
    throw new Error(
      `❌ Variables de entorno requeridas faltantes: ${missing.join(', ')}\n` +
        `   Configúralas en tu archivo .env o en las variables de entorno del sistema.`,
    );
  }
}

export function databaseConfig(): TypeOrmModuleOptions {
  // Validate at config time (called once from AppModule)
  validateEnv();

  const sslMode = process.env.DATABASE_SSL;

  return {
    type: 'postgres',
    host: process.env.DATABASE_HOST || '127.0.0.1',
    port: parseInt(process.env.DATABASE_PORT || '54322', 10),
    username: process.env.DATABASE_USER || 'postgres',
    password: process.env.DATABASE_PASSWORD!,
    database: process.env.DATABASE_NAME || 'postgres',
    autoLoadEntities: true,
    synchronize: false,
    logging:
      process.env.NODE_ENV === 'development' ? ['error', 'warn'] : ['error'],
    ...(sslMode && {
      ssl: {
        // Permite conexión segura SSL a poolers de Supabase (por defecto no rechaza CA intermedio si no está explícito)
        rejectUnauthorized:
          process.env.DATABASE_SSL_REJECT_UNAUTHORIZED === 'true',
      },
    }),
  };
}
