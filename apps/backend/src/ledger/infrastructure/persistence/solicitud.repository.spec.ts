import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SolicitudRepository } from './solicitud.repository';
import { Solicitud, SolicitudEstado } from '../../domain/solicitud.entity';

describe('SolicitudRepository — aislamiento multi-tenant', () => {
  let repo: SolicitudRepository;

  const mockRepo = {
    find: jest.fn(),
    findOne: jest.fn(),
    delete: jest.fn(),
    save: jest.fn(),
  };

  const TENANT_A = 'tenant-A';
  const TENANT_B = 'tenant-B';

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SolicitudRepository,
        { provide: getRepositoryToken(Solicitud), useValue: mockRepo },
      ],
    }).compile();

    repo = module.get<SolicitudRepository>(SolicitudRepository);
  });

  describe('findByUsuario()', () => {
    it('should always filter by tenantId together with usuarioId', async () => {
      mockRepo.find.mockResolvedValue([]);

      await repo.findByUsuario('usr-1', TENANT_A);

      expect(mockRepo.find).toHaveBeenCalledTimes(1);
      const args = mockRepo.find.mock.calls[0][0];
      expect(args.where).toEqual({
        usuarioId: 'usr-1',
        tenantId: TENANT_A,
      });
    });

    it('must NEVER query by usuarioId alone (cross-tenant leak guard)', async () => {
      mockRepo.find.mockResolvedValue([]);

      await repo.findByUsuario('usr-1', TENANT_B, 10, 5);

      const args = mockRepo.find.mock.calls[0][0];
      // If tenantId were missing, a usuarioId colliding across tenants
      // would leak another tenant's solicitudes.
      expect(args.where.tenantId).toBe(TENANT_B);
      expect(args.where.usuarioId).toBe('usr-1');
      expect(args.take).toBe(10);
      expect(args.skip).toBe(5);
    });

    it('should cap limit at 100 regardless of requested value', async () => {
      mockRepo.find.mockResolvedValue([]);

      await repo.findByUsuario('usr-1', TENANT_A, 9999);

      expect(mockRepo.find.mock.calls[0][0].take).toBe(100);
    });
  });

  describe('findById()', () => {
    it('should include tenantId in the where clause', async () => {
      mockRepo.findOne.mockResolvedValue({ id: 'sol-1' });

      const result = await repo.findById('sol-1', TENANT_A);

      expect(mockRepo.findOne).toHaveBeenCalledWith({
        where: { id: 'sol-1', tenantId: TENANT_A },
      });
      expect(result?.id).toBe('sol-1');
    });

    it('should return null when the id exists but belongs to another tenant', async () => {
      mockRepo.findOne.mockResolvedValue(null);

      const result = await repo.findById('sol-other-tenant', TENANT_A);

      expect(result).toBeNull();
      expect(mockRepo.findOne.mock.calls[0][0].where.tenantId).toBe(TENANT_A);
    });
  });

  describe('findByTenant()', () => {
    it('should merge pagination into a tenant-scoped query', async () => {
      mockRepo.find.mockResolvedValue([]);

      await repo.findByTenant(TENANT_A, 50, 10);

      const args = mockRepo.find.mock.calls[0][0];
      expect(args.where).toEqual({ tenantId: TENANT_A });
      expect(args.take).toBe(50);
      expect(args.skip).toBe(10);
    });
  });

  describe('findPendingByTenant()', () => {
    it('should query scoped to the tenant and filter active states in memory', async () => {
      mockRepo.find.mockResolvedValue([
        { id: 's1', estado: SolicitudEstado.PENDIENTE },
        { id: 's2', estado: SolicitudEstado.EN_CAMINO },
        { id: 's3', estado: SolicitudEstado.RESUELTA },
      ]);

      const result = await repo.findPendingByTenant(TENANT_A);

      const args = mockRepo.find.mock.calls[0][0];
      expect(args.where).toEqual({ tenantId: TENANT_A });
      expect(result.map((s) => s.id)).toEqual(['s1', 's2']);
    });
  });
});
