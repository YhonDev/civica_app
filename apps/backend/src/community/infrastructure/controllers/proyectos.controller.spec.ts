import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { ProyectosController } from './proyectos.controller';
import { CrearProyectoUseCase } from '../../application/use-cases/crear-proyecto.use-case';
import { CrearEtapaUseCase } from '../../application/use-cases/crear-etapa.use-case';
import { CrearManzanaUseCase } from '../../application/use-cases/crear-manzana.use-case';
import { RegistrarCasaUseCase } from '../../application/use-cases/registrar-casa.use-case';
import { ProyectoRepository } from '../../infrastructure/proyecto.repository';

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
    it('should throw BadRequestException if stage has tenencias or cobros', async () => {
      dataSource.query.mockResolvedValueOnce([{ count: '1' }]); // tenencias count
      dataSource.query.mockResolvedValueOnce([{ count: '0' }]); // cobros count

      await expect(controller.eliminarEtapa('etapa-id')).rejects.toThrow(
        BadRequestException,
      );
      expect(dataSource.query).toHaveBeenCalledTimes(2);
    });

    it('should delete stage if it is empty', async () => {
      dataSource.query.mockResolvedValueOnce([{ count: '0' }]); // tenencias count
      dataSource.query.mockResolvedValueOnce([{ count: '0' }]); // cobros count
      dataSource.query.mockResolvedValueOnce(undefined); // delete query

      const result = await controller.eliminarEtapa('etapa-id');
      expect(result).toEqual({ success: true });
      expect(dataSource.query).toHaveBeenCalledTimes(3);
    });
  });

  describe('eliminarManzana', () => {
    it('should throw BadRequestException if manzana has tenencias or cobros', async () => {
      dataSource.query.mockResolvedValueOnce([{ count: '0' }]); // tenencias count
      dataSource.query.mockResolvedValueOnce([{ count: '3' }]); // cobros count

      await expect(controller.eliminarManzana('manzana-id')).rejects.toThrow(
        BadRequestException,
      );
      expect(dataSource.query).toHaveBeenCalledTimes(2);
    });

    it('should delete manzana if it is empty', async () => {
      dataSource.query.mockResolvedValueOnce([{ count: '0' }]); // tenencias count
      dataSource.query.mockResolvedValueOnce([{ count: '0' }]); // cobros count
      dataSource.query.mockResolvedValueOnce(undefined); // delete query

      const result = await controller.eliminarManzana('manzana-id');
      expect(result).toEqual({ success: true });
      expect(dataSource.query).toHaveBeenCalledTimes(3);
    });
  });

  describe('eliminarCasa', () => {
    it('should throw BadRequestException if casa has tenencias or cobros', async () => {
      dataSource.query.mockResolvedValueOnce([{ count: '1' }]); // tenencias count
      dataSource.query.mockResolvedValueOnce([{ count: '1' }]); // cobros count

      await expect(controller.eliminarCasa('casa-id')).rejects.toThrow(
        BadRequestException,
      );
      expect(dataSource.query).toHaveBeenCalledTimes(2);
    });

    it('should delete casa if it is empty', async () => {
      dataSource.query.mockResolvedValueOnce([{ count: '0' }]); // tenencias count
      dataSource.query.mockResolvedValueOnce([{ count: '0' }]); // cobros count
      dataSource.query.mockResolvedValueOnce(undefined); // delete query

      const result = await controller.eliminarCasa('casa-id');
      expect(result).toEqual({ success: true });
      expect(dataSource.query).toHaveBeenCalledTimes(3);
    });
  });
});
