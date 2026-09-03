import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, LessThan, In } from 'typeorm';
import {
  Notificacion,
  EstadoNotificacion,
} from '../../domain/notificacion.entity';
import { EmailSender } from '../email/email-sender';

@Injectable()
export class EnviarNotificacionesJob {
  private readonly logger = new Logger(EnviarNotificacionesJob.name);

  constructor(
    @InjectRepository(Notificacion)
    private readonly notificacionRepository: Repository<Notificacion>,
    private readonly emailSender: EmailSender,
  ) {}

  @Cron('0 51 * * * *')
  async handleCron() {
    const pendientes = await this.notificacionRepository.find({
      where: [
        { estado: EstadoNotificacion.PENDIENTE, intentos: LessThan(3) },
        { estado: EstadoNotificacion.FALLIDA, intentos: LessThan(3) },
      ],
      take: 20,
    });

    if (pendientes.length === 0) return;

    this.logger.log(
      `Procesando ${pendientes.length} notificaciones pendientes...`,
    );

    for (const notif of pendientes) {
      notif.intentos += 1;
      notif.ultimoIntento = new Date();

      const success = await this.emailSender.send({
        to: notif.destinatarioEmail,
        subject: notif.asunto,
        html: notif.cuerpo,
      });

      if (success) {
        notif.estado = EstadoNotificacion.ENVIADA;
      } else {
        notif.estado = EstadoNotificacion.FALLIDA;
      }

      await this.notificacionRepository.save(notif);
    }
  }
}
