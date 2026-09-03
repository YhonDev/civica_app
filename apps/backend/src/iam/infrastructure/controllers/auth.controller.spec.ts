import { Test, TestingModule } from '@nestjs/testing';

import { AuthController } from './auth.controller';
import { AuthService } from '../../../shared/auth/auth.service';
import { CrearUsuarioUseCase } from '../../application/use-cases/crear-usuario.use-case';
import { Usuario, RolUsuario } from '../../domain/usuario.entity';

describe('AuthController', () => {
  let controller: AuthController;
  let authService: jest.Mocked<AuthService>;
  let crearUsuarioUC: jest.Mocked<CrearUsuarioUseCase>;

  const mockUsuario = Object.assign(
    Usuario.crear(
      'test@test.com',
      'hash',
      'Test',
      RolUsuario.ADMIN,
      'tenant-1',
    ),
    { id: 'usr-1' },
  );

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [AuthController],
      providers: [
        {
          provide: AuthService,
          useValue: {
            validateUser: jest.fn(),
            login: jest.fn(),
            refreshToken: jest.fn(),
          },
        },
        {
          provide: CrearUsuarioUseCase,
          useValue: {
            execute: jest.fn(),
          },
        },
      ],
    }).compile();

    controller = module.get<AuthController>(AuthController);
    authService = module.get(AuthService);
    crearUsuarioUC = module.get(CrearUsuarioUseCase);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  // ─── Register ────────────────────────────────────────

  describe('register', () => {
    it('should call crearUsuarioUseCase with dto and tenantId', async () => {
      const dto = {
        username: 'nuevo.user',
        password: 'Pass123!',
        nombre: 'Nuevo Usuario',
        rol: RolUsuario.COBRADOR,
      };
      const expectedUser = Object.assign(new Usuario(), {
        id: 'usr-2',
        email: 'nuevo.user',
      });
      crearUsuarioUC.execute.mockResolvedValue(expectedUser);

      const result = await controller.register(dto, 'tenant-1');

      expect(result).toEqual(expectedUser);
      expect(crearUsuarioUC.execute).toHaveBeenCalledWith({
        username: 'nuevo.user',
        password: 'Pass123!',
        nombre: 'Nuevo Usuario',
        rol: RolUsuario.COBRADOR,
        tenantId: 'tenant-1',
        residenteId: undefined,
      });
    });

    it('should pass residenteId when provided', async () => {
      const dto = {
        username: 'residente.user',
        password: 'Pass123!',
        nombre: 'Residente',
        rol: RolUsuario.RESIDENTE,
        residenteId: 'res-1',
      };
      crearUsuarioUC.execute.mockResolvedValue(new Usuario());

      await controller.register(dto, 'tenant-1');

      expect(crearUsuarioUC.execute).toHaveBeenCalledWith({
        ...dto,
        tenantId: 'tenant-1',
      });
    });
  });

  // ─── Login ────────────────────────────────────────────

  describe('login', () => {
    it('should validate user and return login tokens', async () => {
      const loginResult = {
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        usuario: mockUsuario,
      };

      authService.validateUser.mockResolvedValue(mockUsuario);
      authService.login.mockResolvedValue(loginResult);

      const result = await controller.login({
        username: 'test@test.com',
        password: 'correct-password',
      });

      expect(result).toEqual(loginResult);
      expect(authService.validateUser).toHaveBeenCalledWith(
        'test@test.com',
        'correct-password',
      );
      expect(authService.login).toHaveBeenCalledWith(mockUsuario, {
        deviceId: undefined,
        deviceName: undefined,
        ipAddress: undefined,
        userAgent: undefined,
      });
    });
  });

  // ─── Refresh ──────────────────────────────────────────

  describe('refresh', () => {
    it('should call authService.refreshToken with dto.refreshToken', async () => {
      const refreshResult = {
        accessToken: 'new-access-token',
        refreshToken: 'new-refresh-token',
        usuario: mockUsuario,
      };
      authService.refreshToken.mockResolvedValue(refreshResult);

      const result = await controller.refresh({
        refreshToken: 'valid-refresh-token',
      });

      expect(result).toEqual(refreshResult);
      expect(authService.refreshToken).toHaveBeenCalledWith(
        'valid-refresh-token',
      );
    });
  });
});
