import { Test, TestingModule } from '@nestjs/testing';
import { Reflector } from '@nestjs/core';
import { SolicitudesController } from './solicitudes.controller';
import { SolicitudRepository } from '../persistence/solicitud.repository';
import { CobroRepository } from '../persistence/cobro.repository';
import { ActividadRepository } from '../../../notifications/domain/actividad.repository';
import { Usuario, RolUsuario } from '../../../iam/domain/usuario.entity';

describe('SolicitudesController', () => {
  let controller: SolicitudesController;
  let mockSolicitudRepo: any;
  let mockCobroRepo: any;

  const mockUser = Object.assign(
    Usuario.crear(
      'residente@test.com',
      'hash',
      'Residente Test',
      RolUsuario.RESIDENTE,
      'tenant-123',
    ),
    { id: 'usr-1' },
  );

  beforeEach(async () => {
    mockSolicitudRepo = {
      save: jest.fn(),
      findByUsuario: jest.fn(),
      findByTenant: jest.fn(),
      findPendingByTenant: jest.fn(),
      findById: jest.fn(),
    };

    mockCobroRepo = {
      findById: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [SolicitudesController],
      providers: [
        { provide: SolicitudRepository, useValue: mockSolicitudRepo },
        { provide: CobroRepository, useValue: mockCobroRepo },
        { provide: ActividadRepository, useValue: { save: jest.fn() } },
        { provide: Reflector, useValue: { get: jest.fn() } },
      ],
    }).compile();

    controller = module.get<SolicitudesController>(SolicitudesController);
  });

  describe('listar', () => {
    it('should call findByUsuario with user id and optional limit/offset', async () => {
      const mockResult = [{ id: 'sol-1' }];
      mockSolicitudRepo.findByUsuario.mockResolvedValue(mockResult);

      const result = await controller.listar(mockUser, 20, 10);

      expect(mockSolicitudRepo.findByUsuario).toHaveBeenCalledWith('usr-1', 20, 10);
      expect(result).toEqual(mockResult);
    });

    it('should work without pagination parameters', async () => {
      mockSolicitudRepo.findByUsuario.mockResolvedValue([]);

      const result = await controller.listar(mockUser);

      expect(mockSolicitudRepo.findByUsuario).toHaveBeenCalledWith('usr-1', undefined, undefined);
      expect(result).toEqual([]);
    });
  });

  describe('listarAdmin', () => {
    it('should call findByTenant with tenant id and optional pagination', async () => {
      mockSolicitudRepo.findByTenant.mockResolvedValue([]);

      await controller.listarAdmin('tenant-123', 50, 0);

      expect(mockSolicitudRepo.findByTenant).toHaveBeenCalledWith('tenant-123', 50, 0);
    });
  });
});
