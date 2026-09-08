import { Test, TestingModule } from '@nestjs/testing';
import { CobroRepository } from './cobro.repository';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Cobro } from '../../domain/cobro.entity';
import { Repository, In } from 'typeorm';

describe('CobroRepository', () => {
  let repo: CobroRepository;
  let typeOrmRepo: Repository<Cobro>;

  // Mock the TypeORM repository methods we use
  const mockQueryBuilder = {
    select: jest.fn().mockReturnThis(),
    addSelect: jest.fn().mockReturnThis(),
    where: jest.fn().mockReturnThis(),
    andWhere: jest.fn().mockReturnThis(),
    leftJoin: jest.fn().mockReturnThis(),
    groupBy: jest.fn().mockReturnThis(),
    orderBy: jest.fn().mockReturnThis(),
    limit: jest.fn().mockReturnThis(),
    getRawOne: jest.fn(),
    getRawMany: jest.fn(),
    getMany: jest.fn(),
  };

  const mockRepo = {
    createQueryBuilder: jest.fn().mockReturnValue(mockQueryBuilder),
    find: jest.fn(),
    findOne: jest.fn(),
    count: jest.fn(),
    save: jest.fn(),
  };

  const TENANT_ID = 'tenant-1';

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CobroRepository,
        {
          provide: getRepositoryToken(Cobro),
          useValue: mockRepo,
        },
      ],
    }).compile();

    repo = module.get<CobroRepository>(CobroRepository);

    // Inject BaseTenantRepository's applyTenantFilter mock
    // The base class calls createQueryBuilder internally - we mock that
    mockRepo.createQueryBuilder.mockReturnValue(mockQueryBuilder);
    mockQueryBuilder.select.mockReturnThis();
    mockQueryBuilder.addSelect.mockReturnThis();
    mockQueryBuilder.where.mockReturnThis();
    mockQueryBuilder.andWhere.mockReturnThis();
    mockQueryBuilder.leftJoin.mockReturnThis();
    mockQueryBuilder.groupBy.mockReturnThis();
    mockQueryBuilder.orderBy.mockReturnThis();
    mockQueryBuilder.limit.mockReturnThis();
  });

  describe('findById()', () => {
    it('should call findOne with id and tenantId', async () => {
      mockRepo.findOne.mockResolvedValue({ id: 'cobro-1' });
      const result = await repo.findById('cobro-1', TENANT_ID);
      expect(mockRepo.findOne).toHaveBeenCalledWith({
        where: { id: 'cobro-1', tenantId: TENANT_ID },
      });
      expect(result?.id).toBe('cobro-1');
    });

    it('should return null when not found', async () => {
      mockRepo.findOne.mockResolvedValue(null);
      const result = await repo.findById('no-existe', TENANT_ID);
      expect(result).toBeNull();
    });

    it('should include tenantId in where to enforce multi-tenant isolation', async () => {
      mockRepo.findOne.mockResolvedValue(null);
      await repo.findById('cobro-1', 'other-tenant');
      expect(mockRepo.findOne).toHaveBeenCalledWith({
        where: { id: 'cobro-1', tenantId: 'other-tenant' },
      });
    });
  });

  describe('findByResidentes()', () => {
    it('should filter by tenantId to enforce multi-tenant isolation', async () => {
      mockQueryBuilder.getMany.mockResolvedValue([]);
      await repo.findByResidentes(['res-1', 'res-2'], TENANT_ID);
      expect(mockQueryBuilder.where).toHaveBeenCalledWith(
        'cobro.residenteId IN (:...residenteIds)',
        { residenteIds: ['res-1', 'res-2'] },
      );
      expect(mockQueryBuilder.andWhere).toHaveBeenCalledWith(
        'cobro.tenantId = :tenantId',
        { tenantId: TENANT_ID },
      );
    });

    it('should return empty array when no residenteIds', async () => {
      const result = await repo.findByResidentes([], TENANT_ID);
      expect(result).toEqual([]);
    });
  });

  describe('findByResidente()', () => {
    it('should call find with residenteId, tenantId and order', async () => {
      mockRepo.find.mockResolvedValue([]);
      await repo.findByResidente('res-1', TENANT_ID);
      expect(mockRepo.find).toHaveBeenCalledWith({
        where: { residenteId: 'res-1', tenantId: TENANT_ID },
        relations: {
          residente: { casaActual: { manzana: { etapa: true } } },
          casa: { manzana: { etapa: true } },
        },
        order: { periodoInicio: 'DESC' },
      });
    });
  });

  describe('findPendientesByTenant()', () => {
    it('should find cobros with PENDIENTE estado', async () => {
      mockRepo.find.mockResolvedValue([]);
      await repo.findPendientesByTenant(TENANT_ID);
      expect(mockRepo.find).toHaveBeenCalledWith({
        where: { tenantId: TENANT_ID, estado: expect.anything() },
        relations: expect.anything(),
        order: { fechaVencimiento: 'ASC' },
      });
    });
  });

  describe('sumMontoByYear() — EXTRACT', () => {
    it('should use EXTRACT(YEAR FROM ...) instead of LIKE', async () => {
      mockQueryBuilder.getRawOne.mockResolvedValue({ total: 100000 });

      const result = await repo.sumMontoByYear(TENANT_ID, 2026);

      expect(result).toBe(100000);
      // Verify EXTRACT is used, not LIKE
      const andWhereCalls = mockQueryBuilder.andWhere.mock.calls;
      const hasExtract = andWhereCalls.some(
        (call: any[]) => call[0] && call[0].includes('EXTRACT(YEAR FROM'),
      );
      const hasLike = andWhereCalls.some(
        (call: any[]) => call[0] && call[0].includes('LIKE'),
      );
      expect(hasExtract).toBe(true);
      expect(hasLike).toBe(false);
    });

    it('should return 0 when no data', async () => {
      mockQueryBuilder.getRawOne.mockResolvedValue({ total: null });
      const result = await repo.sumMontoByYear(TENANT_ID, 2025);
      expect(result).toBe(0);
    });
  });

  describe('groupByWeekInMonth() — EXTRACT', () => {
    it('should use EXTRACT instead of LIKE for date filtering', async () => {
      mockQueryBuilder.getRawMany.mockResolvedValue([
        { semana: 1, pagados: 5 },
      ]);

      const result = await repo.groupByWeekInMonth(TENANT_ID, 2026, 7);

      expect(result).toHaveLength(1);
      const andWhereCalls = mockQueryBuilder.andWhere.mock.calls;
      const hasExtractYear = andWhereCalls.some(
        (call: any[]) => call[0] && call[0].includes('EXTRACT(YEAR'),
      );
      const hasExtractMonth = andWhereCalls.some(
        (call: any[]) => call[0] && call[0].includes('EXTRACT(MONTH'),
      );
      const hasLike = andWhereCalls.some(
        (call: any[]) => call[0] && call[0].includes('LIKE'),
      );
      expect(hasExtractYear).toBe(true);
      expect(hasExtractMonth).toBe(true);
      expect(hasLike).toBe(false);
    });

    it('should return empty array when no data', async () => {
      mockQueryBuilder.getRawMany.mockResolvedValue([]);
      const result = await repo.groupByWeekInMonth(TENANT_ID, 2026, 7);
      expect(result).toEqual([]);
    });
  });

  describe('countPendientesByWeek() — EXTRACT', () => {
    it('should use EXTRACT instead of LIKE for date filtering', async () => {
      mockQueryBuilder.getRawMany.mockResolvedValue([
        { semana: 2, pendientes: 3, enMora: 1 },
      ]);

      const result = await repo.countPendientesByWeek(TENANT_ID, 2026, 7);

      expect(result).toHaveLength(1);
      const andWhereCalls = mockQueryBuilder.andWhere.mock.calls;
      const hasExtractYear = andWhereCalls.some(
        (call: any[]) => call[0] && call[0].includes('EXTRACT(YEAR'),
      );
      const hasLike = andWhereCalls.some(
        (call: any[]) => call[0] && call[0].includes('LIKE'),
      );
      expect(hasExtractYear).toBe(true);
      expect(hasLike).toBe(false);
    });
  });

  describe('findVencidas()', () => {
    it('should find PENDIENTE cobros with past fechaVencimiento', async () => {
      mockRepo.find.mockResolvedValue([]);
      await repo.findVencidas();
      expect(mockRepo.find).toHaveBeenCalled();
      const findArgs = mockRepo.find.mock.calls[0][0];
      expect(findArgs.where[0].estado).toBe('PENDIENTE');
      expect(findArgs.where[1].estado).toBe('PARCIAL');
      expect(findArgs.where[0].fechaVencimiento).toBeDefined();
    });
  });

  describe('countPropietariosInMora()', () => {
    it('should count distinct residentes with VENCIDA/PENDIENTE/PARCIAL', async () => {
      mockQueryBuilder.getRawOne.mockResolvedValue({ count: 5 });

      const result = await repo.countPropietariosInMora(TENANT_ID);

      expect(result).toBe(5);
      const andWhereCalls = mockQueryBuilder.andWhere.mock.calls;
      const hasEstados = andWhereCalls.some(
        (call: any[]) => call[0] && call[0].includes('IN'),
      );
      expect(hasEstados).toBe(true);
    });
  });

  describe('findMasAntiguoConSaldo()', () => {
    it('should find oldest PENDIENTE cobro ordered by fechaVencimiento ASC', async () => {
      const mockCobro = { id: 'oldest', estado: 'PENDIENTE' };
      mockRepo.findOne.mockResolvedValue(mockCobro);

      const result = await repo.findMasAntiguoConSaldo('res-1', TENANT_ID);

      expect(result?.id).toBe('oldest');
      expect(mockRepo.findOne).toHaveBeenCalledWith({
        where: {
          residenteId: 'res-1',
          tenantId: TENANT_ID,
          estado: In(['VENCIDA', 'PARCIAL', 'PENDIENTE']),
        },
        order: { fechaVencimiento: 'ASC' },
      });
    });

    it('should return null when no pending cobros', async () => {
      mockRepo.findOne.mockResolvedValue(null);
      const result = await repo.findMasAntiguoConSaldo('res-1', TENANT_ID);
      expect(result).toBeNull();
    });
  });

  describe('findMasAntiguoConSaldoLocked()', () => {
    it('should filter by tenantId to enforce multi-tenant isolation', async () => {
      const mockEmQb = {
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        setLock: jest.fn().mockReturnThis(),
        getOne: jest.fn().mockResolvedValue({ id: 'cobro-1' }),
      };
      const mockEm = {
        createQueryBuilder: jest.fn().mockReturnValue(mockEmQb),
      };

      const result = await repo.findMasAntiguoConSaldoLocked(
        mockEm as any,
        'res-1',
        TENANT_ID,
      );

      // Debe filtrar por tenant para no devolver cobros de otro tenant
      expect(mockEmQb.andWhere).toHaveBeenCalledWith(
        'cobro.tenantId = :tenantId',
        {
          tenantId: TENANT_ID,
        },
      );
      expect(result?.id).toBe('cobro-1');
    });
  });

  describe('countByEstadoInMonth()', () => {
    it('should return pagadas and pendientes counts', async () => {
      mockQueryBuilder.getRawOne.mockResolvedValue({
        pagadas: 10,
        pendientes: 5,
      });

      const result = await repo.countByEstadoInMonth(TENANT_ID, 2026, 7);

      expect(result.pagadas).toBe(10);
      expect(result.pendientes).toBe(5);
    });

    it('should return zeros when no data', async () => {
      mockQueryBuilder.getRawOne.mockResolvedValue({
        pagadas: null,
        pendientes: null,
      });

      const result = await repo.countByEstadoInMonth(TENANT_ID, 2026, 7);

      expect(result.pagadas).toBe(0);
      expect(result.pendientes).toBe(0);
    });
  });

  describe('sumSaldoVencidasByTenant()', () => {
    it('should sum (monto - montoPagado) for VENCIDA/PENDIENTE/PARCIAL', async () => {
      mockQueryBuilder.getRawOne.mockResolvedValue({ total: 200000 });

      const result = await repo.sumSaldoVencidasByTenant(TENANT_ID);

      expect(result).toBe(200000);
    });

    it('should return 0 when no data', async () => {
      mockQueryBuilder.getRawOne.mockResolvedValue({ total: null });
      const result = await repo.sumSaldoVencidasByTenant(TENANT_ID);
      expect(result).toBe(0);
    });
  });

  describe('sumMontoByMonth()', () => {
    it('should sum monto for given month excluding ANULADO', async () => {
      mockQueryBuilder.getRawOne.mockResolvedValue({ total: 8000000 });
      const result = await repo.sumMontoByMonth(TENANT_ID, 2026, 7);
      expect(result).toBe(8000000);
    });
  });

  describe('groupByTarifaModalidad()', () => {
    it('should group cobros by tarifa modalidad', async () => {
      mockQueryBuilder.getRawMany.mockResolvedValue([
        { modalidad: 'MENSUAL', totalCuotas: 10, pagadas: 7 },
      ]);
      const result = await repo.groupByTarifaModalidad(TENANT_ID, 2026, 7);
      expect(result).toHaveLength(1);
      expect(result[0].modalidad).toBe('MENSUAL');
    });
  });

  describe('findAllWithFilters() — aislamiento multi-tenant', () => {
    const fullQb = () => ({
      leftJoinAndSelect: jest.fn().mockReturnThis(),
      where: jest.fn().mockReturnThis(),
      andWhere: jest.fn().mockReturnThis(),
      orderBy: jest.fn().mockReturnThis(),
      take: jest.fn().mockReturnThis(),
      skip: jest.fn().mockReturnThis(),
      getManyAndCount: jest.fn().mockResolvedValue([[], 0]),
    });

    it('should always filter by tenantId as the first condition', async () => {
      const qb = fullQb();
      mockRepo.createQueryBuilder.mockReturnValue(qb as any);

      await repo.findAllWithFilters('tenant-A', { status: 'PENDIENTE' });

      expect(qb.where).toHaveBeenCalledWith('cobro.tenantId = :tenantId', {
        tenantId: 'tenant-A',
      });
      // Every extra filter must be andWhere, never overwrite the tenant where
      expect(qb.andWhere).toHaveBeenCalledWith('cobro.estado = :status', {
        status: 'PENDIENTE',
      });
    });

    it('should scope COBRADOR to allowedEtapaIds (defense in depth with tenant)', async () => {
      const qb = fullQb();
      mockRepo.createQueryBuilder.mockReturnValue(qb as any);

      await repo.findAllWithFilters(
        TENANT_ID,
        {},
        ['etapa-1', 'etapa-2'],
      );

      expect(qb.where).toHaveBeenCalledWith('cobro.tenantId = :tenantId', {
        tenantId: TENANT_ID,
      });
      expect(qb.andWhere).toHaveBeenCalledWith(
        'manzana.etapaId IN (:...allowedEtapaIds)',
        { allowedEtapaIds: ['etapa-1', 'etapa-2'] },
      );
    });

    it('should not leak rows when a etapa filter and allowed list are combined', async () => {
      const qb = fullQb();
      mockRepo.createQueryBuilder.mockReturnValue(qb as any);

      await repo.findAllWithFilters(
        TENANT_ID,
        { etapaId: 'etapa-9' },
        ['etapa-1'],
      );

      const andWhereArgs = qb.andWhere.mock.calls.map((c: any[]) => c[0]);
      expect(andWhereArgs).toContainEqual(
        'manzana.etapaId IN (:...allowedEtapaIds)',
      );
      expect(andWhereArgs).toContainEqual('manzana.etapaId = :etapaId');
    });
  });
});
