import { Test, TestingModule } from '@nestjs/testing';
import { DataSource } from 'typeorm';
import { PurgaSolicitudesJob } from './purga-solicitudes.job';
import { ActividadRepository } from '../../../notifications/domain/actividad.repository';

describe('PurgaSolicitudesJob', () => {
  let job: PurgaSolicitudesJob;
  let mockQueryRunner: any;
  let mockDataSource: any;
  let mockActividadRepo: any;

  beforeEach(async () => {
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

    mockActividadRepo = {
      registrar: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PurgaSolicitudesJob,
        { provide: DataSource, useValue: mockDataSource },
        { provide: ActividadRepository, useValue: mockActividadRepo },
      ],
    }).compile();

    job = module.get<PurgaSolicitudesJob>(PurgaSolicitudesJob);
  });

  it('should be defined', () => {
    expect(job).toBeDefined();
  });

  it('should execute purge transaction and log audit event for expired solicitudes', async () => {
    const expiredRows = [
      { id: 'sol-1', tenant_id: 'tenant-123', residente_id: 'res-1' },
      { id: 'sol-2', tenant_id: 'tenant-123', residente_id: 'res-2' },
    ];
    mockQueryRunner.query.mockResolvedValue([expiredRows]);

    const result = await job.executePurga();

    expect(mockQueryRunner.startTransaction).toHaveBeenCalled();
    expect(mockQueryRunner.query).toHaveBeenCalledWith(
      expect.stringContaining('UPDATE solicitudes'),
    );
    expect(mockQueryRunner.commitTransaction).toHaveBeenCalled();
    expect(mockQueryRunner.release).toHaveBeenCalled();
    expect(result.purgadas).toBe(2);
    expect(mockActividadRepo.registrar).toHaveBeenCalledTimes(2);
  });

  it('should rollback transaction on query error', async () => {
    mockQueryRunner.query.mockRejectedValue(new Error('DB Timeout'));

    const result = await job.executePurga();

    expect(mockQueryRunner.rollbackTransaction).toHaveBeenCalled();
    expect(mockQueryRunner.release).toHaveBeenCalled();
    expect(result.purgadas).toBe(0);
  });
});
