/**
 * Setup file to ensure JWT_SECRET is set before the NestJS module is loaded.
 * The auth.module.ts reads process.env.JWT_SECRET at module-definition time,
 * which is before ConfigModule.forRoot() loads the .env file.
 * Jest's setupFiles run before imports are resolved, so this ensures the
 * correct secret is available to ALL consumers (JwtModule + JwtStrategy).
 */
process.env.JWT_SECRET = 'civica-pago-dev-jwt-secret-2026';
// Secret dedicado para refresh tokens (diferente al de access tokens)
process.env.JWT_REFRESH_SECRET = 'civica-pago-dev-jwt-refresh-secret-2026';
