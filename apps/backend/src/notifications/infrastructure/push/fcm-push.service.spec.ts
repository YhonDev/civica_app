import { Test, TestingModule } from '@nestjs/testing';
import { FcmPushService } from './fcm-push.service';

describe('FcmPushService', () => {
  let service: FcmPushService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [FcmPushService],
    }).compile();

    service = module.get<FcmPushService>(FcmPushService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should gracefully handle empty tokens', async () => {
    const result = await service.sendToToken('', {
      title: 'Test',
      body: 'Test',
    });
    expect(result).toBe(false);
  });

  it('should send notification in dev/mock mode when firebase app is null', async () => {
    const result = await service.sendToToken('mock-fcm-token-12345', {
      title: '¡Pago Registrado!',
      body: 'Se recibieron $40.000 COP',
    });
    expect(result).toBe(true);
  });

  it('should send pago registrado push payload with deep link data', async () => {
    const spy = jest.spyOn(service, 'sendToToken').mockResolvedValue(true);

    await service.sendPagoRegistradoPush({
      residenteToken: 'res-token-123',
      monto: 4000000,
      pagoId: 'pago-abc',
      casaNombre: 'Manzana A Casa 1',
    });

    expect(spy).toHaveBeenCalledWith('res-token-123', {
      title: '💳 ¡Pago Registrado Exitosamente!',
      body: 'Se ha procesado tu pago de $40.000 para la vivienda Manzana A Casa 1.',
      data: {
        type: 'PAGO_REGISTRADO',
        pagoId: 'pago-abc',
        deepLink: '/ticket/pago-abc',
      },
    });
  });

  it('should send solicitud creada push payload to cobradores', async () => {
    const spy = jest.spyOn(service, 'sendToToken').mockResolvedValue(true);

    await service.sendSolicitudCreadaPush({
      cobradorTokens: ['token-cobrador-1', 'token-cobrador-2'],
      casaNombre: 'Manzana B Casa 3',
      solicitudId: 'sol-123',
      nota: 'Por favor venir antes de las 5pm',
    });

    expect(spy).toHaveBeenCalledTimes(2);
    expect(spy).toHaveBeenNthCalledWith(
      1,
      'token-cobrador-1',
      expect.objectContaining({
        title: '📍 ¡Nueva Solicitud de Cobro!',
      }),
    );
    expect(spy).toHaveBeenNthCalledWith(
      2,
      'token-cobrador-2',
      expect.objectContaining({
        title: '📍 ¡Nueva Solicitud de Cobro!',
      }),
    );
  });
});
