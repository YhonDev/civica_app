import { Test, TestingModule } from '@nestjs/testing';
import { GenerarTicketUseCase } from './generar-ticket.use-case';
import { TicketRepository } from '../../infrastructure/persistence/ticket.repository';
import { ResidenteRepository } from '../../../community/infrastructure/residente.repository';
import { Pago } from '../../domain/pago.entity';
import { Cobro } from '../../domain/cobro.entity';
import { Money } from '../../../shared/common/value-objects';

describe('GenerarTicketUseCase', () => {
  let useCase: GenerarTicketUseCase;

  const mockTicketRepo = {
    nextNumero: jest.fn().mockResolvedValue('TKT-2026-000001'),
    save: jest.fn().mockImplementation(async (ticket) => {
      ticket.id = 'ticket-uuid-1';
      return ticket;
    }),
  };

  const mockResidenteRepo = {
    findByIdWithRelations: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GenerarTicketUseCase,
        { provide: TicketRepository, useValue: mockTicketRepo },
        { provide: ResidenteRepository, useValue: mockResidenteRepo },
      ],
    }).compile();

    useCase = module.get<GenerarTicketUseCase>(GenerarTicketUseCase);
  });

  it('should snapshot residente and location data and save a TicketCobro', async () => {
    const mockResidente = {
      id: 'residente-1',
      nombre: 'Carlos Perez',
      documento: '12345678',
      tenencias: [
        {
          fechaFin: null,
          casa: {
            direccionInterna: 'Casa 102',
            manzana: {
              nombre: 'Manzana B',
              etapa: {
                nombre: 'Etapa 1',
              },
            },
          },
        },
      ],
    };
    mockResidenteRepo.findByIdWithRelations.mockResolvedValue(mockResidente);

    const pago = Pago.crear(
      'client-pay-1',
      'tenant-1',
      Money.ofCOP(50000),
      '2026-07-25',
      'cobrador-1',
      'residente-1',
    );
    pago.id = 'pago-1';

    const cobro = Cobro.crear(
      'residente-1',
      'tenant-1',
      'Cuota de Vigilancia - Julio',
      Money.ofCOP(50000),
      '2026-07-01',
      '2026-08-01',
      '2026-07-15',
    );
    cobro.id = 'cobro-1';

    const result = await useCase.execute({
      pago,
      cobrosAfectados: [cobro],
      cobradorNombre: 'Juan Cobrador',
    });

    expect(mockResidenteRepo.findByIdWithRelations).toHaveBeenCalledWith('residente-1');
    expect(mockTicketRepo.nextNumero).toHaveBeenCalledWith('tenant-1');
    expect(mockTicketRepo.save).toHaveBeenCalled();

    expect(result.id).toBe('ticket-uuid-1');
    expect(result.numero).toBe('TKT-2026-000001');
    expect(result.residenteNombre).toBe('Carlos Perez');
    expect(result.casaDireccion).toBe('Casa 102');
    expect(result.manzana).toBe('Manzana B');
    expect(result.etapa).toBe('Etapa 1');
    expect(result.cobradorNombre).toBe('Juan Cobrador');
    expect(result.monto).toBe(50000);
    expect(result.concepto).toBe('Cuota de Vigilancia - Julio');
  });

  it('should handle missing residente relations gracefully with fallback values', async () => {
    mockResidenteRepo.findByIdWithRelations.mockResolvedValue(null);

    const pago = Pago.crear(
      'client-pay-2',
      'tenant-1',
      Money.ofCOP(30000),
      '2026-07-25',
      'cobrador-1',
      'residente-unknown',
    );
    pago.id = 'pago-2';

    const result = await useCase.execute({
      pago,
      cobrosAfectados: [],
      cobradorNombre: 'Admin',
    });

    expect(result.residenteNombre).toBe('Residente desconocido');
    expect(result.casaDireccion).toBe('Sin dirección');
    expect(result.etapa).toBe('Sin etapa');
    expect(result.manzana).toBe('Sin manzana');
  });
});
