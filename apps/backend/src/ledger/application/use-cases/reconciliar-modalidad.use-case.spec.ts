import { Test, TestingModule } from '@nestjs/testing';
import { ReconciliarModalidadUseCase } from './reconciliar-modalidad.use-case';
import { PlanDeCobroRepository } from '../../infrastructure/persistence/plan-de-cobro.repository';
import { PeriodoCobroRepository } from '../../infrastructure/persistence/periodo-cobro.repository';
import { CobroRepository } from '../../infrastructure/persistence/cobro.repository';
import { TarifaRepository } from '../../infrastructure/persistence/tarifa.repository';
import { EventsGateway } from '../../../notifications/events.gateway';

describe('ReconciliarModalidadUseCase', () => {
  let useCase: ReconciliarModalidadUseCase;
  let mockPlanRepo: any;
  let mockPeriodoRepo: any;
  let mockCobroRepo: any;
  let mockTarifaRepo: any;
  let mockEventsGateway: any;

  beforeEach(async () => {
    mockPlanRepo = {
      findByResidente: jest.fn(),
      save: jest.fn(),
    };

    mockPeriodoRepo = {
      findByPlanAndMonth: jest.fn(),
    };

    mockCobroRepo = {
      findByResidente: jest.fn(),
      delete: jest.fn(),
      saveMany: jest.fn(),
    };

    mockTarifaRepo = {
      findVigente: jest.fn(),
    };

    mockEventsGateway = {
      emitModalidadCambiada: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ReconciliarModalidadUseCase,
        { provide: PlanDeCobroRepository, useValue: mockPlanRepo },
        { provide: PeriodoCobroRepository, useValue: mockPeriodoRepo },
        { provide: CobroRepository, useValue: mockCobroRepo },
        { provide: TarifaRepository, useValue: mockTarifaRepo },
        { provide: EventsGateway, useValue: mockEventsGateway },
      ],
    }).compile();

    useCase = module.get<ReconciliarModalidadUseCase>(ReconciliarModalidadUseCase);
  });

  it('should be defined', () => {
    expect(useCase).toBeDefined();
  });

  it('should gracefully warn and return if no plan exists', async () => {
    mockPlanRepo.findByResidente.mockResolvedValue(null);

    await useCase.execute('residente-123', 'QUINCENAL');

    expect(mockPlanRepo.save).not.toHaveBeenCalled();
    expect(mockCobroRepo.saveMany).not.toHaveBeenCalled();
  });

  it('should update plan modality and emit real-time event when period exists', async () => {
    const mockPlan = {
      id: 'plan-123',
      tenantId: 'tenant-001',
      proyectoId: 'proyecto-001',
      modalidad: 'SEMANAL',
      fechaActivacion: '2026-01-01',
      valorMensual: 4000000,
    };

    const mockPeriodo = { id: 'periodo-123' };
    const mockCobros = [
      {
        id: 'cobro-1',
        periodoId: 'periodo-123',
        estado: 'PENDIENTE',
        monto: 1000000,
        montoPagado: 0,
        periodoInicio: '2026-08-01',
      },
    ];

    mockPlanRepo.findByResidente.mockResolvedValue(mockPlan);
    mockPeriodoRepo.findByPlanAndMonth.mockResolvedValue(mockPeriodo);
    mockCobroRepo.findByResidente.mockResolvedValue(mockCobros);

    await useCase.execute('residente-123', 'QUINCENAL');

    expect(mockPlanRepo.save).toHaveBeenCalledWith(expect.objectContaining({ modalidad: 'QUINCENAL' }));
    expect(mockCobroRepo.delete).toHaveBeenCalledWith('cobro-1');
    expect(mockCobroRepo.saveMany).toHaveBeenCalled();
    expect(mockEventsGateway.emitModalidadCambiada).toHaveBeenCalledWith({
      tenantId: 'tenant-001',
      residenteId: 'residente-123',
      nuevaModalidad: 'QUINCENAL',
    });
  });
});
