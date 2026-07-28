import { Test, TestingModule } from '@nestjs/testing';
import { DataSource } from 'typeorm';
import { CarteraViviendaResumenQuery } from './cartera-vivienda-resumen.query';

describe('CarteraViviendaResumenQuery', () => {
  let query: CarteraViviendaResumenQuery;

  const mockQueryBuilder = {
    select: jest.fn().mockReturnThis(),
    addSelect: jest.fn().mockReturnThis(),
    from: jest.fn().mockReturnThis(),
    innerJoin: jest.fn().mockReturnThis(),
    leftJoin: jest.fn().mockReturnThis(),
    where: jest.fn().mockReturnThis(),
    andWhere: jest.fn().mockReturnThis(),
    getRawMany: jest.fn(),
  };

  const mockDataSource = {
    createQueryBuilder: jest.fn().mockReturnValue(mockQueryBuilder),
  };

  const TENANT_ID = 'tenant-1';

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CarteraViviendaResumenQuery,
        { provide: DataSource, useValue: mockDataSource },
      ],
    }).compile();

    query = module.get<CarteraViviendaResumenQuery>(CarteraViviendaResumenQuery);
  });

  it('should return empty list when no houses exist', async () => {
    mockQueryBuilder.getRawMany.mockResolvedValue([]);

    const result = await query.execute(TENANT_ID);

    expect(result).toEqual([]);
    expect(mockDataSource.createQueryBuilder).toHaveBeenCalledTimes(1);
  });

  it('should calculate semáforo states correctly based on cobros', async () => {
    // 1. Mock houses
    mockQueryBuilder.getRawMany.mockResolvedValueOnce([
      {
        casaId: 'casa-101',
        direccionInterna: 'Casa 101',
        manzanaNombre: 'Manzana A',
        etapaNombre: 'Etapa 1',
        residenteNombre: 'Juan Perez',
        residenteId: 'res-1',
      },
      {
        casaId: 'casa-102',
        direccionInterna: 'Casa 102',
        manzanaNombre: 'Manzana A',
        etapaNombre: 'Etapa 1',
        residenteNombre: 'María Garcia',
        residenteId: 'res-2',
      },
    ]);

    // 2. Mock cobros
    const hoyStr = new Date().toISOString().split('T')[0];
    const pastDate = '2026-01-01'; // definitely in the past
    mockQueryBuilder.getRawMany.mockResolvedValueOnce([
      // Casa 101 has one pagada
      {
        casaId: 'casa-101',
        estado: 'PAGADA',
        monto: 40000,
        montoPagado: 40000,
        fechaVencimiento: pastDate,
      },
      // Casa 102 has one vencida
      {
        casaId: 'casa-102',
        estado: 'VENCIDA',
        monto: 40000,
        montoPagado: 0,
        fechaVencimiento: pastDate,
      },
    ]);

    const result = await query.execute(TENANT_ID);

    expect(result).toHaveLength(2);

    const c101 = result.find(c => c.casaId === 'casa-101')!;
    expect(c101.estadoMora).toBe('AL_DIA');
    expect(c101.totalCuotasPagadas).toBe(1);

    const c102 = result.find(c => c.casaId === 'casa-102')!;
    expect(c102.estadoMora).toBe('EN_MORA');
    expect(c102.totalCuotasVencidas).toBe(1);
    expect(c102.saldoMoraCentavos).toBe(40000);
  });
});
