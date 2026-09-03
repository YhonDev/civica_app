import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { JwtService } from '@nestjs/jwt';
import { Repository } from 'typeorm';
import { UnauthorizedException, NotFoundException } from '@nestjs/common';
import * as bcrypt from 'bcrypt';

import { AuthService } from './auth.service';
import { TokenRevocationService } from './token-revocation.service';
import { Usuario, RolUsuario } from '../../iam/domain/usuario.entity';
import { AuthSession } from '../../iam/domain/auth-session.entity';

jest.mock('bcrypt');

describe('AuthService', () => {
  let service: AuthService;
  let usuarioRepo: jest.Mocked<Repository<Usuario>>;
  let sessionRepo: jest.Mocked<Repository<AuthSession>>;
  let jwtService: jest.Mocked<JwtService>;
  let tokenRevocation: jest.Mocked<TokenRevocationService>;

  const mockUsuario = Usuario.crear(
    'test@test.com',
    'hashed-password',
    'Test User',
    RolUsuario.ADMIN,
    'tenant-1',
  );
  Object.assign(mockUsuario, { id: 'user-1' });

  const mockSession: Partial<AuthSession> = {
    id: 'session-1',
    usuarioId: 'user-1',
    refreshTokenHash: 'mocked-hash',
    isRevoked: false,
    expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
    lastUsedAt: new Date(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        {
          provide: getRepositoryToken(Usuario),
          useValue: {
            findOne: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(AuthSession),
          useValue: {
            findOne: jest.fn(),
            save: jest.fn().mockImplementation((s) => Promise.resolve(s)),
            update: jest.fn().mockResolvedValue(undefined),
            find: jest.fn(),
          },
        },
        {
          provide: JwtService,
          useValue: {
            sign: jest.fn(),
            verify: jest.fn(),
          },
        },
        {
          provide: TokenRevocationService,
          useValue: {
            revoke: jest.fn().mockResolvedValue(undefined),
            isRevoked: jest.fn().mockResolvedValue(false),
          },
        },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
    usuarioRepo = module.get(getRepositoryToken(Usuario));
    sessionRepo = module.get(getRepositoryToken(AuthSession));
    jwtService = module.get(JwtService);
    tokenRevocation = module.get(TokenRevocationService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  // ─── validateUser ────────────────────────────────────

  describe('validateUser', () => {
    it('should return user when credentials are valid', async () => {
      usuarioRepo.findOne.mockResolvedValue(mockUsuario);
      (bcrypt.compare as jest.Mock).mockResolvedValue(true);

      const result = await service.validateUser(
        'test@test.com',
        'correct-password',
      );

      expect(result).toEqual(mockUsuario);
      expect(usuarioRepo.findOne).toHaveBeenCalledWith({
        where: { email: 'test@test.com' },
      });
      expect(bcrypt.compare).toHaveBeenCalledWith(
        'correct-password',
        'hashed-password',
      );
    });

    it('should throw UnauthorizedException when user not found', async () => {
      usuarioRepo.findOne.mockResolvedValue(null);

      await expect(
        service.validateUser('unknown@test.com', 'any-password'),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('should throw UnauthorizedException when password is wrong', async () => {
      usuarioRepo.findOne.mockResolvedValue(mockUsuario);
      (bcrypt.compare as jest.Mock).mockResolvedValue(false);

      await expect(
        service.validateUser('test@test.com', 'wrong-password'),
      ).rejects.toThrow(UnauthorizedException);
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
      (bcrypt.compare as jest.Mock).mockResolvedValue(true);

      await expect(
        service.validateUser('inactive@test.com', 'any-password'),
      ).rejects.toThrow(UnauthorizedException);
    });
  });

  // ─── login ────────────────────────────────────────────

  describe('login', () => {
    it('should return accessToken, refreshToken and user and create a session', async () => {
      jwtService.sign
        .mockReturnValueOnce('access-token-1')
        .mockReturnValueOnce('refresh-token-1');

      const result = await service.login(mockUsuario);

      expect(result).toEqual({
        accessToken: 'access-token-1',
        refreshToken: 'refresh-token-1',
        usuario: mockUsuario,
      });

      expect(jwtService.sign).toHaveBeenCalledTimes(2);
      expect(jwtService.sign).toHaveBeenNthCalledWith(
        1,
        {
          sub: mockUsuario.id,
          email: mockUsuario.email,
          rol: mockUsuario.rol,
          tenantId: mockUsuario.tenantId,
        },
        { expiresIn: '15m' },
      );
      expect(sessionRepo.save).toHaveBeenCalled();
    });
  });

  // ─── refreshToken ─────────────────────────────────────

  describe('refreshToken', () => {
    it('should return new token pair and rotate session when refresh token is valid', async () => {
      jwtService.verify.mockReturnValue({
        sub: 'user-1',
        type: 'refresh',
      });
      usuarioRepo.findOne.mockResolvedValue(mockUsuario);
      sessionRepo.findOne.mockResolvedValue(mockSession as AuthSession);
      jwtService.sign
        .mockReturnValueOnce('new-access-token')
        .mockReturnValueOnce('new-refresh-token');

      const result = await service.refreshToken('valid-refresh-token');

      expect(result).toEqual({
        accessToken: 'new-access-token',
        refreshToken: 'new-refresh-token',
        usuario: mockUsuario,
      });
      expect(jwtService.verify).toHaveBeenCalledWith('valid-refresh-token');
      expect(sessionRepo.save).toHaveBeenCalled();
    });

    it('should throw UnauthorizedException when token is not refresh type', async () => {
      jwtService.verify.mockReturnValue({
        sub: 'user-1',
        type: 'access',
      });

      await expect(service.refreshToken('access-token')).rejects.toThrow(
        UnauthorizedException,
      );
    });

    it('should throw NotFoundException when user not found', async () => {
      jwtService.verify.mockReturnValue({
        sub: 'nonexistent',
        type: 'refresh',
      });
      usuarioRepo.findOne.mockResolvedValue(null);

      await expect(service.refreshToken('valid-token')).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should throw UnauthorizedException when session is not found or revoked', async () => {
      jwtService.verify.mockReturnValue({
        sub: 'user-1',
        type: 'refresh',
      });
      usuarioRepo.findOne.mockResolvedValue(mockUsuario);
      sessionRepo.findOne.mockResolvedValue(null);

      await expect(service.refreshToken('valid-token')).rejects.toThrow(
        UnauthorizedException,
      );
    });
  });
});
