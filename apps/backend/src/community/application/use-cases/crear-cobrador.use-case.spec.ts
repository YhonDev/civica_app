import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { BadRequestException } from '@nestjs/common';
import * as bcrypt from 'bcrypt';

import { CrearCobradorUseCase } from './crear-cobrador.use-case';
import { GenerarCredencialesService } from '../../../iam/application/services/generar-credenciales.service';
import { Usuario, RolUsuario } from '../../../iam/domain/usuario.entity';

jest.mock('bcrypt');

describe('CrearCobradorUseCase', () => {
  let useCase: CrearCobradorUseCase;
  let usuarioRepo: jest.Mocked<Repository<Usuario>>;
  let generarCredenciales: jest.Mocked<GenerarCredencialesService>;
  let mockQueryRunner: any;

  beforeEach(async () => {
    mockQueryRunner = {
      connect: jest.fn(),
      startTransaction: jest.fn(),
      commitTransaction: jest.fn(),
      rollbackTransaction: jest.fn(),
      release: jest.fn(),
      manager: {
        save: jest.fn(),
        query: jest.fn(),
      },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CrearCobradorUseCase,
        GenerarCredencialesService,
        {
          provide: getRepositoryToken(Usuario),
          useValue: {
            findOne: jest.fn(),
          },
        },
        {
          provide: DataSource,
          useValue: {
            createQueryRunner: jest.fn(() => mockQueryRunner),
          },
        },
      ],
    }).compile();

    useCase = module.get<CrearCobradorUseCase>(CrearCobradorUseCase);
    usuarioRepo = module.get(getRepositoryToken(Usuario));
    generarCredenciales = module.get(GenerarCredencialesService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  // ─── Validation ──────────────────────────────────────

  describe('validation', () => {
    it('should throw BadRequestException when nombre is too short', async () => {
      await expect(
        useCase.execute({
          nombre: 'Ab',
          telefono: '3000000000',
          tenantId: 'tenant-1',
        }),
      ).rejects.toThrow(BadRequestException);

      expect(mockQueryRunner.connect).not.toHaveBeenCalled();
    });

    it('should throw BadRequestException when nombre is empty', async () => {
      await expect(
        useCase.execute({
          nombre: '',
          telefono: '3000000000',
          tenantId: 'tenant-1',
        }),
      ).rejects.toThrow(BadRequestException);
    });
  });

  // ─── Success ──────────────────────────────────────────

  describe('execute', () => {
    it('should create cobrador and return usuario + credenciales', async () => {
      jest.spyOn(generarCredenciales, 'generarUsernameCobrador')
        .mockReturnValue('juanperezcobrador');
      jest.spyOn(generarCredenciales, 'generarPasswordCobrador')
        .mockReturnValue('juanperez2026');
      usuarioRepo.findOne.mockResolvedValue(null);
      (bcrypt.hash as jest.Mock).mockResolvedValue('hashed-password');

      const savedUser = Usuario.crear(
        'juanperezcobrador',
        'hashed-password',
        'Juan Perez',
        RolUsuario.COBRADOR,
        'tenant-1',
      );
      Object.assign(savedUser, { id: 'user-1' });
      mockQueryRunner.manager.save.mockResolvedValue(savedUser);

      const result = await useCase.execute({
        nombre: 'Juan Perez',
        telefono: '3000000000',
        tenantId: 'tenant-1',
      });

      expect(result).toEqual({
        usuario: savedUser,
        credenciales: { username: 'juanperezcobrador', password: 'juanperez2026' },
      });
      expect(mockQueryRunner.connect).toHaveBeenCalled();
      expect(mockQueryRunner.startTransaction).toHaveBeenCalled();
      expect(mockQueryRunner.commitTransaction).toHaveBeenCalled();
      expect(mockQueryRunner.release).toHaveBeenCalled();
    });

    it('should assign etapas when etapaIds are provided', async () => {
      jest.spyOn(generarCredenciales, 'generarUsernameCobrador')
        .mockReturnValue('carloscobrador');
      jest.spyOn(generarCredenciales, 'generarPasswordCobrador')
        .mockReturnValue('carlos2026');
      usuarioRepo.findOne.mockResolvedValue(null);
      (bcrypt.hash as jest.Mock).mockResolvedValue('hashed-password');

      const savedUser = Usuario.crear(
        'carloscobrador',
        'hashed-password',
        'Carlos Lopez',
        RolUsuario.COBRADOR,
        'tenant-1',
      );
      Object.assign(savedUser, { id: 'user-2' });
      mockQueryRunner.manager.save.mockResolvedValue(savedUser);

      const result = await useCase.execute({
        nombre: 'Carlos Lopez',
        telefono: '3001112233',
        tenantId: 'tenant-1',
        etapaIds: ['etapa-1', 'etapa-2'],
      });

      expect(result.usuario.id).toBe('user-2');
      expect(mockQueryRunner.manager.query).toHaveBeenCalledTimes(2);
      expect(mockQueryRunner.manager.query).toHaveBeenNthCalledWith(
        1,
        expect.stringContaining('INSERT INTO asignaciones_etapa'),
        ['user-2', 'etapa-1', 'tenant-1'],
      );
      expect(mockQueryRunner.manager.query).toHaveBeenNthCalledWith(
        2,
        expect.stringContaining('INSERT INTO asignaciones_etapa'),
        ['user-2', 'etapa-2', 'tenant-1'],
      );
    });

    it('should throw BadRequestException when username already exists', async () => {
      jest.spyOn(generarCredenciales, 'generarUsernameCobrador')
        .mockReturnValue('existingcobrador');
      jest.spyOn(generarCredenciales, 'generarPasswordCobrador')
        .mockReturnValue('existing2026');

      const existingUser = Usuario.crear(
        'existingcobrador',
        'hash',
        'Existing',
        RolUsuario.COBRADOR,
        'tenant-1',
      );
      usuarioRepo.findOne.mockResolvedValue(existingUser);

      await expect(
        useCase.execute({
          nombre: 'Existing User',
          telefono: '3000000000',
          tenantId: 'tenant-1',
        }),
      ).rejects.toThrow(BadRequestException);

      expect(mockQueryRunner.connect).not.toHaveBeenCalled();
    });
  });

  // ─── Error handling ──────────────────────────────────

  describe('error handling', () => {
    it('should rollback transaction on save failure', async () => {
      jest.spyOn(generarCredenciales, 'generarUsernameCobrador')
        .mockReturnValue('juanperezcobrador');
      jest.spyOn(generarCredenciales, 'generarPasswordCobrador')
        .mockReturnValue('juanperez2026');
      usuarioRepo.findOne.mockResolvedValue(null);
      (bcrypt.hash as jest.Mock).mockResolvedValue('hashed-password');

      mockQueryRunner.manager.save.mockRejectedValue(new Error('DB error'));

      await expect(
        useCase.execute({
          nombre: 'Juan Perez',
          telefono: '3000000000',
          tenantId: 'tenant-1',
        }),
      ).rejects.toThrow('DB error');

      expect(mockQueryRunner.rollbackTransaction).toHaveBeenCalled();
      expect(mockQueryRunner.release).toHaveBeenCalled();
    });
  });
});
