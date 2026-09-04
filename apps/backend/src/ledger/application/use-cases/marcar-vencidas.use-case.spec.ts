import { Test, TestingModule } from '@nestjs/testing';
import { MarcarVencidasUseCase } from './marcar-vencidas.use-case';
import { CobroRepository } from '../../infrastructure/persistence/cobro.repository';

describe('MarcarVencidasUseCase', () => {
  let useCase: MarcarVencidasUseCase;

  const mockCobroRepo = {
    markVencidasAtomic: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MarcarVencidasUseCase,
        { provide: CobroRepository, useValue: mockCobroRepo },
      ],
    }).compile();

    useCase = module.get<MarcarVencidasUseCase>(MarcarVencidasUseCase);
  });

  it('should call atomic UPDATE and return affected count', async () => {
    mockCobroRepo.markVencidasAtomic.mockResolvedValue(5);

    const result = await useCase.execute();

    expect(result.marcadas).toBe(5);
    expect(mockCobroRepo.markVencidasAtomic).toHaveBeenCalledTimes(1);
  });

  it('should return 0 when no cobros are vencidas', async () => {
    mockCobroRepo.markVencidasAtomic.mockResolvedValue(0);

    const result = await useCase.execute();

    expect(result.marcadas).toBe(0);
    expect(mockCobroRepo.markVencidasAtomic).toHaveBeenCalledTimes(1);
  });

  it('should not call findVencidas or saveMany (no read-modify-write)', async () => {
    mockCobroRepo.markVencidasAtomic.mockResolvedValue(3);

    await useCase.execute();

    // Ensure the old read-modify-write methods are not used
    expect((mockCobroRepo as any).findVencidas).toBeUndefined();
    expect((mockCobroRepo as any).saveMany).toBeUndefined();
  });
});
