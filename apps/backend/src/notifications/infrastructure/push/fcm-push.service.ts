import { Injectable, Logger } from '@nestjs/common';
import * as admin from 'firebase-admin';

export interface PushPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
}

@Injectable()
export class FcmPushService {
  private readonly logger = new Logger(FcmPushService.name);
  private firebaseApp: any = null;

  constructor() {
    this.initFirebase();
  }

  private initFirebase() {
    try {
      const fbAdmin = admin as any;
      if (fbAdmin.apps && fbAdmin.apps.length > 0) {
        this.firebaseApp = fbAdmin.apps[0];
      } else if (process.env.FIREBASE_CREDENTIALS) {
        const serviceAccount = JSON.parse(process.env.FIREBASE_CREDENTIALS);
        this.firebaseApp = fbAdmin.initializeApp({
          credential: fbAdmin.credential.cert(serviceAccount),
        });
        this.logger.log('Firebase Admin SDK inicializado exitosamente');
      } else {
        this.logger.warn('FIREBASE_CREDENTIALS no configurado. Ejecutando FcmPushService en modo Simulado/Dev.');
      }
    } catch (error) {
      this.logger.error('Error al inicializar Firebase Admin SDK:', error);
    }
  }

  async sendToToken(token: string, payload: PushPayload): Promise<boolean> {
    if (!token) return false;

    this.logger.log(`[FCM Push] Enviando notificación a token (${token.slice(0, 10)}...): "${payload.title}"`);

    if (!this.firebaseApp) {
      this.logger.debug(`[FCM Mock] Notificación push entregada en simulación: ${payload.title} - ${payload.body}`);
      return true;
    }

    try {
      const fbAdmin = admin as any;
      await fbAdmin.messaging(this.firebaseApp).send({
        token,
        notification: {
          title: payload.title,
          body: payload.body,
        },
        data: payload.data ?? {},
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
            },
          },
        },
      });
      return true;
    } catch (e) {
      this.logger.error(`Error enviando FCM Push a token ${token}: ${e}`);
      return false;
    }
  }

  /// Notificación de Pago Registrado
  async sendPagoRegistradoPush(params: {
    residenteToken?: string;
    monto: number;
    pagoId: string;
    casaNombre: string;
  }) {
    const montoFormateado = `$${(params.monto / 100).toLocaleString('es-CO')}`;

    if (params.residenteToken) {
      await this.sendToToken(params.residenteToken, {
        title: '💳 ¡Pago Registrado Exitosamente!',
        body: `Se ha procesado tu pago de ${montoFormateado} para la vivienda ${params.casaNombre}.`,
        data: {
          type: 'PAGO_REGISTRADO',
          pagoId: params.pagoId,
          deepLink: `/ticket/${params.pagoId}`,
        },
      });
    }
  }

  /// Notificación de Solicitud de Cobro Creada
  async sendSolicitudCreadaPush(params: {
    cobradorTokens: string[];
    casaNombre: String;
    solicitudId: string;
    nota?: string;
  }) {
    for (const token of params.cobradorTokens) {
      await this.sendToToken(token, {
        title: '📍 ¡Nueva Solicitud de Cobro!',
        body: `La casa ${params.casaNombre} solicita cobro presencial. ${params.nota ? `Nota: "${params.nota}"` : ''}`,
        data: {
          type: 'SOLICITUD_CREADA',
          solicitudId: params.solicitudId,
          deepLink: `/jornada`,
        },
      });
    }
  }
}
