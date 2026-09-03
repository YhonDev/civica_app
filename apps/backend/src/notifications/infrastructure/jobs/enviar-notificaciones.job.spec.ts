import { EnviarNotificacionesJob } from './enviar-notificaciones.job';
import { EstadoNotificacion } from '../../domain/notificacion.entity';

describe('EnviarNotificacionesJob', () => {
  let job: EnviarNotificacionesJob;
  let mockNotificacionRepository: any;
  let mockEmailSender: any;

  beforeEach(() => {
    mockNotificacionRepository = {
      find: jest.fn(),
      save: jest.fn(),
    };

    mockEmailSender = {
      send: jest.fn(),
    };

    job = new EnviarNotificacionesJob(
      mockNotificacionRepository,
      mockEmailSender,
    );
  });

  it('no hace nada si no hay notificaciones pendientes', async () => {
    mockNotificacionRepository.find.mockResolvedValue([]);

    await job.handleCron();

    expect(mockEmailSender.send).not.toHaveBeenCalled();
    expect(mockNotificacionRepository.save).not.toHaveBeenCalled();
  });

  it('procesa notificaciones pendientes exitosamente y las marca como ENVIADA', async () => {
    const notif = {
      id: 'notif-1',
      destinatarioEmail: 'residente@test.com',
      asunto: 'Cobro del Mes',
      cuerpo: '<p>Tu cuota está lista</p>',
      estado: EstadoNotificacion.PENDIENTE,
      intentos: 0,
      ultimoIntento: null,
    };

    mockNotificacionRepository.find.mockResolvedValue([notif]);
    mockEmailSender.send.mockResolvedValue(true);

    await job.handleCron();

    expect(notif.intentos).toBe(1);
    expect(notif.estado).toBe(EstadoNotificacion.ENVIADA);
    expect(mockEmailSender.send).toHaveBeenCalledWith({
      to: 'residente@test.com',
      subject: 'Cobro del Mes',
      html: '<p>Tu cuota está lista</p>',
    });
    expect(mockNotificacionRepository.save).toHaveBeenCalledWith(notif);
  });

  it('marca como FALLIDA si el envío por email retorna false', async () => {
    const notif = {
      id: 'notif-2',
      destinatarioEmail: 'error@test.com',
      asunto: 'Aviso de Mora',
      cuerpo: 'Mensaje',
      estado: EstadoNotificacion.PENDIENTE,
      intentos: 1,
      ultimoIntento: null,
    };

    mockNotificacionRepository.find.mockResolvedValue([notif]);
    mockEmailSender.send.mockResolvedValue(false);

    await job.handleCron();

    expect(notif.intentos).toBe(2);
    expect(notif.estado).toBe(EstadoNotificacion.FALLIDA);
    expect(mockNotificacionRepository.save).toHaveBeenCalledWith(notif);
  });
});
