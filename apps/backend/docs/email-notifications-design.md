# Diseño Futuro: Notificaciones por Correo (Resend + BullMQ)

> **Estado: PROPUESTO — no implementado.** El job anterior (`enviar-notificaciones.job.ts`)
> y el stub `EmailSender` se eliminaron en `6ef0b05` porque eran un no-op sin proveedor.
> Este doc queda como plano listo para ejecutar cuando la funcionalidad se apruebe.
> Notificaciones in-app (WebSocket) y push (FCM) siguen activas y no cambian.

## 1. Objetivo

Enviar por correo los avisos transaccionales del condominio (cuota emitida, aviso de mora,
recibo de pago, restablecimiento de contraseña) con entrega garantizada y reintentos,
sin bloquear los requests HTTP que los originan.

## 2. Arquitectura

```
UseCases (GenerarCobros, MarcarVencidas, RegistrarPago, Auth)
        │  (persisten Notificacion estado=PENDIENTE, igual que hoy)
        ▼
   DB: notificaciones ──► ENQUEUER: al crear, encola job en BullMQ
                                     │
                          Redis (REDIS_URL ya soportado)
                                     │
                                     ▼
                    WORKER: EmailWorker (BullMQ Worker separado)
                        │  intenta Resend API
                        │  fallo → retry con backoff exponencial (3 intentos)
                        ▼
                 PENDIENTE → ENVIADA | FALLIDA (intentos/ultimoIntento ya existen)
```

- **Productor:** los use-cases solo persisten la fila `Notificacion` (contrato actual de
  `notificaciones` con `destinatarioEmail/asunto/cuerpo/estado/intentos/ultimoIntento`).
- **Encolador:** un pequeño servicio `EmailQueueService` hace `emailQueue.add({ notificacionId })`
  tras el `save` (solo el ID; el worker rele la fila para no enviar datos stale).
- **Worker:** `EmailWorker` procesa 1 job a la vez (rate limit de Resend), rele la notificación,
  llama a `ResendEmailSender.send()`, y actualiza `estado/intentos/ultimoIntento`.

## 3. Piezas concretas

| Pieza | Ubicación propuesta | Notas |
|---|---|---|
| `RESEND_API_KEY` (env) | `.env` backend | Nunca en el repo; leer en bootstrap |
| `ResendEmailSender` | `notifications/infrastructure/email/resend-email-sender.ts` | Implementa la misma interfaz `send({to, subject, html}) => Promise<boolean>` del stub eliminado |
| `EmailQueueService` | `notifications/application/email-queue.service.ts` | `@OnModuleInit` crea `new Queue('email', { connection })`; `add` con `jobId: notificacionId` (idempotente) |
| `EmailWorker` | `notifications/infrastructure/jobs/email.worker.ts` | BullMQ `Worker`, `attempts: 3`, `backoff: { type: 'exponential', delay: 30_000 }`, `removeOnComplete: 100` |
| `EmailModule` wiring | `notifications.module.ts` | Registrar queue/worker solo si `REDIS_ENABLED=true && REDIS_URL` (mismo guard que `TokenRevocationService`); sin Redis, degradar a envío síncrono con log de advertencia |

## 4. Reintentos y estados

- **3 intentos** con backoff exponencial (30s → 60s → 120s), cubriendo RNF05 de la visión original.
- Éxito: `estado=ENVIADA`, `ultimoIntento=now`. Agotados intentos: `estado=FALLIDA` (visible en
  `NotificacionesController`, que ya expone las fallidas).
- `jobId` = `notificacionId` evita duplicados si el encolador se reejecuta.
- Reconciliación: cron ligero (cada 10 min) re-encola `PENDIENTE` con `ultimoIntento < now - 15min`
  — cubre caídas de Redis entre el save y el add.

## 5. Por qué Resend (y alternativa)

- API simple (`resend-node`), free tier amplio, dominios verificados, webhooks de bounce.
- Alternativa evaluable: **SendGrid** (mismo diseño; solo cambia `ResendEmailSender`).
- El resto de la arquitectura (BullMQ, estados, reintentos) es agnóstico del proveedor.

## 6. Configuración mínima al implementar

```bash
# deps
pnpm add bullmq resend   # ioredis ya está

# env
REDIS_ENABLED=true
REDIS_URL=redis://...            # Upstash/ElastiCache/localhost
RESEND_API_KEY=re_...
EMAIL_FROM="Cívica Pago <no-reply@civicapago.com>"
```

## 7. Plan de verificación (cuando se implemente)

1. Unit: `ResendEmailSender` (mock fetch) y `EmailWorker` (transiciones de estado, 3 intentos).
2. Integración: Redis real en test → crear notificación → assert `ENVIADA` y 1 llamada a Resend.
3. Resiliencia: `kill -9` al worker a mitad de job → el job se re-procesa sin duplicar correo
   (idempotencia por `jobId`).
4. E2E manual: mora generada por `MarcarVencidasJob` → correo recibido → fila `ENVIADA`.
