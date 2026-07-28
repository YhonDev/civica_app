import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';

import { UsuariosController } from './usuarios.controller';
import { AsignarEtapaUseCase } from '../../application/use-cases/asignar-etapa.use-case';
import { Usuario, RolUsuario } from '../../domain/usuario.entity';
import { AsignacionEtapa } from '../../domain/asignacion-etapa.entity';

jest.mock('bcrypt');

describe('UsuariosController', () => {
  let controller: UsuariosController;
  let usuarioRepo: jest.Mocked<Repository<Usuario>>;
  let asignacionRepo: jest.Mocked<Repository<AsignacionEtapa>>;
  let asignarEtapaUC: jest.Mocked<AsignarEtapaUseCase>;

  const mockAdmin = Object.assign(
    Usuario.crear('admin@test.com', 'hash', 'Admin', RolUsuario.ADMIN, 'tenant-1'),
    { id: 'admin-1' },
  );
  const mockCobrador = Object.assign(
    Usuario.crear('cob@test.com', 'hash', 'Cobrador', RolUsuario.COBRADOR, 'tenant-1'),
    { id: 'cob-1' },
  );
  const mockOtherCobrador = Object.assign(
    Usuario.crear('other@test.com', 'hash', 'Otro', RolUsuario.COBRADOR, 'tenant-1'),
    { id: 'cob-2' },
  );

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [UsuariosController],
      providers: [
        {
          provide: getRepositoryToken(AsignacionEtapa),
          useValue: {
            find: jest.fn(),
            delete: jest.fn(),
            save: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(Usuario),
          useValue: {
            find: jest.fn(),
            findOne: jest.fn(),
            save: jest.fn(),
          },
        },
        {
          provide: AsignarEtapaUseCase,
          useValue: {
            execute: jest.fn(),
          },
        },
      ],
    }).compile();

    controller = module.get<UsuariosController>(UsuariosController);
    usuarioRepo = module.get(getRepositoryToken(Usuario));
    asignacionRepo = module.get(getRepositoryToken(AsignacionEtapa));
    asignarEtapaUC = module.get(AsignarEtapaUseCase);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  // ─── listarResidentes ─────────────────────────────────

  describe('listarResidentes', () => {
    it('should return mapped resident users', async () => {
      const users = [
        Object.assign(
          Usuario.crear('res1@test.com', 'hash', 'Residente A', RolUsuario.RESIDENTE, 'tenant-1'),
          { id: 'usr-1', residenteId: 'res-1', activo: true, createdAt: new Date() },
        ),
        Object.assign(
          Usuario.crear('res2@test.com', 'hash', 'Residente B', RolUsuario.RESIDENTE, 'tenant-1'),
          { id: 'usr-2', residenteId: 'res-2', activo: true, createdAt: new Date() },
        ),
      ];
      usuarioRepo.find.mockResolvedValue(users);

      const result = await controller.listarResidentes('tenant-1');

      expect(result).toHaveLength(2);
      expect(result[0]).toHaveProperty('email');
      expect(result[0]).toHaveProperty('nombre');
      expect(result[0]).toHaveProperty('residenteId');
      expect(result[0]).not.toHaveProperty('passwordHash');
      expect(usuarioRepo.find).toHaveBeenCalledWith({
        where: { tenantId: 'tenant-1', rol: RolUsuario.RESIDENTE },
        order: { nombre: 'ASC' },
      });
    });
  });

  // ─── listar ───────────────────────────────────────────

  describe('listar', () => {
    it('should return cobradores with asignaciones', async () => {
      const cobradores = [mockCobrador];
      usuarioRepo.find.mockResolvedValue(cobradores);

      const result = await controller.listar('tenant-1');

      expect(result).toEqual(cobradores);
      expect(usuarioRepo.find).toHaveBeenCalledWith({
        where: { tenantId: 'tenant-1', rol: RolUsuario.COBRADOR },
        relations: { asignaciones: { etapa: true } },
      });
    });
  });

  // ─── obtenerEtapas ────────────────────────────────────

  describe('obtenerEtapas', () => {
    it('should return etapas for ADMIN viewing any user', async () => {
      const asignaciones = [
        Object.assign(new AsignacionEtapa(), { id: 'asig-1', etapaId: 'etapa-1', createdAt: new Date() }),
      ];
      asignacionRepo.find.mockResolvedValue(asignaciones);

      const result = await controller.obtenerEtapas('cob-1', mockAdmin);

      expect(result).toHaveLength(1);
      expect(result[0].etapaId).toBe('etapa-1');
      expect(asignacionRepo.find).toHaveBeenCalledWith({
        where: { usuarioId: 'cob-1' },
      });
    });

    it('should return etapas for COBRADOR viewing their own', async () => {
      const asignaciones = [
        Object.assign(new AsignacionEtapa(), { id: 'asig-2', etapaId: 'etapa-2', createdAt: new Date() }),
      ];
      asignacionRepo.find.mockResolvedValue(asignaciones);

      const result = await controller.obtenerEtapas('cob-1', mockCobrador);

      expect(result).toHaveLength(1);
      expect(result[0].etapaId).toBe('etapa-2');
    });

    it('should return empty for COBRADOR viewing another user', async () => {
      const result = await controller.obtenerEtapas('cob-2', mockCobrador);

      expect(result).toEqual([]);
      expect(asignacionRepo.find).not.toHaveBeenCalled();
    });
  });

  // ─── asignarEtapa ─────────────────────────────────────

  describe('asignarEtapa', () => {
    it('should call asignarEtapaUseCase with dto and current user tenant', async () => {
      const expected = Object.assign(new AsignacionEtapa(), { id: 'asig-3' });
      asignarEtapaUC.execute.mockResolvedValue(expected);

      const result = await controller.asignarEtapa(
        'cob-1',
        { etapaId: 'etapa-1' },
        mockAdmin,
      );

      expect(result).toEqual(expected);
      expect(asignarEtapaUC.execute).toHaveBeenCalledWith({
        usuarioId: 'cob-1',
        etapaId: 'etapa-1',
        tenantId: 'tenant-1',
      });
    });
  });

  // ─── cambiarPassword ──────────────────────────────────

  describe('cambiarPassword', () => {
    it('should update password and return message + email', async () => {
      const usuario = Object.assign(
        Usuario.crear('user@test.com', 'old-hash', 'User', RolUsuario.COBRADOR, 'tenant-1'),
        { id: 'usr-1' },
      );
      usuarioRepo.findOne.mockResolvedValue(usuario);
      (bcrypt.hash as jest.Mock).mockResolvedValue('new-hash');
      usuarioRepo.save.mockResolvedValue(usuario);

      const result = await controller.cambiarPassword(
        'usr-1',
        { newPassword: 'NewPass123' },
        mockAdmin,
      );

      expect(result).toEqual({
        message: 'Contraseña actualizada para User',
        email: 'user@test.com',
      });
      expect(usuarioRepo.findOne).toHaveBeenCalledWith({
        where: { id: 'usr-1', tenantId: 'tenant-1' },
      });
      expect(bcrypt.hash).toHaveBeenCalledWith('NewPass123', 10);
      expect(usuarioRepo.save).toHaveBeenCalledWith(usuario);
    });

    it('should throw NotFoundException when user not found', async () => {
      usuarioRepo.findOne.mockResolvedValue(null);

      await expect(
        controller.cambiarPassword(
          'nonexistent',
          { newPassword: 'NewPass123' },
          mockAdmin,
        ),
      ).rejects.toThrow('Usuario no encontrado');

      expect(usuarioRepo.save).not.toHaveBeenCalled();
    });
  });

  // ─── resetearPassword ─────────────────────────────────

  describe('resetearPassword', () => {
    it('should reset with provided password', async () => {
      const usuario = Object.assign(
        Usuario.crear('reset@test.com', 'old-hash', 'Reset User', RolUsuario.COBRADOR, 'tenant-1'),
        { id: 'usr-2' },
      );
      usuarioRepo.findOne.mockResolvedValue(usuario);
      (bcrypt.hash as jest.Mock).mockResolvedValue('temp-hash');
      usuarioRepo.save.mockResolvedValue(usuario);

      const result = await controller.resetearPassword(
        'usr-2',
        { password: 'TempPass1' },
        mockAdmin,
      );

      expect(result.message).toContain('Reset User');
      expect(result.tempPassword).toBe('TempPass1');
      expect(bcrypt.hash).toHaveBeenCalledWith('TempPass1', 10);
    });

    it('should generate temporary password when not provided', async () => {
      const usuario = Object.assign(
        Usuario.crear('auto@test.com', 'old-hash', 'Auto', RolUsuario.COBRADOR, 'tenant-1'),
        { id: 'usr-3' },
      );
      usuarioRepo.findOne.mockResolvedValue(usuario);
      (bcrypt.hash as jest.Mock).mockResolvedValue('auto-hash');
      usuarioRepo.save.mockResolvedValue(usuario);

      const result = await controller.resetearPassword(
        'usr-3',
        {},
        mockAdmin,
      );

      expect(result.tempPassword).toMatch(/^Civica\d{4}!\d{4}$/);
      expect(bcrypt.hash).toHaveBeenCalledWith(result.tempPassword, 10);
    });

    it('should throw NotFoundException when user not found', async () => {
      usuarioRepo.findOne.mockResolvedValue(null);

      await expect(
        controller.resetearPassword(
          'nonexistent',
          {},
          mockAdmin,
        ),
      ).rejects.toThrow('Usuario no encontrado');

      expect(usuarioRepo.save).not.toHaveBeenCalled();
    });
  });

  // ─── desasignarEtapa ──────────────────────────────────

  describe('desasignarEtapa', () => {
    it('should delete assignment and return success', async () => {
      asignacionRepo.delete.mockResolvedValue({ affected: 1 } as any);

      const result = await controller.desasignarEtapa('cob-1', 'etapa-1');

      expect(result).toEqual({ success: true });
      expect(asignacionRepo.delete).toHaveBeenCalledWith({
        usuarioId: 'cob-1',
        etapaId: 'etapa-1',
      });
    });

    it('should throw NotFoundException if no rows affected', async () => {
      asignacionRepo.delete.mockResolvedValue({ affected: 0 } as any);

      await expect(
        controller.desasignarEtapa('cob-1', 'etapa-1'),
      ).rejects.toThrow('Asignación no encontrada');
    });
  });
});
