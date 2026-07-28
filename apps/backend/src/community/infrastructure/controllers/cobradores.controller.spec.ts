import { Test, TestingModule } from '@nestjs/testing';

import { CobradoresController } from './cobradores.controller';
import { CrearCobradorUseCase } from '../../application/use-cases/crear-cobrador.use-case';

describe('CobradoresController', () => {
  let controller: CobradoresController;
  let crearCobradorUC: jest.Mocked<CrearCobradorUseCase>;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [CobradoresController],
      providers: [
        {
          provide: CrearCobradorUseCase,
          useValue: {
            execute: jest.fn(),
          },
        },
      ],
    }).compile();

    controller = module.get<CobradoresController>(CobradoresController);
    crearCobradorUC = module.get(CrearCobradorUseCase);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('crear', () => {
    it('should call crearCobradorUseCase with dto and tenantId', async () => {
      const expectedResult: any = {
        usuario: { id: 'usr-1', nombre: 'Carlos' },
        credenciales: { username: 'carlos.cobrador', password: 'carlos2026' },
      };
      crearCobradorUC.execute.mockResolvedValue(expectedResult);

      const result = await controller.crear(
        {
          nombre: 'Carlos Cobrador',
          telefono: '3001234567',
          etapaIds: ['etapa-1'],
        },
        'tenant-1',
      );

      expect(result).toEqual(expectedResult);
      expect(crearCobradorUC.execute).toHaveBeenCalledWith({
        nombre: 'Carlos Cobrador',
        telefono: '3001234567',
        tenantId: 'tenant-1',
        etapaIds: ['etapa-1'],
      });
    });

    it('should pass dto without optional fields when not provided', async () => {
      crearCobradorUC.execute.mockResolvedValue({
        usuario: { id: 'usr-2', nombre: 'Ana' } as any,
        credenciales: { username: 'ana.cobradora', password: 'ana2026' },
      });

      await controller.crear(
        {
          nombre: 'Ana Cobradora',
        },
        'tenant-2',
      );

      expect(crearCobradorUC.execute).toHaveBeenCalledWith({
        nombre: 'Ana Cobradora',
        tenantId: 'tenant-2',
      });
    });
  });
});
