import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Actividad } from './domain/actividad.entity';
import { ActividadRepository } from './domain/actividad.repository';
import { ActividadRepositoryImpl } from './infrastructure/actividad.repository.impl';
import { Notificacion } from './domain/notificacion.entity';
import { EmailSender } from './infrastructure/email/email-sender';
import { EnviarNotificacionesJob } from './infrastructure/jobs/enviar-notificaciones.job';
import { NotificacionesController } from './infrastructure/controllers/notificaciones.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Actividad, Notificacion])],
  controllers: [NotificacionesController],
  providers: [
    {
      provide: ActividadRepository,
      useClass: ActividadRepositoryImpl,
    },
    EmailSender,
    EnviarNotificacionesJob,
  ],
  exports: [ActividadRepository, EmailSender],
})
export class NotificationsModule {}
