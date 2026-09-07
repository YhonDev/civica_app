import { ServiceUnavailableException } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { MantenimientoService } from './mantenimiento.service';

describe('MantenimientoService', () => {
  let service: MantenimientoService;
  const query = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
    service = new MantenimientoService({
      query,
    } as unknown as DataSource);
  });

  it('lanza 503 si el proyecto del residente está en mantenimiento', async () => {
    query.mockResolvedValue([{ modo_mantenimiento: true }]);

    await expect(
      service.verificarResidenteNoBloqueado('residente-1'),
    ).rejects.toThrow(ServiceUnavailableException);
  });

  it('permite la operación si el proyecto no está en mantenimiento', async () => {
    query.mockResolvedValue([{ modo_mantenimiento: false }]);

    await expect(
      service.verificarResidenteNoBloqueado('residente-1'),
    ).resolves.toBeUndefined();
  });

  it('permite la operación si el residente no tiene plan de cobro activo', async () => {
    query.mockResolvedValue([]);

    await expect(
      service.verificarResidenteNoBloqueado('residente-1'),
    ).resolves.toBeUndefined();
  });

  it('no consulta la base de datos si el residenteId es vacío', async () => {
    await expect(
      service.verificarResidenteNoBloqueado(''),
    ).resolves.toBeUndefined();
    expect(query).not.toHaveBeenCalled();
  });
});
