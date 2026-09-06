import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundException } from '@nestjs/common';
import { ActualizarTarifaUseCase } from './actualizar-tarifa.use-case';
import { TarifaRepository } from '../../infrastructure/persistence/tarifa.repository';
import { TarifaDerivacionService } from '../services/tarifa-derivacion.service';
import { Tarifa } from '../../domain/tarifa.entity';
import { Money } from '../../../shared/common/value-objects';

describe('ActualizarTarifaUseCase', () => {
  let useCase: ActualizarTarifaUseCase;

  const mockTarifaRepo = {
    findById: jest.fn(),
    save: jest.fn(),
  };

  const mockDerivacionService = {
    actualizarActivas: jest.fn(),
  };

  const TENANT_ID = 'tenant-1';

  function crearTarifa(): Tarifa {
    const tarifa = new Tarifa();
    tarifa.id = 'tarifa-1';
    tarifa.tenantId = TENANT_ID;
    tarifa.proyectoId = 'proy-1';
    tarifa.modalidad = 'MENSUAL';
    tarifa.monto = Money.ofCOP(40000).amount;
    tarifa.activa = true;
    tarifa.fechaVigencia = '2026-01-01';
    return tarifa;
  }

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ActualizarTarifaUseCase,
        { provide: TarifaRepository, useValue: mockTarifaRepo },
        { provide: TarifaDerivacionService, useValue: mockDerivacionService },
      ],
    }).compile();
    useCase = module.get<ActualizarTarifaUseCase>(ActualizarTarifaUseCase);
  });

  it('should throw NotFoundException if tarifa does not exist', async () => {
    mockTarifaRepo.findById.mockResolvedValue(null);

    await expect(
      useCase.execute({
        tarifaId: 'tarifa-x',
        tenantId: TENANT_ID,
        montoPesos: 50000,
      }),
    ).rejects.toThrow(NotFoundException);
  });

  it('should throw NotFoundException if tarifa belongs to another tenant', async () => {
    const tarifa = crearTarifa(); // tenant-1
    mockTarifaRepo.findById.mockImplementation(async (_id, tenantId) =>
      tenantId === TENANT_ID ? tarifa : null,
    );

    await expect(
      useCase.execute({
        tarifaId: 'tarifa-1',
        tenantId: 'tenant-OTHER',
        montoPesos: 50000,
      }),
    ).rejects.toThrow(NotFoundException);

    expect(mockTarifaRepo.findById).toHaveBeenCalledWith(
      'tarifa-1',
      'tenant-OTHER',
    );
  });

  it('should update fechaVigencia when tarifa belongs to caller tenant', async () => {
    const tarifa = crearTarifa();
    mockTarifaRepo.findById.mockResolvedValue(tarifa);
    mockTarifaRepo.save.mockImplementation(async (t) => t);

    const result = await useCase.execute({
      tarifaId: 'tarifa-1',
      tenantId: TENANT_ID,
      fechaVigencia: '2026-03-01',
    });

    expect(result.fechaVigencia).toBe('2026-03-01');
    expect(mockTarifaRepo.findById).toHaveBeenCalledWith('tarifa-1', TENANT_ID);
  });
});
