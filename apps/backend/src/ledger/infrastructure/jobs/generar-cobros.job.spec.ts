import { Test, TestingModule } from '@nestjs/testing';
import { Logger } from '@nestjs/common';

import { GenerarCobrosJob } from './generar-cobros.job';
import { GenerarCobrosUseCase } from '../../application/use-cases/generar-cobros.use-case';

describe('GenerarCobrosJob', () => {
  let job: GenerarCobrosJob;
  let useCase: jest.Mocked<GenerarCobrosUseCase>;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GenerarCobrosJob,
        {
          provide: GenerarCobrosUseCase,
          useValue: {
            execute: jest.fn(),
          },
        },
      ],
    }).compile();

    job = module.get<GenerarCobrosJob>(GenerarCobrosJob);
    useCase = module.get(GenerarCobrosUseCase);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('handleCron', () => {
    it('should call use case and log result on success', async () => {
      useCase.execute.mockResolvedValue({ generados: 5 });
      const logSpy = jest.spyOn(Logger.prototype, 'log');

      await job.handleCron();

      expect(useCase.execute).toHaveBeenCalledTimes(1);
      expect(logSpy).toHaveBeenCalledWith(
        expect.stringContaining('5 cobro(s) generado(s)'),
      );
    });

    it('should log zero when no cobros are generated', async () => {
      useCase.execute.mockResolvedValue({ generados: 0 });
      const logSpy = jest.spyOn(Logger.prototype, 'log');

      await job.handleCron();

      expect(useCase.execute).toHaveBeenCalledTimes(1);
      expect(logSpy).toHaveBeenCalledWith(
        expect.stringContaining('0 cobro(s) generado(s)'),
      );
    });

    it('should log error when use case throws', async () => {
      useCase.execute.mockRejectedValue(new Error('DB connection failed'));
      const errorSpy = jest.spyOn(Logger.prototype, 'error');

      await job.handleCron();

      expect(useCase.execute).toHaveBeenCalledTimes(1);
      expect(errorSpy).toHaveBeenCalledWith(
        expect.stringContaining('DB connection failed'),
      );
    });

    it('should log generic error when thrown value is not an Error', async () => {
      useCase.execute.mockRejectedValue('string error');
      const errorSpy = jest.spyOn(Logger.prototype, 'error');

      await job.handleCron();

      expect(errorSpy).toHaveBeenCalledWith(
        expect.stringContaining('Error desconocido'),
      );
    });
  });
});
