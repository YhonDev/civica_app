import { Test, TestingModule } from '@nestjs/testing';
import { DataSource } from 'typeorm';
import { EliminarResidenteUseCase } from './eliminar-residente.use-case';
import { ResidenteRepository } from '../../infrastructure/residente.repository';

describe('EliminarResidenteUseCase', () => {
  let useCase: EliminarResidenteUseCase;
  let mockResidenteRepo: any;
  let mockQueryRunner: any;
  let mockDataSource: any;

  beforeEach(async () => {
    mockResidenteRepo = {
      findById: jest.fn(),
    };

    mockQueryRunner = {
      connect: jest.fn(),
      startTransaction: jest.fn(),
      commitTransaction: jest.fn(),
      rollbackTransaction: jest.fn(),
      release: jest.fn(),
      query: jest.fn(),
    };

    mockDataSource = {
      createQueryRunner: jest.fn().mockReturnValue(mockQueryRunner),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        EliminarResidenteUseCase,
        { provide: ResidenteRepository, useValue: mockResidenteRepo },
        { provide: DataSource, useValue: mockDataSource },
      ],
    }).compile();

    useCase = module.get<EliminarResidenteUseCase>(EliminarResidenteUseCase);
  });

  it('should be defined', () => {
    expect(useCase).toBeDefined();
  });

  it('should execute full transactional cascade deletion', async () => {
    mockResidenteRepo.findById.mockResolvedValue({
      id: 'res-123',
      tenantId: 'tenant-001',
    });

    await useCase.execute('res-123', 'tenant-001');

    expect(mockQueryRunner.startTransaction).toHaveBeenCalled();
    expect(mockQueryRunner.query).toHaveBeenCalledWith(
      expect.stringContaining('DELETE FROM residentes'),
      ['res-123', 'tenant-001'],
    );
    expect(mockQueryRunner.commitTransaction).toHaveBeenCalled();
    expect(mockQueryRunner.release).toHaveBeenCalled();
  });

  it('should rollback transaction on error', async () => {
    mockResidenteRepo.findById.mockResolvedValue({
      id: 'res-123',
      tenantId: 'tenant-001',
    });
    mockQueryRunner.query.mockRejectedValue(new Error('FK constraint'));

    await expect(useCase.execute('res-123', 'tenant-001')).rejects.toThrow(
      'FK constraint',
    );
    expect(mockQueryRunner.rollbackTransaction).toHaveBeenCalled();
    expect(mockQueryRunner.release).toHaveBeenCalled();
  });
});
