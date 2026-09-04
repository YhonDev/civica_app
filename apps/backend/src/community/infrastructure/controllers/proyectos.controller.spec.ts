import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { ProyectosController } from './proyectos.controller';
import { CrearProyectoUseCase } from '../../application/use-cases/crear-proyecto.use-case';
import { CrearEtapaUseCase } from '../../application/use-cases/crear-etapa.use-case';
import { CrearManzanaUseCase } from '../../application/use-cases/crear-manzana.use-case';
import { RegistrarCasaUseCase } from '../../application/use-cases/registrar-casa.use-case';
import { ProyectoRepository } from '../../infrastructure/proyecto.repository';

const TENANT_ID = 'tenant-aaa';
const OTHER_TENANT_ID = 'tenant-bbb';

describe('ProyectosController', () => {
  let controller: ProyectosController;
  let dataSource: jest.Mocked<DataSource>;

  const mockDataSource = {
    query: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      controllers: [ProyectosController],
      providers: [
        {
          provide: CrearProyectoUseCase,
          useValue: { execute: jest.fn() },
        },
        {
          provide: CrearEtapaUseCase,
          useValue: { execute: jest.fn() },
        },
        {
          provide: CrearManzanaUseCase,
          useValue: { execute: jest.fn() },
        },
        {
          provide: RegistrarCasaUseCase,
          useValue: { execute: jest.fn() },
        },
        {
          provide: ProyectoRepository,
          useValue: {
            findByTenant: jest.fn(),
            findByIdPlano: jest.fn(),
            save: jest.fn(),
          },
        },
        {
          provide: DataSource,
          useValue: mockDataSource,
        },
      ],
    }).compile();

    controller = module.get<ProyectosController>(ProyectosController);
    dataSource = module.get(DataSource);
  });

  describe('eliminarEtapa', () => {
    it('should throw NotFoundException if etapa belongs to another tenant', async () => {
      dataSource.query.mockResolvedValueOnce([]); // tenant existence check: empty → not found

      await expect(
        controller.eliminarEtapa('etapa-id', OTHER_TENANT_ID),
      ).rejects.toThrow(NotFoundException);
      expect(dataSource.query).toHaveBeenCalledTimes(1);
    });

    it('should throw BadRequestException if stage has tenencias or cobros', async () => {
      dataSource.query.mockResolvedValueOnce([{ '?column?': 1 }]); // tenant existence check
      dataSource.query.mockResolvedValueOnce([{ count: '1' }]); // tenencias count
      dataSource.query.mockResolvedValueOnce([{ count: '0' }]); // cobros count

      await expect(
        controller.eliminarEtapa('etapa-id', TENANT_ID),
      ).rejects.toThrow(BadRequestException);
      expect(dataSource.query).toHaveBeenCalledTimes(3);
    });

    it('should delete stage if it is empty', async () => {
      dataSource.query.mockResolvedValueOnce([{ '?column?': 1 }]); // tenant existence check
      dataSource.query.mockResolvedValueOnce([{ count: '0' }]); // tenencias count
      dataSource.query.mockResolvedValueOnce([{ count: '0' }]); // cobros count
      dataSource.query.mockResolvedValueOnce(undefined); // delete query

      const result = await controller.eliminarEtapa('etapa-id', TENANT_ID);
      expect(result).toEqual({ success: true });
      expect(dataSource.query).toHaveBeenCalledTimes(4);
    });
  });

  describe('eliminarManzana', () => {
    it('should throw NotFoundException if manzana belongs to another tenant', async () => {
      dataSource.query.mockResolvedValueOnce([]); // tenant existence check: empty

      await expect(
        controller.eliminarManzana('manzana-id', OTHER_TENANT_ID),
      ).rejects.toThrow(NotFoundException);
      expect(dataSource.query).toHaveBeenCalledTimes(1);
    });

    it('should throw BadRequestException if manzana has tenencias or cobros', async () => {
      dataSource.query.mockResolvedValueOnce([{ '?column?': 1 }]); // tenant existence check
      dataSource.query.mockResolvedValueOnce([{ count: '0' }]); // tenencias count
      dataSource.query.mockResolvedValueOnce([{ count: '3' }]); // cobros count

      await expect(
        controller.eliminarManzana('manzana-id', TENANT_ID),
      ).rejects.toThrow(BadRequestException);
      expect(dataSource.query).toHaveBeenCalledTimes(3);
    });

    it('should delete manzana if it is empty', async () => {
      dataSource.query.mockResolvedValueOnce([{ '?column?': 1 }]); // tenant existence check
      dataSource.query.mockResolvedValueOnce([{ count: '0' }]); // tenencias count
      dataSource.query.mockResolvedValueOnce([{ count: '0' }]); // cobros count
      dataSource.query.mockResolvedValueOnce(undefined); // delete query

      const result = await controller.eliminarManzana('manzana-id', TENANT_ID);
      expect(result).toEqual({ success: true });
      expect(dataSource.query).toHaveBeenCalledTimes(4);
    });
  });

  describe('eliminarCasa', () => {
    it('should throw NotFoundException if casa belongs to another tenant', async () => {
      dataSource.query.mockResolvedValueOnce([]); // tenant existence check: empty

      await expect(
        controller.eliminarCasa('casa-id', OTHER_TENANT_ID),
      ).rejects.toThrow(NotFoundException);
      expect(dataSource.query).toHaveBeenCalledTimes(1);
    });

    it('should throw BadRequestException if casa has tenencias or cobros', async () => {
      dataSource.query.mockResolvedValueOnce([{ '?column?': 1 }]); // tenant existence check
      dataSource.query.mockResolvedValueOnce([{ count: '1' }]); // tenencias count
      dataSource.query.mockResolvedValueOnce([{ count: '1' }]); // cobros count

      await expect(
        controller.eliminarCasa('casa-id', TENANT_ID),
      ).rejects.toThrow(BadRequestException);
      expect(dataSource.query).toHaveBeenCalledTimes(3);
    });

    it('should delete casa if it is empty', async () => {
      dataSource.query.mockResolvedValueOnce([{ '?column?': 1 }]); // tenant existence check
      dataSource.query.mockResolvedValueOnce([{ count: '0' }]); // tenencias count
      dataSource.query.mockResolvedValueOnce([{ count: '0' }]); // cobros count
      dataSource.query.mockResolvedValueOnce(undefined); // delete query

      const result = await controller.eliminarCasa('casa-id', TENANT_ID);
      expect(result).toEqual({ success: true });
      expect(dataSource.query).toHaveBeenCalledTimes(4);
    });
  });
});
