import 'dotenv/config';
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { ValidationPipe, ClassSerializerInterceptor } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import helmet from 'helmet';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module';

async function bootstrap() {
  // Necesario para app.set('trust proxy') con tipado correcto
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  // ─── Reverse Proxy (Render, etc.) ────────────────────
  // Detrás del proxy de Render todas las conexiones llegan desde la IP del
  // proxy: sin esto, el rate limiter por IP agruparía a todos los clientes
  // en un solo bucket y las IPs reales no serían visibles en los logs.
  // Confía en el último salto (el proxy propio de la plataforma).
  app.set('trust proxy', 1);

  // ─── Global Prefix ───────────────────────────────────
  app.setGlobalPrefix('api');

  // ─── Swagger / OpenAPI ───────────────────────────────
  const config = new DocumentBuilder()
    .setTitle('Cívica Pago API')
    .setDescription(
      'API REST para gestión de cobros de vigilancia.\n\n' +
        '**Autenticación:** Bearer JWT (obtener en POST /api/auth/login).\n\n' +
        '**Multi-tenant:** Todas las operaciones están scopeadas por `tenantId` del usuario autenticado.',
    )
    .setVersion('1.0')
    .addBearerAuth(
      {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        description: 'Pega el accessToken obtenido en POST /api/auth/login',
      },
      'jwt-auth',
    )
    .addTag('Auth', 'Autenticación, registro y gestión de sesiones')
    .addTag('Usuarios', 'Gestión de usuarios, cobradores y residentes')
    .addTag('Proyectos', 'CRUD de proyectos, etapas, manzanas y casas')
    .addTag('Cobradores', 'Registro de cobradores')
    .addTag('Residentes', 'Gestión de residentes')
    .addTag('Tarifas', 'Configuración y consulta de tarifas')
    .addTag('Montos', 'Montos predefinidos de pago')
    .addTag('Cobros', 'Gestión de cobros (cuotas)')
    .addTag('Pagos', 'Registro, corrección y validación de pagos')
    .addTag('Solicitudes', 'Solicitudes de cobro presencial')
    .addTag('Dashboard', 'Dashboards por rol (admin, cobrador, residente)')
    .addTag('Reportes', 'Generación de reportes de recaudo')
    .addTag('Tickets', 'Comprobantes de pago')
    .addTag('Notificaciones', 'Gestión de notificaciones fallidas')
    .addTag('Health', 'Health checks del sistema')
    .build();

  if (
    process.env.NODE_ENV !== 'production' ||
    process.env.ENABLE_SWAGGER === 'true'
  ) {
    const document = SwaggerModule.createDocument(app, config);
    SwaggerModule.setup('docs', app, document, {
      swaggerOptions: {
        persistAuthorization: true,
        tagsSorter: 'alpha',
        operationsSorter: 'method',
      },
      customSiteTitle: 'Cívica Pago — API Docs',
    });
    console.log(
      `📄 Swagger docs disponibles en http://localhost:${process.env.PORT ?? 3000}/docs`,
    );
  }

  // ─── Security Middleware ─────────────────────────────
  // Helmet: protege contra vulnerabilidades HTTP comunes
  app.use(helmet());

  // CORS: orígenes permitidos (en desarrollo admite cualquier puerto localhost/127.0.0.1 para Flutter Web)
  const isDev = process.env.NODE_ENV !== 'production';
  const corsOrigins = process.env.CORS_ORIGIN?.split(',').map((s) => s.trim()) ?? [
    'http://localhost:3000',
  ];
  const allowAllOrigins = corsOrigins.includes('*');
  app.enableCors({
    origin: (
      origin: string | undefined,
      callback: (err: Error | null, allow?: boolean) => void,
    ) => {
      if (!origin) return callback(null, true);
      if (isDev && /^https?:\/\/(localhost|127\.0\.0\.1)(:[0-9]+)?$/.test(origin)) {
        return callback(null, true);
      }
      if (allowAllOrigins) {
        // CORS_ORIGIN=* : permitir cualquier origen (útil con apps móviles / web
        // en dominio desconocido). credentials:true + wildcard no es válido
        // según la spec, así que en este modo se desactiva credentials.
        return callback(null, true);
      }
      if (corsOrigins.includes(origin)) {
        return callback(null, true);
      }
      // Rechazo limpio de CORS (sin header ACAO → el navegador bloquea la
      // petición). Lanzar Error aquí producía un 500 en el preflight,
      // indistinguible de un fallo real del servidor.
      console.warn(
        `[CORS] Origen no permitido: ${origin}. Configúralo en CORS_ORIGIN (separado por comas) o usa CORS_ORIGIN=* para permitir todo.`,
      );
      return callback(null, false);
    },
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
    credentials: !allowAllOrigins,
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

  const shutdown = async (signal: string) => {
    console.log(
      `\n[Nest] 🛑 Recibida señal ${signal}. Cerrando servidor limpiamente...`,
    );
    try {
      await app.close();
      console.log('[Nest] ✅ Servidor y conexiones cerrados con éxito.');
    } catch (err) {
      console.error('[Nest] Error durante el cierre:', err);
    } finally {
      process.exit(0);
    }
  };

  process.on('SIGINT', () => {
    void shutdown('SIGINT');
  });
  process.on('SIGTERM', () => {
    void shutdown('SIGTERM');
  });
  process.on('SIGHUP', () => {
    void shutdown('SIGHUP');
  });
  process.on('uncaughtException', (err) => {
    console.error('[Nest] 💥 Excepción no controlada:', err);
    void shutdown('uncaughtException');
  });
  process.on('unhandledRejection', (reason) => {
    console.error('[Nest] 💥 Promesa rechazada no controlada:', reason);
    void shutdown('unhandledRejection');
  });

  const port = process.env.PORT ?? 3000;
  // Sin host explícito: Node escucha en :: (dual-stack), aceptando conexiones
  // IPv6 (::1) e IPv4. Fijar '0.0.0.0' dejaba fuera a los navegadores que
  // resuelven "localhost" a ::1 primero (ECONNREFUSED → OperationError en
  // Flutter web).
  await app.listen(port);
  console.log(`Servidor iniciado en puerto ${port} (dual-stack IPv4+IPv6)`);
}
void bootstrap();
