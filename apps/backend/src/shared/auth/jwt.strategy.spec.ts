import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UnauthorizedException } from '@nestjs/common';

import { JwtStrategy } from './jwt.strategy';
import { Usuario, RolUsuario } from '../../iam/domain/usuario.entity';

describe('JwtStrategy', () => {
  let strategy: JwtStrategy;
  let usuarioRepo: jest.Mocked<Repository<Usuario>>;

  const mockUsuario = Usuario.crear(
    'test@test.com',
    'hash',
    'Test User',
    RolUsuario.COBRADOR,
    'tenant-1',
  );
  Object.assign(mockUsuario, { id: 'user-1' });

  const mockPayload = {
    sub: 'user-1',
    email: 'test@test.com',
    rol: 'COBRADOR',
    tenantId: 'tenant-1',
  };

  beforeEach(async () => {
    // Reset env so the strategy uses the dev secret
    process.env.JWT_SECRET = 'test-secret';

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        JwtStrategy,
        {
          provide: getRepositoryToken(Usuario),
          useValue: {
            findOne: jest.fn(),
          },
        },
      ],
    }).compile();

    strategy = module.get<JwtStrategy>(JwtStrategy);
    usuarioRepo = module.get(getRepositoryToken(Usuario));
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('validate', () => {
    it('should return user when payload is valid and user is active', async () => {
      usuarioRepo.findOne.mockResolvedValue(mockUsuario);

      const result = await strategy.validate(mockPayload);

      expect(result).toEqual(mockUsuario);
      expect(usuarioRepo.findOne).toHaveBeenCalledWith({
        where: { id: 'user-1' },
      });
    });

    it('should throw UnauthorizedException when user is not found', async () => {
      usuarioRepo.findOne.mockResolvedValue(null);

      await expect(strategy.validate(mockPayload)).rejects.toThrow(
        UnauthorizedException,
      );
    });

    it('should throw UnauthorizedException when user is inactive', async () => {
      const inactiveUser = Usuario.crear(
        'inactive@test.com',
        'hash',
        'Inactive',
        RolUsuario.COBRADOR,
        'tenant-1',
      );
      Object.assign(inactiveUser, { id: 'user-2', activo: false });
      usuarioRepo.findOne.mockResolvedValue(inactiveUser);

      await expect(strategy.validate(mockPayload)).rejects.toThrow(
        UnauthorizedException,
      );
    });
  });
});
