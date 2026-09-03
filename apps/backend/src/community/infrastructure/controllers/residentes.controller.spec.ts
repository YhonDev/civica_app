import { Test, TestingModule } from '@nestjs/testing';
import { DataSource } from 'typeorm';
import { getRepositoryToken } from '@nestjs/typeorm';
import { UnauthorizedException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';

import { ResidentesController } from './residentes.controller';
import { RegistrarResidenteUseCase } from '../../application/use-cases/registrar-residente.use-case';
import { ResidenteRepository } from '../../infrastructure/residente.repository';
import { ResidenteDetailQuery } from '../../application/queries/residente-detail.query';
import { EliminarResidenteUseCase } from '../../application/use-cases/eliminar-residente.use-case';
import { ActualizarResidenteUseCase } from '../../application/use-cases/actualizar-residente.use-case';
import { Usuario, RolUsuario } from '../../../iam/domain/usuario.entity';
import { ActividadRepository } from '../../../notifications/domain/actividad.repository';

describe('ResidentesController', () => {
  let controller: ResidentesController;
  let registrarUC: jest.Mocked<RegistrarResidenteUseCase>;
  let eliminarUC: jest.Mocked<EliminarResidenteUseCase>;
  let actualizarUC: jest.Mocked<ActualizarResidenteUseCase>;
  let residenteRepo: jest.Mocked<ResidenteRepository>;
  let residenteDetailQuery: jest.Mocked<ResidenteDetailQuery>;
  let dataSource: jest.Mocked<DataSource>;
  let usuarioRepo: jest.Mocked<any>;

  const mockAdmin = Object.assign(
    Usuario.crear(
      'admin@test.com',
      'hash',
      'Admin',
      RolUsuario.ADMIN,
      'tenant-1',
    ),
    { id: 'admin-1' },
  );
  const mockCobrador = Object.assign(
    Usuario.crear(
      'cob@test.com',
      'hash',
      'Cobrador',
      RolUsuario.COBRADOR,
      'tenant-1',
    ),
    { id: 'cob-1' },
  );
  const mockResidente = Object.assign(
    Usuario.crear(
      'res@test.com',
      'hash',
      'Residente',
      RolUsuario.RESIDENTE,
      'tenant-1',
      'res-1',
    ),
    { id: 'res-usr-1', residenteId: 'res-1' },
  );

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [ResidentesController],
      providers: [
        {
          provide: RegistrarResidenteUseCase,
          useValue: { execute: jest.fn() },
        },
        {
          provide: EliminarResidenteUseCase,
          useValue: { execute: jest.fn() },
        },
        {
          provide: ActualizarResidenteUseCase,
          useValue: { execute: jest.fn() },
        },
        {
          provide: ResidenteRepository,
          useValue: {
            buscarPorFiltros: jest.fn(),
            findById: jest.fn(),
            buscarPorEtapas: jest.fn(),
          },
        },
        {
          provide: ResidenteDetailQuery,
          useValue: { execute: jest.fn() },
        },
        {
          provide: DataSource,
          useValue: {
            query: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(Usuario),
          useValue: {
            find: jest.fn(),
          },
        },
        {
          provide: ActividadRepository,
          useValue: { save: jest.fn() },
        },
        {
          provide: Reflector,
          useValue: { get: jest.fn() },
        },
      ],
    }).compile();

    controller = module.get<ResidentesController>(ResidentesController);
    registrarUC = module.get(RegistrarResidenteUseCase);
    eliminarUC = module.get(EliminarResidenteUseCase);
    actualizarUC = module.get(ActualizarResidenteUseCase);
    residenteRepo = module.get(ResidenteRepository);
    residenteDetailQuery = module.get(ResidenteDetailQuery);
    dataSource = module.get(DataSource);
    usuarioRepo = module.get(getRepositoryToken(Usuario));
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  // ─── Registrar ───────────────────────────────────────

  describe('registrar', () => {
    it('should call registrarResidenteUseCase with dto and tenantId', async () => {
      registrarUC.execute.mockResolvedValue({
        residente: { id: 'res-1', nombre: 'Juan' } as any,
        credenciales: { username: 'juan', password: 'pass' },
      });

      const result = await controller.registrar(
        {
          nombre: 'Juan Perez',
          telefono: '3001234567',
          email: 'juan@test.com',
          casaId: 'casa-1',
        },
        'tenant-1',
      );

      expect(result).toBeDefined();
      expect(registrarUC.execute).toHaveBeenCalledWith({
        nombre: 'Juan Perez',
        telefono: '3001234567',
        email: 'juan@test.com',
        tenantId: 'tenant-1',
        casaId: 'casa-1',
        fechaInicio: undefined,
        modalidadPago: undefined,
      });
    });
  });

  // ─── Actualizar ──────────────────────────────────────

  describe('actualizar', () => {
    it('should call actualizarResidenteUseCase and return success', async () => {
      const result = await controller.actualizar(
        'res-1',
        { nombre: 'Nuevo Nombre' },
        mockAdmin,
      );

      expect(result).toEqual({ success: true });
      expect(actualizarUC.execute).toHaveBeenCalledWith({
        id: 'res-1',
        tenantId: 'tenant-1',
        nombre: 'Nuevo Nombre',
      });
    });

    it('should throw UnauthorizedException when user has no tenantId', async () => {
      const userNoTenant = Object.assign(new Usuario(), { id: 'no-tenant' });

      await expect(
        controller.actualizar('res-1', { nombre: 'Test' }, userNoTenant),
      ).rejects.toThrow(UnauthorizedException);
    });
  });

  // ─── Eliminar ────────────────────────────────────────

  describe('eliminar', () => {
    it('should call eliminarResidenteUseCase and return success', async () => {
      const result = await controller.eliminar('res-1', mockAdmin);

      expect(result).toEqual({ success: true });
      expect(eliminarUC.execute).toHaveBeenCalledWith('res-1', 'tenant-1');
    });
  });

  // ─── Get Detalle ─────────────────────────────────────

  describe('getDetalle', () => {
    it('should return detalle for ADMIN', async () => {
      const detalle: any = { id: 'res-1', nombre: 'Juan' };
      residenteDetailQuery.execute.mockResolvedValue(detalle);

      const result = await controller.getDetalle(
        'res-1',
        'tenant-1',
        mockAdmin,
      );

      expect(result).toEqual(detalle);
      expect(residenteDetailQuery.execute).toHaveBeenCalledWith(
        'res-1',
        'tenant-1',
      );
    });

    it('should throw UnauthorizedException when ADMIN has no tenantId', async () => {
      const noTenantAdmin = Object.assign(new Usuario(), {
        id: 'admin',
        rol: RolUsuario.ADMIN,
      });

      await expect(
        controller.getDetalle('res-1', 'tenant-1', noTenantAdmin),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('should throw UnauthorizedException when RESIDENTE tries to view another residente', async () => {
      await expect(
        controller.getDetalle('other-residente', 'tenant-1', mockResidente),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('should allow RESIDENTE to view their own detalle', async () => {
      const detalle: any = { id: 'res-1', nombre: 'Residente' };
      residenteDetailQuery.execute.mockResolvedValue(detalle);

      const result = await controller.getDetalle(
        'res-1',
        'tenant-1',
        mockResidente,
      );

      expect(result).toEqual(detalle);
    });
  });

  // ─── Listar ──────────────────────────────────────────

  describe('listar', () => {
    it('should return all residentes for ADMIN', async () => {
      const residentes = [{ id: 'res-1' }, { id: 'res-2' }] as any;
      residenteRepo.buscarPorFiltros.mockResolvedValue(residentes);
      usuarioRepo.find.mockResolvedValue([]);

      const result = await controller.listar(
        'tenant-1',
        undefined,
        undefined,
        mockAdmin,
      );

      expect(result).toHaveLength(2);
      expect(residenteRepo.buscarPorFiltros).toHaveBeenCalledWith({
        tenantId: 'tenant-1',
        etapaId: undefined,
        casaId: undefined,
      });
    });

    it('should return filtered residentes by etapa for COBRADOR when etapaId is provided', async () => {
      const residentes = [{ id: 'res-1' }] as any;
      residenteRepo.buscarPorFiltros.mockResolvedValue(residentes);
      usuarioRepo.find.mockResolvedValue([]);

      const result = await controller.listar(
        'tenant-1',
        'etapa-1',
        undefined,
        mockCobrador,
      );

      expect(result).toHaveLength(1);
      expect(residenteRepo.buscarPorFiltros).toHaveBeenCalledWith({
        tenantId: 'tenant-1',
        etapaId: 'etapa-1',
        casaId: undefined,
      });
    });

    it('should return residentes by assigned etapas for COBRADOR without etapaId', async () => {
      const residentes = [
        { id: 'res-1', tenencias: [{ casaId: 'casa-1' }] },
      ] as any;
      dataSource.query.mockResolvedValue([
        { etapa_id: 'etapa-1' },
        { etapa_id: 'etapa-2' },
      ]);
      residenteRepo.buscarPorEtapas.mockResolvedValue(residentes);
      usuarioRepo.find.mockResolvedValue([]);

      const result = await controller.listar(
        'tenant-1',
        undefined,
        undefined,
        mockCobrador,
      );

      expect(result).toHaveLength(1);
      expect(dataSource.query).toHaveBeenCalledWith(
        'SELECT etapa_id FROM asignaciones_etapa WHERE usuario_id = $1',
        ['cob-1'],
      );
      expect(residenteRepo.buscarPorEtapas).toHaveBeenCalledWith('tenant-1', [
        'etapa-1',
        'etapa-2',
      ]);
    });

    it('should return empty array for COBRADOR with no asignaciones', async () => {
      dataSource.query.mockResolvedValue([]);

      const result = await controller.listar(
        'tenant-1',
        undefined,
        undefined,
        mockCobrador,
      );

      expect(result).toEqual([]);
      expect(residenteRepo.buscarPorEtapas).not.toHaveBeenCalled();
    });

    it('should filter by casaId for COBRADOR in memory', async () => {
      const residentes = [
        { id: 'res-1', tenencias: [{ casaId: 'casa-1' }] },
        { id: 'res-2', tenencias: [{ casaId: 'casa-2' }] },
      ] as any;
      dataSource.query.mockResolvedValue([{ etapa_id: 'etapa-1' }]);
      residenteRepo.buscarPorEtapas.mockResolvedValue(residentes);
      usuarioRepo.find.mockResolvedValue([]);

      const result = await controller.listar(
        'tenant-1',
        undefined,
        'casa-1',
        mockCobrador,
      );

      expect(result).toHaveLength(1);
      expect(result[0].id).toBe('res-1');
    });

    it('should return only own data for RESIDENTE', async () => {
      const residente = { id: 'res-1', nombre: 'Yo' } as any;
      residenteRepo.findById.mockResolvedValue(residente);
      usuarioRepo.find.mockResolvedValue([]);

      const result = await controller.listar(
        'tenant-1',
        undefined,
        undefined,
        mockResidente,
      );

      expect(result).toHaveLength(1);
      expect(residenteRepo.findById).toHaveBeenCalledWith('res-1');
    });

    it('should return empty for RESIDENTE without residenteId', async () => {
      const resSinId = Object.assign(
        Usuario.crear(
          'x@test.com',
          'hash',
          'X',
          RolUsuario.RESIDENTE,
          'tenant-1',
        ),
        { id: 'usr-x', residenteId: null },
      );

      const result = await controller.listar(
        'tenant-1',
        undefined,
        undefined,
        resSinId,
      );

      expect(result).toEqual([]);
    });

    it('should throw UnauthorizedException without user or tenantId', async () => {
      await expect(
        controller.listar('', undefined, undefined, undefined),
      ).rejects.toThrow(UnauthorizedException);
    });
  });
});
