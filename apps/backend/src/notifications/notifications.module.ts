import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Actividad } from './domain/actividad.entity';
import { ActividadRepository } from './domain/actividad.repository';
import { ActividadRepositoryImpl } from './infrastructure/actividad.repository.impl';

@Module({
  imports: [TypeOrmModule.forFeature([Actividad])],
  providers: [
    {
      provide: ActividadRepository,
      useClass: ActividadRepositoryImpl,
    },
  ],
  exports: [ActividadRepository],
})
export class NotificationsModule {}
