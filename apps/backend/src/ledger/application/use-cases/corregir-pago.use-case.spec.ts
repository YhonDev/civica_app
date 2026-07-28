import { Test, TestingModule } from '@nestjs/testing';
import { DataSource } from 'typeorm';
import { CorregirPagoUseCase } from './corregir-pago.use-case';
import { PagoRepository } from '../../infrastructure/persistence/pago.repository';
import { CobroRepository } from '../../infrastructure/persistence/cobro.repository';
import { Pago, EstadoValidacionPago } from '../../domain/pago.entity';
import { Cobro } from '../../domain/cobro.entity';
import { Money } from '../../../shared/common/value-objects';

describe('CorregirPagoUseCase', () => {
  let useCase: CorregirPagoUseCase;

  const mockPagoRepo = {
    findById: jest.fn(),
    save: jest.fn(),
  };

  const mockCobroRepo = {
    findByResidente: jest.fn(),
    findMasAntiguoConSaldoLocked: jest.fn(),
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
  const USUARIO_ID = 'user-1';

  function crearPago(monto: number, estado = EstadoValidacionPago.PENDIENTE_REVISION): Pago {
    const pago = Pago.crear('pay-001', TENANT_ID, Money.ofCOP(monto), '2026-01-20', 'cobrador-1', RESIDENTE_ID);
    pago.id = 'pago-1';
    pago.estado = estado;
    return pago;
  }

  function crearCobro(monto: number, montoPagado = 0, fecha = '2026-01-01'): Cobro {
    const cobro = Cobro.crear(RESIDENTE_ID, TENANT_ID, 'Cuota Test', Money.ofCOP(monto), fecha, '2026-02-01', '2026-01-15');
    cobro.montoPagado = montoPagado;
    cobro.estado = montoPagado === 0 ? 'PENDIENTE' : montoPagado === monto ? 'PAGADA' : 'PARCIAL';
    return cobro;
  }

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CorregirPagoUseCase,
        { provide: DataSource, useValue: mockDataSource },
        { provide: PagoRepository, useValue: mockPagoRepo },
        { provide: CobroRepository, useValue: mockCobroRepo },
      ],
    }).compile();

    useCase = module.get<CorregirPagoUseCase>(CorregirPagoUseCase);
  });

  it('should throw NotFoundException if payment does not exist', async () => {
    mockPagoRepo.findById.mockResolvedValue(null);

    await expect(
      useCase.execute({
        pagoId: 'pago-1',
        nuevoMonto: 30000,
        motivo: 'Monto errado',
        usuarioId: USUARIO_ID,
        tenantId: TENANT_ID,
      }),
    ).rejects.toThrow(/no encontrado/);
  });

  it('should throw BadRequestException if payment state is not PENDIENTE_REVISION', async () => {
    const pago = crearPago(40000, EstadoValidacionPago.VALIDADO);
    mockPagoRepo.findById.mockResolvedValue(pago);

    await expect(
      useCase.execute({
        pagoId: 'pago-1',
        nuevoMonto: 30000,
        motivo: 'Monto errado',
        usuarioId: USUARIO_ID,
        tenantId: TENANT_ID,
      }),
    ).rejects.toThrow(/No se puede corregir un pago/);
  });

  it('should revert old payment amount and apply new amount successfully', async () => {
    const pago = crearPago(40000);
    const cobro = crearCobro(50000, 40000); // 40k pagados de 50k
    mockPagoRepo.findById.mockResolvedValue(pago);
    mockCobroRepo.findByResidente.mockResolvedValue([cobro]);
    
    // Al re-aplicar el nuevo monto (30000)
    mockCobroRepo.findMasAntiguoConSaldoLocked.mockResolvedValue(cobro);

    const result = await useCase.execute({
      pagoId: 'pago-1',
      nuevoMonto: 30000,
      motivo: 'Monto real confirmado',
      usuarioId: USUARIO_ID,
      tenantId: TENANT_ID,
    });

    expect(result.monto).toBe(30000);
    expect(cobro.montoPagado).toBe(30000);
    expect(cobro.estado).toBe('PARCIAL');
    expect(mockEntityManager.save).toHaveBeenCalled();
  });
});
