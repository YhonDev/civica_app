import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { BadRequestException, ConflictException } from '@nestjs/common';
import * as bcrypt from 'bcrypt';

import { CrearUsuarioUseCase } from './crear-usuario.use-case';
import { Usuario, RolUsuario } from '../../domain/usuario.entity';

jest.mock('bcrypt');

describe('CrearUsuarioUseCase', () => {
  let useCase: CrearUsuarioUseCase;
  let usuarioRepo: jest.Mocked<Repository<Usuario>>;

  const validParams = {
    username: 'juan.perez',
    password: 'securePass1',
    nombre: 'Juan Perez',
    rol: RolUsuario.COBRADOR,
    tenantId: 'tenant-1',
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CrearUsuarioUseCase,
        {
          provide: getRepositoryToken(Usuario),
          useValue: {
            findOne: jest.fn(),
            save: jest.fn(),
          },
        },
      ],
    }).compile();

    useCase = module.get<CrearUsuarioUseCase>(CrearUsuarioUseCase);
    usuarioRepo = module.get(getRepositoryToken(Usuario));
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  // ─── Validation ──────────────────────────────────────

  describe('validation', () => {
    it('should throw BadRequestException when username is too short', async () => {
      await expect(
        useCase.execute({ ...validParams, username: 'ab' }),
      ).rejects.toThrow(BadRequestException);
    });

    it('should throw BadRequestException when password is too short', async () => {
      await expect(
        useCase.execute({ ...validParams, password: '12345' }),
      ).rejects.toThrow(BadRequestException);
    });

    it('should throw BadRequestException when rol is invalid', async () => {
      await expect(
        useCase.execute({ ...validParams, rol: 'INVALID_ROLE' as RolUsuario }),
      ).rejects.toThrow(BadRequestException);
    });

    it('should throw BadRequestException when tenantId is empty', async () => {
      await expect(
        useCase.execute({ ...validParams, tenantId: '' }),
      ).rejects.toThrow(BadRequestException);
    });
  });

  // ─── Success ──────────────────────────────────────────

  describe('execute', () => {
    it('should create and save user with hashed password', async () => {
      usuarioRepo.findOne.mockResolvedValue(null);
      (bcrypt.hash as jest.Mock).mockResolvedValue('hashed-pass-123');

      const savedUser = Object.assign(new Usuario(), {
        id: 'usr-1',
        email: 'juan.perez',
        nombre: 'Juan Perez',
        rol: RolUsuario.COBRADOR,
        tenantId: 'tenant-1',
      });
      usuarioRepo.save.mockResolvedValue(savedUser);

      const result = await useCase.execute(validParams);

      expect(result).toEqual(savedUser);
      expect(usuarioRepo.findOne).toHaveBeenCalledWith({
        where: { email: 'juan.perez' },
      });
      expect(bcrypt.hash).toHaveBeenCalledWith('securePass1', 10);
      expect(usuarioRepo.save).toHaveBeenCalled();
    });

    it('should support optional residenteId', async () => {
      usuarioRepo.findOne.mockResolvedValue(null);
      (bcrypt.hash as jest.Mock).mockResolvedValue('hash');
      usuarioRepo.save.mockImplementation(async (u) => u as any);

      const result = await useCase.execute({
        ...validParams,
        residenteId: 'res-1',
        rol: RolUsuario.RESIDENTE,
      });

      expect(result.residenteId).toBe('res-1');
    });
  });

  // ─── Duplicate ────────────────────────────────────────

  describe('duplicate', () => {
    it('should throw ConflictException when username already exists', async () => {
      const existing = Object.assign(new Usuario(), { email: 'juan.perez' });
      usuarioRepo.findOne.mockResolvedValue(existing);

      await expect(useCase.execute(validParams)).rejects.toThrow(
        ConflictException,
      );

      expect(usuarioRepo.save).not.toHaveBeenCalled();
    });
  });
});
