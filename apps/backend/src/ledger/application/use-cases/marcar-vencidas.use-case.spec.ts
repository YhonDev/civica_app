import { Test, TestingModule } from '@nestjs/testing';
import { MarcarVencidasUseCase } from './marcar-vencidas.use-case';
import { CobroRepository } from '../../infrastructure/persistence/cobro.repository';
import { Cobro } from '../../domain/cobro.entity';
import { Money } from '../../../shared/common/value-objects';

describe('MarcarVencidasUseCase', () => {
  let useCase: MarcarVencidasUseCase;

  const mockCobroRepo = {
    findVencidas: jest.fn(),
    saveMany: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MarcarVencidasUseCase,
        { provide: CobroRepository, useValue: mockCobroRepo },
      ],
    }).compile();

    useCase = module.get<MarcarVencidasUseCase>(MarcarVencidasUseCase);
  });

  /** Creates a PENDIENTE cobro with a past date */
  function crearCobroVencido(overrides: Partial<Cobro> = {}): Cobro {
    const cobro = Cobro.crear(
      'residente-1',
      'tenant-1',
      'Cuota vencida',
      Money.ofCOP(40000),
      '2026-01-01',
      '2026-02-01',
      '2026-01-15',
    );
    Object.assign(cobro, overrides);
    return cobro;
  }

  it('should mark PENDIENTE cobros as VENCIDA', async () => {
    const cobro = crearCobroVencido();
    mockCobroRepo.findVencidas.mockResolvedValue([cobro]);
    mockCobroRepo.saveMany.mockResolvedValue([cobro]);

    const result = await useCase.execute();

    expect(result.marcadas).toBe(1);
    expect(cobro.estado).toBe('VENCIDA');
    expect(mockCobroRepo.saveMany).toHaveBeenCalledWith([cobro]);
  });

  it('should mark PARCIAL cobros as VENCIDA', async () => {
    const cobro = crearCobroVencido();
    cobro.aplicarPago(Money.ofCOP(15000)); // now PARCIAL
    expect(cobro.estado).toBe('PARCIAL');

    mockCobroRepo.findVencidas.mockResolvedValue([cobro]);
    mockCobroRepo.saveMany.mockResolvedValue([cobro]);

    const result = await useCase.execute();

    expect(result.marcadas).toBe(1);
    expect(cobro.estado).toBe('VENCIDA');
  });

  it('should NOT mark PAGADA cobros as VENCIDA', async () => {
    const cobro = crearCobroVencido();
    cobro.aplicarPago(Money.ofCOP(40000)); // now PAGADA
    expect(cobro.estado).toBe('PAGADA');

    // Even if findVencidas returns it (shouldn't, but defensively)
    mockCobroRepo.findVencidas.mockResolvedValue([cobro]);
    mockCobroRepo.saveMany.mockResolvedValue([cobro]);

    const result = await useCase.execute();

    expect(result.marcadas).toBe(1);
    // marcarVencida should not change PAGADA
    expect(cobro.estado).toBe('PAGADA');
  });

  it('should return 0 when no vencidas exist', async () => {
    mockCobroRepo.findVencidas.mockResolvedValue([]);

    const result = await useCase.execute();

    expect(result.marcadas).toBe(0);
    expect(mockCobroRepo.saveMany).not.toHaveBeenCalled();
  });

  it('should handle multiple cobros', async () => {
    const cobro1 = crearCobroVencido({ id: 'cobro-1' });
    const cobro2 = crearCobroVencido({ id: 'cobro-2' });
    const cobro3 = crearCobroVencido({ id: 'cobro-3' });

    mockCobroRepo.findVencidas.mockResolvedValue([cobro1, cobro2, cobro3]);
    mockCobroRepo.saveMany.mockResolvedValue([cobro1, cobro2, cobro3]);

    const result = await useCase.execute();

    expect(result.marcadas).toBe(3);
    expect(cobro1.estado).toBe('VENCIDA');
    expect(cobro2.estado).toBe('VENCIDA');
    expect(cobro3.estado).toBe('VENCIDA');
  });
});
