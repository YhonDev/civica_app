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

  // Desactivado temporalmente hasta configurar proveedor de correo en producción (Resend / SendGrid)
  // @Cron(CronExpression.EVERY_5_MINUTES)
  async handleCron() {
    return;
  }
}
