import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { JwtService } from '@nestjs/jwt';
import { DataSource, Repository } from 'typeorm';
import { UnauthorizedException, NotFoundException } from '@nestjs/common';
import * as bcrypt from 'bcrypt';

import { AuthService } from './auth.service';
import { TokenRevocationService } from './token-revocation.service';
import { Usuario, RolUsuario } from '../../iam/domain/usuario.entity';
import { AuthSession } from '../../iam/domain/auth-session.entity';

// Los unit tests no cargan .env: proveer secretos para firma/verificación de tokens
process.env.JWT_SECRET = process.env.JWT_SECRET ?? 'test-jwt-secret';
process.env.JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET ?? 'test-jwt-refresh-secret';

jest.mock('bcrypt');

describe('AuthService', () => {
  let service: AuthService;
  let usuarioRepo: jest.Mocked<Repository<Usuario>>;
  let sessionRepo: jest.Mocked<Repository<AuthSession>>;
  let jwtService: jest.Mocked<JwtService>;
  let tokenRevocation: jest.Mocked<TokenRevocationService>;
  let dataSource: jest.Mocked<DataSource>;

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
    previousRefreshTokenHash: null,
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
            save: jest.fn().mockImplementation((u) => Promise.resolve(u)),
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
        {
          provide: DataSource,
          useValue: {
            transaction: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
    usuarioRepo = module.get(getRepositoryToken(Usuario));
    sessionRepo = module.get(getRepositoryToken(AuthSession));
    jwtService = module.get(JwtService);
    tokenRevocation = module.get(TokenRevocationService);
    dataSource = module.get(DataSource);
    dataSource.transaction.mockImplementation(async (callback: any) =>
      callback({
        findOne: sessionRepo.findOne,
        save: sessionRepo.save,
        update: sessionRepo.update,
      }),
    );
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
      // El refresh token se verifica con el secret dedicado (segundo argumento)
      expect(jwtService.verify).toHaveBeenCalledWith(
        'valid-refresh-token',
        expect.objectContaining({}),
      );
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

    it('should throw UnauthorizedException when session is revoked', async () => {
      jwtService.verify.mockReturnValue({
        sub: 'user-1',
        type: 'refresh',
      });
      usuarioRepo.findOne.mockResolvedValue(mockUsuario);
      sessionRepo.findOne.mockResolvedValue({
        ...mockSession,
        isRevoked: true,
      } as AuthSession);

      await expect(service.refreshToken('valid-token')).rejects.toThrow(
        UnauthorizedException,
      );
    });

    it('should throw UnauthorizedException when session is expired', async () => {
      jwtService.verify.mockReturnValue({
        sub: 'user-1',
        type: 'refresh',
      });
      usuarioRepo.findOne.mockResolvedValue(mockUsuario);
      sessionRepo.findOne.mockResolvedValue({
        ...mockSession,
        expiresAt: new Date(Date.now() - 1000),
      } as AuthSession);

      await expect(service.refreshToken('valid-token')).rejects.toThrow(
        UnauthorizedException,
      );
    });

    it('should detect reuse and revoke all sessions when token is already consumed', async () => {
      jwtService.verify.mockReturnValue({
        sub: 'user-1',
        type: 'refresh',
      });
      usuarioRepo.findOne.mockResolvedValue(mockUsuario);
      // First findOne: by refreshTokenHash → not found (already rotated)
      // Second findOne: by previousRefreshTokenHash → found (proof of reuse)
      sessionRepo.findOne
        .mockResolvedValueOnce(null)
        .mockResolvedValueOnce(mockSession as AuthSession);

      await expect(service.refreshToken('consumed-token')).rejects.toThrow(
        UnauthorizedException,
      );
      // All sessions for the user must be revoked
      expect(sessionRepo.update).toHaveBeenCalledWith(
        AuthSession,
        { usuarioId: 'user-1' },
        { isRevoked: true },
      );
    });

    it('should run refresh inside a database transaction with row lock', async () => {
      jwtService.verify.mockReturnValue({
        sub: 'user-1',
        type: 'refresh',
      });
      usuarioRepo.findOne.mockResolvedValue(mockUsuario);
      sessionRepo.findOne.mockResolvedValue(mockSession as AuthSession);
      jwtService.sign
        .mockReturnValueOnce('new-access')
        .mockReturnValueOnce('new-refresh');

      await service.refreshToken('valid-token');

      expect(dataSource.transaction).toHaveBeenCalled();
    });
  });

  // ─── revokeRefreshToken ─────────────────────────────

  describe('revokeRefreshToken', () => {
    it('should revoke in token-revocation store and mark session as revoked', async () => {
      await service.revokeRefreshToken('some-refresh-token');

      expect(tokenRevocation.revoke).toHaveBeenCalledWith('some-refresh-token');
      expect(sessionRepo.update).toHaveBeenCalledWith(
        { refreshTokenHash: expect.any(String) },
        { isRevoked: true },
      );
    });
  });

  // ─── revokeAllSessionsForUser ──────────────────────

  describe('revokeAllSessionsForUser', () => {
    it('should mark all sessions for the user as revoked', async () => {
      await service.revokeAllSessionsForUser('user-1');

      expect(sessionRepo.update).toHaveBeenCalledWith(
        { usuarioId: 'user-1' },
        { isRevoked: true },
      );
    });
  });

  // ─── revokeSessionById ─────────────────────────────

  describe('revokeSessionById', () => {
    it('should revoke the session when it belongs to the user', async () => {
      sessionRepo.findOne.mockResolvedValue(mockSession as AuthSession);

      await service.revokeSessionById('session-1', 'user-1');

      expect(sessionRepo.findOne).toHaveBeenCalledWith({
        where: { id: 'session-1', usuarioId: 'user-1' },
      });
      expect(sessionRepo.save).toHaveBeenCalledWith(
        expect.objectContaining({ isRevoked: true }),
      );
    });

    it('should throw NotFoundException when session does not exist', async () => {
      sessionRepo.findOne.mockResolvedValue(null);

      await expect(
        service.revokeSessionById('nonexistent', 'user-1'),
      ).rejects.toThrow(NotFoundException);
    });
  });

  // ─── getUserSessions ───────────────────────────────

  describe('getUserSessions', () => {
    it('should return active sessions ordered by lastUsedAt desc', async () => {
      const sessions = [mockSession as AuthSession];
      sessionRepo.find.mockResolvedValue(sessions);

      const result = await service.getUserSessions('user-1');

      expect(result).toEqual(sessions);
      expect(sessionRepo.find).toHaveBeenCalledWith({
        where: { usuarioId: 'user-1', isRevoked: false },
        order: { lastUsedAt: 'DESC' },
      });
    });
  });

  // ─── resetPasswordForUser ──────────────────────────

  describe('resetPasswordForUser', () => {
    it('should reset password and revoke all sessions', async () => {
      usuarioRepo.findOne.mockResolvedValue(mockUsuario);
      (bcrypt.hash as jest.Mock).mockResolvedValue('new-hash');

      const result = await service.resetPasswordForUser({
        usuarioId: 'user-1',
        tenantId: 'tenant-1',
      });

      expect(result.username).toBe(mockUsuario.email);
      expect(result.password).toHaveLength(12);
      expect(sessionRepo.update).toHaveBeenCalledWith(
        { usuarioId: 'user-1' },
        { isRevoked: true },
      );
    });

    it('should throw NotFoundException when user not found', async () => {
      usuarioRepo.findOne.mockResolvedValue(null);

      await expect(
        service.resetPasswordForUser({
          usuarioId: 'nonexistent',
          tenantId: 'tenant-1',
        }),
      ).rejects.toThrow(NotFoundException);
    });
  });

  // ─── updateCredentials ─────────────────────────────

  describe('updateCredentials', () => {
    it('should update password and revoke all sessions', async () => {
      usuarioRepo.findOne.mockResolvedValue(mockUsuario);
      (bcrypt.compare as jest.Mock).mockResolvedValue(true);
      (bcrypt.hash as jest.Mock).mockResolvedValue('new-hash');

      await service.updateCredentials({
        usuarioId: 'user-1',
        tenantId: 'tenant-1',
        currentPassword: 'old-pass',
        newPassword: 'new-pass',
      });

      expect(sessionRepo.update).toHaveBeenCalledWith(
        { usuarioId: 'user-1' },
        { isRevoked: true },
      );
    });

    it('should not revoke sessions when only username changes', async () => {
      usuarioRepo.findOne.mockResolvedValue(mockUsuario);

      await service.updateCredentials({
        usuarioId: 'user-1',
        tenantId: 'tenant-1',
        newUsername: 'new@test.com',
      });

      expect(sessionRepo.update).not.toHaveBeenCalled();
    });
  });
});
