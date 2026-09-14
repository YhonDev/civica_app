import { Test, TestingModule } from '@nestjs/testing';
import { PagoRepository } from './pago.repository';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Pago } from '../../domain/pago.entity';

describe('PagoRepository', () => {
  let repo: PagoRepository;

  const mockQueryBuilder = {
    select: jest.fn().mockReturnThis(),
    addSelect: jest.fn().mockReturnThis(),
    where: jest.fn().mockReturnThis(),
    andWhere: jest.fn().mockReturnThis(),
    groupBy: jest.fn().mockReturnThis(),
    orderBy: jest.fn().mockReturnThis(),
    getRawOne: jest.fn(),
    getRawMany: jest.fn(),
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
        PagoRepository,
        {
          provide: getRepositoryToken(Pago),
          useValue: mockRepo,
        },
      ],
    }).compile();

    repo = module.get<PagoRepository>(PagoRepository);
    mockRepo.createQueryBuilder.mockReturnValue(mockQueryBuilder);
    mockQueryBuilder.select.mockReturnThis();
    mockQueryBuilder.andWhere.mockReturnThis();
    mockQueryBuilder.groupBy.mockReturnThis();
    mockQueryBuilder.orderBy.mockReturnThis();
  });

  describe('findByCobradorToday()', () => {
    it('filtra en base de datos usando fechaPago de hoy directamente', async () => {
      const hoy = new Date();
      const hoyStr = `${hoy.getFullYear()}-${String(hoy.getMonth() + 1).padStart(2, '0')}-${String(hoy.getDate()).padStart(2, '0')}`;

      mockRepo.find.mockResolvedValue([
        { id: 'p1', monto: 15000, fechaPago: hoyStr },
        { id: 'p2', monto: 20000, fechaPago: hoyStr },
      ]);

      const result = await repo.findByCobradorToday('cob-1', TENANT_ID);

      expect(mockRepo.find).toHaveBeenCalledWith({
        where: {
          cobradorId: 'cob-1',
          tenantId: TENANT_ID,
          fechaPago: hoyStr,
        },
        order: { fechaPago: 'DESC' },
      });
      expect(result.count).toBe(2);
      expect(result.total).toBe(35000);
      expect(result.pagos).toHaveLength(2);
    });
  });

  describe('sumMontoLast12Months()', () => {
    it('ejecuta agregación SQL agrupando por año y mes', async () => {
      mockQueryBuilder.getRawMany.mockResolvedValue([
        { anio: 2026, mes: 5, recaudo: '100000' },
        { anio: 2026, mes: 6, recaudo: '150000' },
      ]);

      const result = await repo.sumMontoLast12Months(
        TENANT_ID,
        '2025-06-01',
        '2026-06-01',
      );

      expect(mockRepo.createQueryBuilder).toHaveBeenCalledWith('pago');
      expect(mockQueryBuilder.andWhere).toHaveBeenCalledWith(
        'pago.fecha_pago >= :start AND pago.fecha_pago < :end',
        { start: '2025-06-01', end: '2026-06-01' },
      );
      expect(result).toEqual([
        { anio: 2026, mes: 5, recaudo: 100000 },
        { anio: 2026, mes: 6, recaudo: 150000 },
      ]);
    });
  });

  describe('paginación en findByPropietario() y findByCobrador()', () => {
    it('aplica take y skip en findByPropietario cuando se especifican', async () => {
      mockRepo.find.mockResolvedValue([]);
      await repo.findByPropietario('res-1', TENANT_ID, {
        limit: 10,
        offset: 20,
      });

      expect(mockRepo.find).toHaveBeenCalledWith(
        expect.objectContaining({
          take: 10,
          skip: 20,
        }),
      );
    });

    it('aplica take y skip en findByCobrador cuando se especifican', async () => {
      mockRepo.find.mockResolvedValue([]);
      await repo.findByCobrador('cob-1', TENANT_ID, { limit: 25, offset: 50 });

      expect(mockRepo.find).toHaveBeenCalledWith(
        expect.objectContaining({
          take: 25,
          skip: 50,
        }),
      );
    });
  });
});
