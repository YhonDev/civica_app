import { Injectable, Logger } from '@nestjs/common';

export interface EmailOptions {
  to: string;
  subject: string;
  html: string;
}

@Injectable()
export class EmailSender {
  private readonly logger = new Logger(EmailSender.name);

  async send(options: EmailOptions): Promise<boolean> {
    try {
      // En modo desarrollo / simulación, logueamos el correo
      this.logger.log(`[SIMULATED EMAIL] Sent to: ${options.to} | Subject: ${options.subject}`);
      return true;
    } catch (error) {
      this.logger.error(`Failed to send email to ${options.to}:`, error);
      return false;
    }
  }
}
