import { Test, TestingModule } from '@nestjs/testing';
import { DataSource } from 'typeorm';
import { ValidarPagoUseCase } from './validar-pago.use-case';
import { PagoRepository } from '../../infrastructure/persistence/pago.repository';
import { CobroRepository } from '../../infrastructure/persistence/cobro.repository';
import { Pago, EstadoValidacionPago } from '../../domain/pago.entity';
import { Cobro } from '../../domain/cobro.entity';
import { Money } from '../../../shared/common/value-objects';

describe('ValidarPagoUseCase', () => {
  let useCase: ValidarPagoUseCase;

  const mockPagoRepo = {
    findById: jest.fn(),
    save: jest.fn(),
  };

  const mockCobroRepo = {
    findByResidente: jest.fn(),
    save: jest.fn(),
  };

  const mockEntityManager = {
    save: jest.fn().mockImplementation(async (entity: any) => entity),
  };

  const mockDataSource = {
    transaction: jest.fn().mockImplementation(
      async (cb: (em: typeof mockEntityManager) => Promise<any>) => cb(mockEntityManager),
    ),
  };

  const TENANT_ID = 'tenant-1';
  const RESIDENTE_ID = 'residente-1';

  function crearPago(monto: number, estado = EstadoValidacionPago.PENDIENTE_REVISION): Pago {
    const pago = Pago.crear('pay-001', TENANT_ID, Money.ofCOP(monto), '2026-01-20', 'cobrador-1', RESIDENTE_ID);
    pago.id = 'pago-1';
    pago.estado = estado;
    return pago;
  }

  function crearCobro(monto: number, montoPagado = 0): Cobro {
    const cobro = Cobro.crear(RESIDENTE_ID, TENANT_ID, 'Cuota Test', Money.ofCOP(monto), '2026-01-01', '2026-02-01', '2026-12-15');
    cobro.montoPagado = montoPagado;
    cobro.estado = montoPagado === 0 ? 'PENDIENTE' : montoPagado === monto ? 'PAGADA' : 'PARCIAL';
    return cobro;
  }

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ValidarPagoUseCase,
        { provide: DataSource, useValue: mockDataSource },
        { provide: PagoRepository, useValue: mockPagoRepo },
        { provide: CobroRepository, useValue: mockCobroRepo },
      ],
    }).compile();

    useCase = module.get<ValidarPagoUseCase>(ValidarPagoUseCase);
  });

  it('should change state to VALIDADO successfully', async () => {
    const pago = crearPago(40000);
    mockPagoRepo.findById.mockResolvedValue(pago);

    const result = await useCase.execute({
      pagoId: 'pago-1',
      estado: EstadoValidacionPago.VALIDADO,
      tenantId: TENANT_ID,
    });

    expect(result.estado).toBe(EstadoValidacionPago.VALIDADO);
    expect(mockEntityManager.save).toHaveBeenCalledWith(pago);
  });

  it('should change state to RECHAZADO and revert abonos successfully', async () => {
    const pago = crearPago(40000);
    const cobro = crearCobro(50000, 40000);
    mockPagoRepo.findById.mockResolvedValue(pago);
    mockCobroRepo.findByResidente.mockResolvedValue([cobro]);

    const result = await useCase.execute({
      pagoId: 'pago-1',
      estado: EstadoValidacionPago.RECHAZADO,
      tenantId: TENANT_ID,
    });

    expect(result.estado).toBe(EstadoValidacionPago.RECHAZADO);
    expect(result.cobroId).toBeNull();
    expect(cobro.montoPagado).toBe(0);
    expect(cobro.estado).toBe('PENDIENTE');
    expect(mockEntityManager.save).toHaveBeenCalledWith(cobro);
  });
});
