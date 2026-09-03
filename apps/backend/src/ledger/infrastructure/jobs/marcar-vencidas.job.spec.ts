import { Test, TestingModule } from '@nestjs/testing';
import { Logger } from '@nestjs/common';

import { MarcarVencidasJob } from './marcar-vencidas.job';
import { MarcarVencidasUseCase } from '../../application/use-cases/marcar-vencidas.use-case';

describe('MarcarVencidasJob', () => {
  let job: MarcarVencidasJob;
  let useCase: jest.Mocked<MarcarVencidasUseCase>;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MarcarVencidasJob,
        {
          provide: MarcarVencidasUseCase,
          useValue: {
            execute: jest.fn(),
          },
        },
      ],
    }).compile();

    job = module.get<MarcarVencidasJob>(MarcarVencidasJob);
    useCase = module.get(MarcarVencidasUseCase);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('handleCron', () => {
    it('should call use case and log result on success', async () => {
      useCase.execute.mockResolvedValue({ marcadas: 3 });
      const logSpy = jest.spyOn(Logger.prototype, 'log');

      await job.handleCron();

      expect(useCase.execute).toHaveBeenCalledTimes(1);
      expect(logSpy).toHaveBeenCalledWith(
        expect.stringContaining('3 cobro(s) marcado(s) como vencido(s)'),
      );
    });

    it('should log zero when no cobros are overdue', async () => {
      useCase.execute.mockResolvedValue({ marcadas: 0 });
      const logSpy = jest.spyOn(Logger.prototype, 'log');

      await job.handleCron();

      expect(useCase.execute).toHaveBeenCalledTimes(1);
      expect(logSpy).toHaveBeenCalledWith(
        expect.stringContaining('0 cobro(s) marcado(s) como vencido(s)'),
      );
    });

    it('should log error when use case throws', async () => {
      useCase.execute.mockRejectedValue(new Error('Timeout'));
      const errorSpy = jest.spyOn(Logger.prototype, 'error');

      await job.handleCron();

      expect(useCase.execute).toHaveBeenCalledTimes(1);
      expect(errorSpy).toHaveBeenCalledWith(expect.stringContaining('Timeout'));
    });

    it('should log generic error when thrown value is not an Error', async () => {
      useCase.execute.mockRejectedValue(null);
      const errorSpy = jest.spyOn(Logger.prototype, 'error');

      await job.handleCron();

      expect(errorSpy).toHaveBeenCalledWith(
        expect.stringContaining('Error desconocido'),
      );
    });
  });
});
