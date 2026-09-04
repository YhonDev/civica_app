import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';

import { RegistrarResidenteUseCase } from './registrar-residente.use-case';
import { ResidenteRepository } from '../../infrastructure/residente.repository';
import { GenerarCredencialesService } from '../../../iam/application/services/generar-credenciales.service';
import { Usuario } from '../../../iam/domain/usuario.entity';
import { Casa } from '../../domain/casa.entity';
import { Manzana } from '../../domain/manzana.entity';
import { Etapa } from '../../domain/etapa.entity';
import { PlanDeCobroRepository } from '../../../ledger/infrastructure/persistence/plan-de-cobro.repository';
import { GenerarCobrosUseCase } from '../../../ledger/application/use-cases/generar-cobros.use-case';
import { Residente } from '../../domain/residente.entity';

jest.mock('bcrypt');

describe('RegistrarResidenteUseCase', () => {
  let useCase: RegistrarResidenteUseCase;
  let residenteRepo: jest.Mocked<ResidenteRepository>;
  let usuarioRepo: jest.Mocked<Repository<Usuario>>;
  let casaRepo: jest.Mocked<Repository<Casa>>;
  let planDeCobroRepo: jest.Mocked<PlanDeCobroRepository>;
  let generarCobrosUC: jest.Mocked<GenerarCobrosUseCase>;
  let generarCredenciales: jest.Mocked<GenerarCredencialesService>;

  const mockCasa = Object.assign(new Casa(), {
    id: 'casa-1',
    direccionInterna: 'Lote 23',
    manzana: Object.assign(new Manzana(), {
      id: 'mza-1',
      nombre: 'Manzana A',
      etapa: Object.assign(new Etapa(), {
        id: 'etapa-1',
        proyectoId: 'proy-1',
        proyecto: { tenantId: 'tenant-1' },
      }),
    }),
  });

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RegistrarResidenteUseCase,
        GenerarCredencialesService,
        {
          provide: ResidenteRepository,
          useValue: {
            save: jest.fn(),
            findById: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(Usuario),
          useValue: {
            save: jest.fn(),
            findOne: jest.fn().mockResolvedValue(null),
          },
        },
        {
          provide: getRepositoryToken(Casa),
          useValue: {
            findOne: jest.fn(),
          },
        },
        {
          provide: PlanDeCobroRepository,
          useValue: {
            save: jest.fn(),
          },
        },
        {
          provide: GenerarCobrosUseCase,
          useValue: {
            generarCobrosParaPlan: jest.fn(),
          },
        },
      ],
    }).compile();

    useCase = module.get<RegistrarResidenteUseCase>(RegistrarResidenteUseCase);
    residenteRepo = module.get(ResidenteRepository);
    usuarioRepo = module.get(getRepositoryToken(Usuario));
    casaRepo = module.get(getRepositoryToken(Casa));
    planDeCobroRepo = module.get(PlanDeCobroRepository);
    generarCobrosUC = module.get(GenerarCobrosUseCase);
    generarCredenciales = module.get(GenerarCredencialesService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  // ─── Success without casa ─────────────────────────────

  describe('execute without casa', () => {
    it('should create residente and user with fallback username', async () => {
      const savedResidente = Residente.crear(
        'Maria Lopez',
        '3001234567',
        'maria@test.com',
        'tenant-1',
      );
      Object.assign(savedResidente, { id: 'res-1' });
      residenteRepo.save.mockResolvedValue(savedResidente);

      jest.spyOn(generarCredenciales, 'generarUsernameResidente');
      jest
        .spyOn(generarCredenciales, 'generarPasswordAleatoria')
        .mockReturnValue('pass123ABC');

      (bcrypt.hash as jest.Mock).mockResolvedValue('hashed-pass');

      const savedUser = Object.assign(new Usuario(), { id: 'usr-1' });
      usuarioRepo.save.mockResolvedValue(savedUser);

      const result = await useCase.execute({
        nombre: 'Maria Lopez',
        telefono: '3001234567',
        email: 'maria@test.com',
        tenantId: 'tenant-1',
      });

      expect(result.residente).toEqual(savedResidente);
      expect(result.credenciales).toBeDefined();
      expect(result.credenciales.username).toContain('residente_');
      expect(result.credenciales.password).toBe('pass123ABC');
      expect(usuarioRepo.save).toHaveBeenCalled();
      expect(casaRepo.findOne).not.toHaveBeenCalled();
      expect(planDeCobroRepo.save).not.toHaveBeenCalled();
    });
  });

  // ─── Success with casa ────────────────────────────────

  describe('execute with casa', () => {
    it('should create residente, tenencia, plan and user', async () => {
      const savedResidente = Residente.crear(
        'Juan Perez',
        '3007654321',
        null,
        'tenant-1',
        'MENSUAL',
      );
      Object.assign(savedResidente, { id: 'res-2' });

      // save() is called twice: first for residente, second after agregarTenencia
      residenteRepo.save
        .mockResolvedValueOnce(savedResidente)
        .mockResolvedValueOnce(savedResidente);

      casaRepo.findOne.mockResolvedValue(mockCasa);

      jest
        .spyOn(generarCredenciales, 'generarUsernameResidente')
        .mockReturnValue('manzana_a_lote_23_residente');
      jest
        .spyOn(generarCredenciales, 'generarPasswordResidente')
        .mockReturnValue('XyZ789!pq');

      (bcrypt.hash as jest.Mock).mockResolvedValue('hashed-pass');

      const savedUser = Object.assign(new Usuario(), { id: 'usr-2' });
      usuarioRepo.save.mockResolvedValue(savedUser);

      const savedPlan = Object.assign({ id: 'plan-1' });
      planDeCobroRepo.save.mockResolvedValue(savedPlan);
      generarCobrosUC.generarCobrosParaPlan.mockResolvedValue(1);

      const result = await useCase.execute({
        nombre: 'Juan Perez',
        telefono: '3007654321',
        email: null,
        tenantId: 'tenant-1',
        casaId: 'casa-1',
        modalidadPago: 'MENSUAL',
      });

      expect(result.residente).toEqual(savedResidente);
      expect(result.credenciales).toEqual({
        username: 'manzana_a_lote_23_residente',
        password: 'XyZ789!pq',
      });

      // Verify tenencia was added (agregarTenencia pushes to the array)
      expect(residenteRepo.save).toHaveBeenCalledTimes(2);
      expect(savedResidente.tenencias).toHaveLength(1);
      expect(savedResidente.tenencias[0].casaId).toBe('casa-1');

      // Verify plan de cobro was created
      expect(casaRepo.findOne).toHaveBeenCalledWith({
        where: { id: 'casa-1' },
        relations: { manzana: { etapa: { proyecto: true } } },
      });
      expect(planDeCobroRepo.save).toHaveBeenCalledTimes(1);
      expect(generarCobrosUC.generarCobrosParaPlan).toHaveBeenCalledWith(
        savedPlan,
        expect.any(Number),
        expect.any(Number),
        expect.any(Date),
      );
    });
  });

  // ─── Casa not found ───────────────────────────────────

  describe('execute with casa that is not found', () => {
    it('should reject the resident when casa is outside the tenant lineage', async () => {
      casaRepo.findOne.mockResolvedValue(null);

      await expect(
        useCase.execute({
          nombre: 'Ana Ruiz',
          telefono: '3001112233',
          email: 'ana@test.com',
          tenantId: 'tenant-1',
          casaId: 'nonexistent-casa',
        }),
      ).rejects.toThrow('Casa no encontrada en el tenant actual');

      expect(residenteRepo.save).not.toHaveBeenCalled();
    });
  });
});
