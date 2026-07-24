import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundException, BadRequestException } from '@nestjs/common';
import { EliminarCobroUseCase } from './eliminar-cobro.use-case';
import { CobroRepository } from '../../infrastructure/persistence/cobro.repository';
import { PagoRepository } from '../../infrastructure/persistence/pago.repository';
import { Cobro } from '../../domain/cobro.entity';
import { Money } from '../../../shared/common/value-objects';

describe('EliminarCobroUseCase', () => {
  let useCase: EliminarCobroUseCase;

  const mockCobroRepo = {
    findById: jest.fn(),
    delete: jest.fn(),
  };

  const mockPagoRepo = {
    countByCobro: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        EliminarCobroUseCase,
        { provide: CobroRepository, useValue: mockCobroRepo },
        { provide: PagoRepository, useValue: mockPagoRepo },
      ],
    }).compile();

    useCase = module.get<EliminarCobroUseCase>(EliminarCobroUseCase);
  });

  function crearCobro(): Cobro {
    return Cobro.crear(
      'residente-1',
      'tenant-1',
      'Cuota de prueba',
      Money.ofCOP(40000),
      '2026-01-01',
      '2026-02-01',
      '2026-01-15',
    );
  }

  it('should throw NotFoundException if cobro does not exist', async () => {
    mockCobroRepo.findById.mockResolvedValue(null);

    await expect(useCase.execute('cobro-1')).rejects.toThrow(
      NotFoundException,
    );
    expect(mockCobroRepo.delete).not.toHaveBeenCalled();
  });

  it('should throw BadRequestException if cobro has associated payments', async () => {
    const cobro = crearCobro();
    mockCobroRepo.findById.mockResolvedValue(cobro);
    mockPagoRepo.countByCobro.mockResolvedValue(1);

    await expect(useCase.execute('cobro-1')).rejects.toThrow(
      BadRequestException,
    );
    expect(mockCobroRepo.delete).not.toHaveBeenCalled();
  });

  it('should successfully delete cobro if it has no payments', async () => {
    const cobro = crearCobro();
    mockCobroRepo.findById.mockResolvedValue(cobro);
    mockPagoRepo.countByCobro.mockResolvedValue(0);
    mockCobroRepo.delete.mockResolvedValue(undefined);

    await expect(useCase.execute('cobro-1')).resolves.not.toThrow();
    expect(mockCobroRepo.delete).toHaveBeenCalledWith('cobro-1');
  });
});
