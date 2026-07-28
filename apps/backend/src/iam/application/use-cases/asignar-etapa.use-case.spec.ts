import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import {
  NotFoundException,
  BadRequestException,
  ConflictException,
} from '@nestjs/common';

import { AsignarEtapaUseCase } from './asignar-etapa.use-case';
import { Usuario, RolUsuario } from '../../domain/usuario.entity';
import { AsignacionEtapa } from '../../domain/asignacion-etapa.entity';

describe('AsignarEtapaUseCase', () => {
  let useCase: AsignarEtapaUseCase;
  let usuarioRepo: jest.Mocked<Repository<Usuario>>;
  let asignacionRepo: jest.Mocked<Repository<AsignacionEtapa>>;
  let dataSource: jest.Mocked<DataSource>;

  const mockUsuario = Usuario.crear(
    'test@test.com',
    'hash',
    'Test User',
    RolUsuario.COBRADOR,
    'tenant-1',
  );
  Object.assign(mockUsuario, { id: 'user-1' });

  const validParams = {
    usuarioId: 'user-1',
    etapaId: 'etapa-1',
    tenantId: 'tenant-1',
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AsignarEtapaUseCase,
        {
          provide: getRepositoryToken(Usuario),
          useValue: {
            findOne: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(AsignacionEtapa),
          useValue: {
            findOne: jest.fn(),
            save: jest.fn(),
          },
        },
        {
          provide: DataSource,
          useValue: {
            createQueryBuilder: jest.fn(),
          },
        },
      ],
    }).compile();

    useCase = module.get<AsignarEtapaUseCase>(AsignarEtapaUseCase);
    usuarioRepo = module.get(getRepositoryToken(Usuario));
    asignacionRepo = module.get(getRepositoryToken(AsignacionEtapa));
    dataSource = module.get(DataSource);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  // ─── Success ──────────────────────────────────────────

  describe('execute', () => {
    it('should create asignacion when all validations pass', async () => {
      usuarioRepo.findOne.mockResolvedValue(mockUsuario);

      const mockQueryBuilder: any = {
        select: jest.fn().mockReturnThis(),
        from: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        getRawOne: jest.fn().mockResolvedValue({ '1': 1 }),
      };
      dataSource.createQueryBuilder.mockReturnValue(mockQueryBuilder);

      asignacionRepo.findOne.mockResolvedValue(null);

      const savedAsignacion = Object.assign(new AsignacionEtapa(), {
        id: 'asig-1',
        usuarioId: 'user-1',
        etapaId: 'etapa-1',
        tenantId: 'tenant-1',
      });
      asignacionRepo.save.mockResolvedValue(savedAsignacion);

      const result = await useCase.execute(validParams);

      expect(result).toEqual(savedAsignacion);
      expect(usuarioRepo.findOne).toHaveBeenCalledWith({
        where: { id: 'user-1' },
      });
      expect(asignacionRepo.findOne).toHaveBeenCalledWith({
        where: { usuarioId: 'user-1', etapaId: 'etapa-1' },
      });
      expect(asignacionRepo.save).toHaveBeenCalled();
    });
  });

  // ─── User not found ───────────────────────────────────

  describe('user not found', () => {
    it('should throw NotFoundException', async () => {
      usuarioRepo.findOne.mockResolvedValue(null);

      await expect(useCase.execute(validParams)).rejects.toThrow(
        NotFoundException,
      );
      expect(asignacionRepo.save).not.toHaveBeenCalled();
    });
  });

  // ─── Tenant mismatch ──────────────────────────────────

  describe('tenant mismatch', () => {
    it('should throw BadRequestException', async () => {
      usuarioRepo.findOne.mockResolvedValue(mockUsuario);

      await expect(
        useCase.execute({ ...validParams, tenantId: 'other-tenant' }),
      ).rejects.toThrow(BadRequestException);

      expect(asignacionRepo.save).not.toHaveBeenCalled();
    });
  });

  // ─── Stage not found ─────────────────────────────────

  describe('etapa not found', () => {
    it('should throw NotFoundException when etapa does not exist', async () => {
      usuarioRepo.findOne.mockResolvedValue(mockUsuario);

      const mockQueryBuilder: any = {
        select: jest.fn().mockReturnThis(),
        from: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        getRawOne: jest.fn().mockResolvedValue(null),
      };
      dataSource.createQueryBuilder.mockReturnValue(mockQueryBuilder);

      await expect(useCase.execute(validParams)).rejects.toThrow(
        NotFoundException,
      );
      expect(asignacionRepo.save).not.toHaveBeenCalled();
    });
  });

  // ─── Already assigned ─────────────────────────────────

  describe('already assigned', () => {
    it('should throw ConflictException', async () => {
      usuarioRepo.findOne.mockResolvedValue(mockUsuario);

      const mockQueryBuilder: any = {
        select: jest.fn().mockReturnThis(),
        from: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        getRawOne: jest.fn().mockResolvedValue({ '1': 1 }),
      };
      dataSource.createQueryBuilder.mockReturnValue(mockQueryBuilder);

      asignacionRepo.findOne.mockResolvedValue(
        Object.assign(new AsignacionEtapa(), { id: 'existing-asig' }),
      );

      await expect(useCase.execute(validParams)).rejects.toThrow(
        ConflictException,
      );
      expect(asignacionRepo.save).not.toHaveBeenCalled();
    });
  });
});
