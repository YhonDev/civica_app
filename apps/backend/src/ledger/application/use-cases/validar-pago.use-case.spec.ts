import { Test, TestingModule } from '@nestjs/testing';
import { DataSource } from 'typeorm';
import { ValidarPagoUseCase } from './validar-pago.use-case';
import { PagoRepository } from '../../infrastructure/persistence/pago.repository';
import { PagoCobroRepository } from '../../infrastructure/persistence/pago-cobro.repository';
import { Pago, EstadoValidacionPago } from '../../domain/pago.entity';
import { Cobro } from '../../domain/cobro.entity';
import { Money } from '../../../shared/common/value-objects';

describe('ValidarPagoUseCase', () => {
  let useCase: ValidarPagoUseCase;

  const mockPagoRepo = {
    findById: jest.fn(),
    save: jest.fn(),
  };

  const mockPagoCobroRepo = {
    findByPago: jest.fn(),
    save: jest.fn(),
  };

  let cobro: Cobro;

  const mockEntityManager = {
    save: jest.fn().mockImplementation(async (entity: any) => entity),
    findOne: jest.fn(),
    getRepository: jest.fn().mockReturnValue({
      find: jest.fn().mockImplementation(async () => [cobro]),
    }),
  };

  const mockDataSource = {
    transaction: jest
      .fn()
      .mockImplementation(
        async (cb: (em: typeof mockEntityManager) => Promise<any>) =>
          cb(mockEntityManager),
      ),
  };

  const TENANT_ID = 'tenant-1';
  const RESIDENTE_ID = 'residente-1';

  function crearPago(
    monto: number,
    estado = EstadoValidacionPago.PENDIENTE_REVISION,
  ): Pago {
    const pago = Pago.crear(
      'pay-001',
      TENANT_ID,
      Money.ofCOP(monto),
      '2026-01-20',
      'cobrador-1',
      RESIDENTE_ID,
    );
    pago.id = 'pago-1';
    pago.estado = estado;
    return pago;
  }

  function crearCobro(monto: number, montoPagado = 0): Cobro {
    const c = Cobro.crear(
      RESIDENTE_ID,
      TENANT_ID,
      'Cuota Test',
      Money.ofCOP(monto),
      '2026-01-01',
      '2026-02-01',
      '2026-12-15',
    );
    c.montoPagado = montoPagado;
    c.estado =
      montoPagado === 0
        ? 'PENDIENTE'
        : montoPagado === monto
          ? 'PAGADA'
          : 'PARCIAL';
    return c;
  }

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ValidarPagoUseCase,
        { provide: DataSource, useValue: mockDataSource },
        { provide: PagoRepository, useValue: mockPagoRepo },
        { provide: PagoCobroRepository, useValue: mockPagoCobroRepo },
      ],
    }).compile();

    useCase = module.get<ValidarPagoUseCase>(ValidarPagoUseCase);
  });

  it('should throw NotFoundException if payment belongs to another tenant', async () => {
    const pago = crearPago(40000);
    mockPagoRepo.findById.mockImplementation(async (_id, tenantId) =>
      tenantId === TENANT_ID ? pago : null,
    );

    await expect(
      useCase.execute({
        pagoId: 'pago-1',
        estado: EstadoValidacionPago.VALIDADO,
        tenantId: 'tenant-OTHER',
      }),
    ).rejects.toThrow(/no encontrado/);
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
    cobro = crearCobro(50000, 40000);
    mockPagoRepo.findById.mockResolvedValue(pago);
    // Sin vínculos pago_cobros => reverso legacy
    mockPagoCobroRepo.findByPago.mockResolvedValue([]);

    const result = await useCase.execute({
      pagoId: 'pago-1',
      estado: EstadoValidacionPago.RECHAZADO,
      tenantId: TENANT_ID,
    });

    expect(result.estado).toBe(EstadoValidacionPago.RECHAZADO);
    expect(result.cobroId).toBeNull();
    expect(cobro.montoPagado).toBe(0);
    expect(cobro.estado).toBe('PENDIENTE');
    expect(mockEntityManager.save).toHaveBeenCalledWith(Cobro, cobro);
  });
});
