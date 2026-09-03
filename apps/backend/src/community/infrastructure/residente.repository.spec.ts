import { Test, TestingModule } from '@nestjs/testing';
import { ResidenteRepository } from './residente.repository';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Residente } from '../domain/residente.entity';
import { Repository } from 'typeorm';

describe('ResidenteRepository', () => {
  let repo: ResidenteRepository;
  let typeOrmRepo: Repository<Residente>;

  const mockQueryBuilder = {
    select: jest.fn().mockReturnThis(),
    addSelect: jest.fn().mockReturnThis(),
    where: jest.fn().mockReturnThis(),
    andWhere: jest.fn().mockReturnThis(),
    leftJoinAndSelect: jest.fn().mockReturnThis(),
    orderBy: jest.fn().mockReturnThis(),
    getMany: jest.fn(),
    getRawOne: jest.fn(),
    subQuery: jest.fn().mockReturnThis(),
    from: jest.fn().mockReturnThis(),
    getQuery: jest.fn().mockReturnValue('subquery'),
  };

  const mockRepo = {
    createQueryBuilder: jest.fn().mockReturnValue(mockQueryBuilder),
    find: jest.fn(),
    findOne: jest.fn(),
    count: jest.fn(),
  };

  const TENANT_ID = 'tenant-1';

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ResidenteRepository,
        {
          provide: getRepositoryToken(Residente),
          useValue: mockRepo,
        },
      ],
    }).compile();

    repo = module.get<ResidenteRepository>(ResidenteRepository);

    // Default mock chain
    mockRepo.createQueryBuilder.mockReturnValue(mockQueryBuilder);
    mockQueryBuilder.select.mockReturnThis();
    mockQueryBuilder.addSelect.mockReturnThis();
    mockQueryBuilder.where.mockReturnThis();
    mockQueryBuilder.andWhere.mockReturnThis();
    mockQueryBuilder.leftJoinAndSelect.mockReturnThis();
    mockQueryBuilder.orderBy.mockReturnThis();
    mockQueryBuilder.subQuery.mockReturnValue({
      select: jest.fn().mockReturnThis(),
      from: jest.fn().mockReturnThis(),
      where: jest.fn().mockReturnThis(),
      getQuery: jest.fn().mockReturnValue('(subquery)'),
    });
  });

  describe('findByTenant()', () => {
    it('should find residentes by tenant ordered by nombre ASC', async () => {
      const mockResidentes = [
        { id: 'r1', nombre: 'Ana' },
        { id: 'r2', nombre: 'Carlos' },
      ];
      mockRepo.find.mockResolvedValue(mockResidentes);

      const result = await repo.findByTenant(TENANT_ID);

      expect(result).toEqual(mockResidentes);
      expect(mockRepo.find).toHaveBeenCalledWith({
        order: { nombre: 'ASC' },
        where: { tenantId: TENANT_ID },
      });
    });
  });

  describe('countByTenant()', () => {
    it('should count residentes by tenant', async () => {
      mockRepo.count.mockResolvedValue(50);
      const result = await repo.countByTenant(TENANT_ID);
      expect(result).toBe(50);
    });
  });

  describe('findById()', () => {
    it('should find residente by id', async () => {
      mockRepo.findOne.mockResolvedValue({ id: 'r1' });
      const result = await repo.findById('r1');
      expect(result?.id).toBe('r1');
      expect(mockRepo.findOne).toHaveBeenCalledWith({ where: { id: 'r1' } });
    });
  });

  describe('findByIdWithRelations()', () => {
    it('should load tenencias > casa > manzana > etapa relations', async () => {
      const mockResidente = {
        id: 'r1',
        tenencias: [{ casa: { manzana: { etapa: {} } } }],
      };
      mockRepo.findOne.mockResolvedValue(mockResidente);

      const result = await repo.findByIdWithRelations('r1');

      expect(mockRepo.findOne).toHaveBeenCalledWith({
        where: { id: 'r1' },
        relations: {
          tenencias: {
            casa: {
              manzana: {
                etapa: true,
              },
            },
          },
        },
      });
      expect(result).toEqual(mockResidente);
    });
  });

  describe('buscarPorFiltros()', () => {
    it('should build query with tenant filter', async () => {
      mockQueryBuilder.getMany.mockResolvedValue([]);

      await repo.buscarPorFiltros({ tenantId: TENANT_ID });

      expect(mockQueryBuilder.where).toHaveBeenCalled();
      expect(mockQueryBuilder.leftJoinAndSelect).toHaveBeenCalledTimes(5);
      expect(mockQueryBuilder.getMany).toHaveBeenCalled();
    });

    it('should filter by casaId when provided', async () => {
      mockQueryBuilder.getMany.mockResolvedValue([]);

      await repo.buscarPorFiltros({ tenantId: TENANT_ID, casaId: 'casa-1' });

      const andWhereCalls = mockQueryBuilder.andWhere.mock.calls;
      const casaFilter = andWhereCalls.find(
        (call: any[]) => call[0] && call[0].includes('casaId = :casaId'),
      );
      expect(casaFilter).toBeDefined();
    });

    it('should filter by etapaId when provided', async () => {
      mockQueryBuilder.getMany.mockResolvedValue([]);

      await repo.buscarPorFiltros({ tenantId: TENANT_ID, etapaId: 'etapa-1' });

      const andWhereCalls = mockQueryBuilder.andWhere.mock.calls;
      // Should use a subquery for etapa filtering
      expect(andWhereCalls.length).toBeGreaterThanOrEqual(1);
    });
  });

  describe('findWithTenencia()', () => {
    it('should load tenencias relation', async () => {
      mockRepo.findOne.mockResolvedValue({ id: 'r1', tenencias: [] });
      const result = await repo.findWithTenencia('r1');
      expect(mockRepo.findOne).toHaveBeenCalledWith({
        where: { id: 'r1' },
        relations: { tenencias: true },
      });
      expect(result?.id).toBe('r1');
    });
  });

  describe('buscarPorEtapas()', () => {
    it('should return empty array when etapaIds is empty', async () => {
      const result = await repo.buscarPorEtapas(TENANT_ID, []);
      expect(result).toEqual([]);
      expect(mockRepo.createQueryBuilder).not.toHaveBeenCalled();
    });

    it('should build query with subquery for etapa IDs', async () => {
      mockQueryBuilder.getMany.mockResolvedValue([]);

      await repo.buscarPorEtapas(TENANT_ID, ['etapa-1', 'etapa-2']);

      expect(mockQueryBuilder.leftJoinAndSelect).toHaveBeenCalled();
      expect(mockQueryBuilder.getMany).toHaveBeenCalled();
    });

    it('should order by nombre ASC', async () => {
      mockQueryBuilder.getMany.mockResolvedValue([]);

      await repo.buscarPorEtapas(TENANT_ID, ['etapa-1']);

      expect(mockQueryBuilder.orderBy).toHaveBeenCalledWith(
        'residente.nombre',
        'ASC',
      );
    });
  });

  describe('countNuevosByWeek()', () => {
    it('should count residentes created within last 7 days', async () => {
      mockQueryBuilder.getRawOne.mockResolvedValue({ count: 5 });

      const result = await repo.countNuevosByWeek(TENANT_ID);

      expect(result).toBe(5);
      expect(mockQueryBuilder.andWhere).toHaveBeenCalledWith(
        'residente.createdAt >= :fecha',
        expect.anything(),
      );
    });

    it('should return 0 when no new residentes', async () => {
      mockQueryBuilder.getRawOne.mockResolvedValue({ count: null });
      const result = await repo.countNuevosByWeek(TENANT_ID);
      expect(result).toBe(0);
    });
  });

  describe('buscarPorEtapas — edge cases', () => {
    it('should handle null etapaIds gracefully', async () => {
      const result = await repo.buscarPorEtapas(TENANT_ID, null as any);
      expect(result).toEqual([]);
    });
  });
});
