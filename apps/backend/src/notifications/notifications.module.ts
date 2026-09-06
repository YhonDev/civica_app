import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Usuario } from '../iam/domain/usuario.entity';
import { Actividad } from './domain/actividad.entity';
import { ActividadRepository } from './domain/actividad.repository';
import { ActividadRepositoryImpl } from './infrastructure/actividad.repository.impl';
import { Notificacion } from './domain/notificacion.entity';
import { NotificacionesController } from './infrastructure/controllers/notificaciones.controller';

import { EventsGateway } from './events.gateway';
import { FcmPushService } from './infrastructure/push/fcm-push.service';

@Module({
  imports: [TypeOrmModule.forFeature([Actividad, Notificacion, Usuario])],
  controllers: [NotificacionesController],
  providers: [
    {
      provide: ActividadRepository,
      useClass: ActividadRepositoryImpl,
    },
    EventsGateway,
    FcmPushService,
  ],
  exports: [ActividadRepository, EventsGateway, FcmPushService],
})
export class NotificationsModule {}
