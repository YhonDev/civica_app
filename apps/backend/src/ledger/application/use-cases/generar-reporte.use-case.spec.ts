import { GenerarReporteUseCase } from './generar-reporte.use-case';

describe('GenerarReporteUseCase', () => {
  let useCase: GenerarReporteUseCase;
  let mockDataSource: any;
  let mockCobroRepo: any;
  let mockEtapaRepo: any;
  let mockProyectoRepo: any;
  let mockQueryBuilder: any;

  beforeEach(() => {
    mockQueryBuilder = {
      leftJoinAndSelect: jest.fn().mockReturnThis(),
      where: jest.fn().mockReturnThis(),
      andWhere: jest.fn().mockReturnThis(),
      getMany: jest.fn(),
    };

    mockCobroRepo = {
      createQueryBuilder: jest.fn().mockReturnValue(mockQueryBuilder),
    };

    mockEtapaRepo = {
      find: jest.fn(),
    };

    mockProyectoRepo = {
      findOne: jest.fn(),
    };

    mockDataSource = {
      getRepository: jest.fn((entity) => {
        if (entity.name === 'Etapa' || entity.tableName === 'etapas') {
          return mockEtapaRepo;
        }
        if (entity.name === 'Proyecto' || entity.tableName === 'proyectos') {
          return mockProyectoRepo;
        }
        return mockCobroRepo;
      }),
    };

    useCase = new GenerarReporteUseCase(mockDataSource as any);
  });

  it('debe generar reporte de recaudo agrupado por etapa y estado', async () => {
    mockEtapaRepo.find.mockResolvedValue([
      { id: 'etapa-1', nombre: 'Etapa 1' },
      { id: 'etapa-2', nombre: 'Etapa 2' },
    ]);

    mockQueryBuilder.getMany.mockResolvedValue([
      {
        id: 'cob-1',
        monto: 5000000, // 50.000 COP
        montoPagado: 5000000,
        estado: 'PAGADA',
        casa: { manzana: { etapa: { id: 'etapa-1', nombre: 'Etapa 1' } } },
      },
      {
        id: 'cob-2',
        monto: 3000000, // 30.000 COP
        montoPagado: 0,
        estado: 'PENDIENTE',
        casa: { manzana: { etapa: { id: 'etapa-1', nombre: 'Etapa 1' } } },
      },
      {
        id: 'cob-3',
        monto: 2000000, // 20.000 COP
        montoPagado: 0,
        estado: 'VENCIDA',
        residente: { casaActual: { manzana: { etapa: { id: 'etapa-2', nombre: 'Etapa 2' } } } },
      },
    ]);

    mockProyectoRepo.findOne.mockResolvedValue({ id: 'proy-1', tenantId: 'tenant-A' });

    const result = await useCase.execute({
      proyectoId: 'proy-1',
      mes: 7,
      anio: 2026,
      tenantId: 'tenant-A',
    });

    // Debe filtrar cobros por el tenant del llamador
    expect(mockQueryBuilder.andWhere).toHaveBeenCalledWith(
      'cobro.tenantId = :tenantId',
      { tenantId: 'tenant-A' },
    );

    expect(result.mes).toBe(7);
    expect(result.anio).toBe(2026);
    expect(result.totalRecaudado).toBe(50000);
    expect(result.totalPendiente).toBe(30000);
    expect(result.totalVencido).toBe(20000);
    expect(result.meta).toBe(100000);
    expect(result.porcentaje).toBe(50);

    expect(result.desglosePorEstado).toEqual({
      pagadasCount: 1,
      pendientesCount: 1,
      vencidasCount: 1,
    });

    expect(result.desglosePorEtapa).toHaveLength(2);
    expect(result.desglosePorEtapa[0]).toEqual({
      etapaId: 'etapa-1',
      etapaNombre: 'Etapa 1',
      totalRecaudado: 50000,
      totalPendiente: 30000,
      totalVencido: 0,
    });
    expect(result.desglosePorEtapa[1]).toEqual({
      etapaId: 'etapa-2',
      etapaNombre: 'Etapa 2',
      totalRecaudado: 0,
      totalPendiente: 0,
      totalVencido: 20000,
    });
  });

  it('debe filtrar por etapaId cuando se especifica en el DTO', async () => {
    mockEtapaRepo.find.mockResolvedValue([
      { id: 'etapa-1', nombre: 'Etapa 1' },
      { id: 'etapa-2', nombre: 'Etapa 2' },
    ]);

    mockQueryBuilder.getMany.mockResolvedValue([
      {
        id: 'cob-1',
        monto: 5000000,
        montoPagado: 5000000,
        estado: 'PAGADA',
        casa: { manzana: { etapa: { id: 'etapa-1', nombre: 'Etapa 1' } } },
      },
    ]);

    mockProyectoRepo.findOne.mockResolvedValue({ id: 'proy-1', tenantId: 'tenant-A' });

    const result = await useCase.execute({
      proyectoId: 'proy-1',
      mes: 7,
      anio: 2026,
      etapaId: 'etapa-1',
      tenantId: 'tenant-A',
    });

    expect(mockQueryBuilder.andWhere).toHaveBeenCalledWith(
      '(etapa.id = :etapaId OR etapaResidente.id = :etapaId)',
      { etapaId: 'etapa-1' },
    );
    expect(result.desglosePorEtapa).toHaveLength(1);
    expect(result.desglosePorEtapa[0].etapaId).toBe('etapa-1');
  });

  it('debe rechazar un proyecto de otro tenant (aislamiento multi-tenant)', async () => {
    mockEtapaRepo.find.mockResolvedValue([]);
    mockQueryBuilder.getMany.mockResolvedValue([]);
    // El proyecto pertenece a tenant-B, no al llamador (tenant-A)
    mockProyectoRepo.findOne.mockResolvedValue({ id: 'proy-1', tenantId: 'tenant-B' });

    await expect(
      useCase.execute({
        proyectoId: 'proy-1',
        mes: 7,
        anio: 2026,
        tenantId: 'tenant-A',
      }),
    ).rejects.toThrow(/Proyecto proy-1 no encontrado/);
  });

  it('debe filtrar los cobros por el tenant del llamador (el reporte de A no ve cobros de B)', async () => {
    mockEtapaRepo.find.mockResolvedValue([]);
    mockQueryBuilder.getMany.mockResolvedValue([]);

    const result = await useCase.execute({
      mes: 7,
      anio: 2026,
      tenantId: 'tenant-A',
    });

    expect(result).toBeDefined();
    expect(mockQueryBuilder.andWhere).toHaveBeenCalledWith(
      'cobro.tenantId = :tenantId',
      { tenantId: 'tenant-A' },
    );
    // Sin proyectoId no se consulta el repositorio de proyectos
    expect(mockProyectoRepo.findOne).not.toHaveBeenCalled();
  });
});
