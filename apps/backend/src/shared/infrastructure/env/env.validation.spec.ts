import { Environment, validateEnv } from './env.validation';

describe('validateEnv (Fail-Fast Environment Validation)', () => {
  const validBaseConfig = {
    NODE_ENV: 'development',
    PORT: 3000,
    DATABASE_HOST: '127.0.0.1',
    DATABASE_PORT: 54322,
    DATABASE_USER: 'postgres',
    DATABASE_PASSWORD: 'secretpassword',
    DATABASE_NAME: 'civica_db',
    JWT_SECRET: 'super-secret-jwt-key-min-8',
    REDIS_ENABLED: 'false',
    THROTTLE_LIMIT: 30,
  };

  it('debería validar con éxito una configuración completa y válida', () => {
    const validated = validateEnv(validBaseConfig);
    expect(validated.NODE_ENV).toBe(Environment.Development);
    expect(validated.PORT).toBe(3000);
    expect(validated.DATABASE_PASSWORD).toBe('secretpassword');
    expect(validated.JWT_SECRET).toBe('super-secret-jwt-key-min-8');
  });

  it('debería lanzar error si falta DATABASE_PASSWORD en no-test', () => {
    const invalidConfig = { ...validBaseConfig, NODE_ENV: 'production' };
    delete (invalidConfig as Record<string, unknown>).DATABASE_PASSWORD;

    expect(() => validateEnv(invalidConfig)).toThrow(
      /DATABASE_PASSWORD is required for database connection/,
    );
  });

  it('debería lanzar error si falta JWT_SECRET en no-test', () => {
    const invalidConfig = { ...validBaseConfig, NODE_ENV: 'production' };
    delete (invalidConfig as Record<string, unknown>).JWT_SECRET;

    expect(() => validateEnv(invalidConfig)).toThrow(
      /JWT_SECRET is required to sign access tokens/,
    );
  });

  it('debería lanzar error si JWT_SECRET tiene menos de 8 caracteres', () => {
    const invalidConfig = { ...validBaseConfig, JWT_SECRET: 'short' };

    expect(() => validateEnv(invalidConfig)).toThrow(
      /JWT_SECRET must be at least 8 characters long/,
    );
  });

  it('debería lanzar error si PORT no es un número válido o está fuera de rango', () => {
    const invalidConfig = { ...validBaseConfig, PORT: 999999 };

    expect(() => validateEnv(invalidConfig)).toThrow(/PORT must not be greater than 65535/);
  });

  it('debería exigir REDIS_URL cuando REDIS_ENABLED es true', () => {
    const invalidConfig = {
      ...validBaseConfig,
      REDIS_ENABLED: 'true',
    };

    expect(() => validateEnv(invalidConfig)).toThrow(
      /REDIS_URL is required when REDIS_ENABLED is true/,
    );
  });

  it('debería aceptar REDIS_URL cuando REDIS_ENABLED es true y la URL está presente', () => {
    const validConfig = {
      ...validBaseConfig,
      REDIS_ENABLED: 'true',
      REDIS_URL: 'redis://localhost:6379',
    };

    const validated = validateEnv(validConfig);
    expect(validated.REDIS_ENABLED).toBe('true');
    expect(validated.REDIS_URL).toBe('redis://localhost:6379');
  });

  it('debería autocompletar fallbacks seguros en entorno test si faltan', () => {
    const testConfig = {
      NODE_ENV: 'test',
    };

    const validated = validateEnv(testConfig);
    expect(validated.DATABASE_PASSWORD).toBeDefined();
    expect(validated.JWT_SECRET).toBeDefined();
  });
});
