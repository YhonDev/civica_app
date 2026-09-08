import { Test, TestingModule } from '@nestjs/testing';
import { Reflector } from '@nestjs/core';
import { DataSource } from 'typeorm';
import { UnauthorizedException } from '@nestjs/common';
import { CobrosController } from './cobros.controller';
import { CobroRepository } from '../persistence/cobro.repository';
import { EliminarCobroUseCase } from '../../application/use-cases/eliminar-cobro.use-case';
import { GenerarCobrosUseCase } from '../../application/use-cases/generar-cobros.use-case';
import { CarteraViviendaResumenQuery } from '../../application/queries/cartera-vivienda-resumen.query';
import { Usuario, RolUsuario } from '../../../iam/domain/usuario.entity';

describe('CobrosController — aislamiento multi-tenant', () => {
  let controller: CobrosController;
  let mockCobroRepo: any;
  let mockEliminarCobroUC: any;
  let mockGenerarCobrosUC: any;
  let mockCarteraQuery: any;
  let mockDataSource: any;

  const TENANT_A = 'tenant-A';
  const TENANT_B = 'tenant-B';

  function crearUser(overrides: Partial<Usuario> = {}): Usuario {
    const user = new Usuario();
    Object.assign(user, {
      id: 'usr-1',
      nombre: 'User Test',
      email: 'user@test.com',
      rol: RolUsuario.RESIDENTE,
      tenantId: TENANT_A,
      residenteId: 'res-1',
      activo: true,
      ...overrides,
    });
    return user;
  }

  beforeEach(async () => {
    jest.clearAllMocks();

    mockCobroRepo = {
      findById: jest.fn(),
      findByResidente: jest.fn().mockResolvedValue([]),
      findByResidentes: jest.fn().mockResolvedValue([]),
      findPendientesByTenant: jest.fn().mockResolvedValue([]),
      findAllWithFilters: jest.fn().mockResolvedValue({ items: [], total: 0 }),
    };
    mockEliminarCobroUC = { execute: jest.fn().mockResolvedValue(undefined) };
    mockGenerarCobrosUC = {
      execute: jest.fn().mockResolvedValue({ generados: 0 }),
    };
    mockCarteraQuery = { execute: jest.fn().mockResolvedValue([]) };
    mockDataSource = { query: jest.fn().mockResolvedValue([]) };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [CobrosController],
      providers: [
        { provide: CobroRepository, useValue: mockCobroRepo },
        { provide: EliminarCobroUseCase, useValue: mockEliminarCobroUC },
        { provide: GenerarCobrosUseCase, useValue: mockGenerarCobrosUC },
        {
          provide: CarteraViviendaResumenQuery,
          useValue: mockCarteraQuery,
        },
        { provide: DataSource, useValue: mockDataSource },
        { provide: Reflector, useValue: { get: jest.fn() } },
      ],
    }).compile();

    controller = module.get<CobrosController>(CobrosController);
  });

  describe('listar()', () => {
    it('should always pass the tenant from @CurrentTenant to findAllWithFilters', async () => {
      const admin = crearUser({ rol: RolUsuario.ADMIN, residenteId: undefined });

      await controller.listar(TENANT_A, admin);

      expect(mockCobroRepo.findAllWithFilters).toHaveBeenCalledWith(
        TENANT_A,
        { etapaId: undefined, manzanaId: undefined, status: undefined },
        undefined,
        { limit: undefined, offset: undefined },
      );
    });

    it('should never call the repository without a tenant (guards cross-tenant listing)', async () => {
      const admin = crearUser({ rol: RolUsuario.ADMIN, residenteId: undefined });

      const result = await controller.listar('', admin);

      expect(result).toEqual([]);
      expect(mockCobroRepo.findAllWithFilters).not.toHaveBeenCalled();
    });

    it('should scope COBRADOR to its assigned etapas in addition to tenant', async () => {
      const cobrador = crearUser({ rol: RolUsuario.COBRADOR, residenteId: undefined });
      mockDataSource.query.mockResolvedValue([{ etapa_id: 'etapa-x' }]);

      await controller.listar(TENANT_A, cobrador, undefined, undefined, undefined, '10', '0');

      expect(mockCobroRepo.findAllWithFilters).toHaveBeenCalledWith(
        TENANT_A,
        { etapaId: undefined, manzanaId: undefined, status: undefined },
        ['etapa-x'],
        { limit: 10, offset: 0 },
      );
    });

    it('should return [] for COBRADOR with no assigned etapas without querying cobros', async () => {
      const cobrador = crearUser({ rol: RolUsuario.COBRADOR, residenteId: undefined });

      const result = await controller.listar(TENANT_A, cobrador);

      expect(result).toEqual([]);
      expect(mockCobroRepo.findAllWithFilters).not.toHaveBeenCalled();
    });
  });

  describe('listarPorResidente()', () => {
    it('should reject RESIDENTE asking for another residente (IDOR guard)', async () => {
      const residente = crearUser({ residenteId: 'res-1' });

      await expect(
        controller.listarPorResidente('res-OTRO', TENANT_A, residente),
      ).rejects.toThrow(UnauthorizedException);

      expect(mockCobroRepo.findByResidente).not.toHaveBeenCalled();
    });

    it('should allow RESIDENTE to list only its own cobros, scoped to tenant', async () => {
      const residente = crearUser({ residenteId: 'res-1' });
      mockCobroRepo.findByResidente.mockResolvedValue([]);

      await controller.listarPorResidente('res-1', TENANT_A, residente);

      expect(mockCobroRepo.findByResidente).toHaveBeenCalledWith('res-1', TENANT_A);
    });

    it('should pass tenantId to findByResidente (never query cross-tenant)', async () => {
      const admin = crearUser({ rol: RolUsuario.ADMIN, residenteId: undefined });
      mockCobroRepo.findByResidente.mockResolvedValue([]);

      await controller.listarPorResidente('res-2', TENANT_B, admin);

      expect(mockCobroRepo.findByResidente).toHaveBeenCalledWith('res-2', TENANT_B);
    });

    it('should filter COBRADOR results to its assigned etapas (defense in depth)', async () => {
      const cobrador = crearUser({ rol: RolUsuario.COBRADOR, residenteId: undefined });
      mockDataSource.query.mockResolvedValue([{ etapa_id: 'etapa-1' }]);

      const cobroEnEtapa = {
        id: 'cobro-1',
        residente: { casaActual: { manzana: { etapa: { id: 'etapa-1' } } } },
      };
      const cobroFueraEtapa = {
        id: 'cobro-2',
        residente: { casaActual: { manzana: { etapa: { id: 'etapa-2' } } } },
      };
      mockCobroRepo.findByResidente.mockResolvedValue([
        cobroEnEtapa,
        cobroFueraEtapa,
      ]);

      const result = await controller.listarPorResidente('res-1', TENANT_A, cobrador);

      expect(result.map((c: any) => c.id)).toEqual(['cobro-1']);
    });
  });

  describe('eliminar()', () => {
    it('should delegate to the use case with the tenant from @CurrentTenant', async () => {
      const result = await controller.eliminar('cobro-1', TENANT_A);

      expect(mockEliminarCobroUC.execute).toHaveBeenCalledWith('cobro-1', TENANT_A);
      expect(result.success).toBe(true);
    });

    it('should not delete using a different tenant than the one scoped', async () => {
      await controller.eliminar('cobro-1', TENANT_A);

      expect(mockEliminarCobroUC.execute).not.toHaveBeenCalledWith(
        'cobro-1',
        TENANT_B,
      );
    });
  });

  describe('generarCobros()', () => {
    it('should generate cobros only for the caller tenant', async () => {
      const admin = crearUser({ rol: RolUsuario.ADMIN, residenteId: undefined });

      await controller.generarCobros(TENANT_A, admin);

      expect(mockGenerarCobrosUC.execute).toHaveBeenCalledWith(TENANT_A);
      expect(mockGenerarCobrosUC.execute).not.toHaveBeenCalledWith(TENANT_B);
    });
  });

  describe('getCarteraViviendas()', () => {
    it('should pass tenantId to the resumen query and refuse empty tenant', async () => {
      await controller.getCarteraViviendas(TENANT_A);
      expect(mockCarteraQuery.execute).toHaveBeenCalledWith(TENANT_A, undefined, undefined);

      const result = await controller.getCarteraViviendas('');
      expect(result).toEqual([]);
      expect(mockCarteraQuery.execute).toHaveBeenCalledTimes(1);
    });
  });
});
