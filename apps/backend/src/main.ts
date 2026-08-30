import { NestFactory } from '@nestjs/core';
import { ValidationPipe, ClassSerializerInterceptor } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import helmet from 'helmet';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // ─── Global Prefix ───────────────────────────────────
  app.setGlobalPrefix('api');

  // ─── Security Middleware ─────────────────────────────
  // Helmet: protege contra vulnerabilidades HTTP comunes
  app.use(helmet());

  // CORS: solo orígenes permitidos (default: http://localhost:3000)
  const corsOrigins = process.env.CORS_ORIGIN?.split(',') ?? ['http://localhost:3000'];
  app.enableCors({
    origin: corsOrigins,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
    credentials: true,
  });

  // ─── Validation ─────────────────────────────────────
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  // ─── Serialization ──────────────────────────────────
  app.useGlobalInterceptors(new ClassSerializerInterceptor(app.get(Reflector)));

  // ─── Graceful Shutdown ──────────────────────────────
  app.enableShutdownHooks();

  await app.listen(process.env.PORT ?? 3000);
  console.log(`Servidor iniciado en puerto ${process.env.PORT ?? 3000}`);
}
bootstrap();
