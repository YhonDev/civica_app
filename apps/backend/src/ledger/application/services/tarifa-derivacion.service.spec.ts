import { Test, TestingModule } from '@nestjs/testing';
import { TarifaDerivacionService } from './tarifa-derivacion.service';
import { TarifaRepository } from '../../infrastructure/persistence/tarifa.repository';
import { Tarifa } from '../../domain/tarifa.entity';
import { ModalidadRecaudo } from '../../../shared/common/value-objects';

describe('TarifaDerivacionService', () => {
  let service: TarifaDerivacionService;

  const mockTarifaRepo = {
    save: jest.fn(),
    findAll: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TarifaDerivacionService,
        { provide: TarifaRepository, useValue: mockTarifaRepo },
      ],
    }).compile();

    service = module.get<TarifaDerivacionService>(TarifaDerivacionService);
  });

  function crearTarifa(
    modalidad: ModalidadRecaudo,
    montoCentavos: number,
    fechaVigencia: string,
    activa = true,
  ): Tarifa {
    const tarifa = Tarifa.crear(
      'proyecto-1',
      'tenant-1',
      modalidad,
      { amount: montoCentavos, currency: 'COP' } as any,
      fechaVigencia,
    );
    tarifa.activa = activa;
    return tarifa;
  }

  describe('crearVersiones', () => {
    it('deriva las 3 modalidades desde la cuota mensual (100.000 mensual → 25.000 semanal / 50.000 quincenal)', async () => {
      mockTarifaRepo.findAll.mockResolvedValue([]);
      mockTarifaRepo.save.mockImplementation((t: Tarifa) =>
        Promise.resolve(t),
      );

      const resultado = await service.crearVersiones(
        'proyecto-1',
        'tenant-1',
        'MENSUAL',
        10_000_000, // $100.000 en centavos
        '2026-09-01',
      );

      expect(resultado).toHaveLength(3);
      const porModalidad = Object.fromEntries(
        resultado.map((t) => [t.modalidad, t.monto]),
      );
      expect(porModalidad).toEqual({
        SEMANAL: 2_500_000, // $25.000
        QUINCENAL: 5_000_000, // $50.000
        MENSUAL: 10_000_000, // $100.000
      });
      expect(resultado.every((t) => t.activa)).toBe(true);
      expect(resultado.every((t) => t.proyectoId === 'proyecto-1')).toBe(true);
      expect(resultado.every((t) => t.tenantId === 'tenant-1')).toBe(true);
      expect(resultado.every((t) => t.fechaVigencia === '2026-09-01')).toBe(
        true,
      );
    });

    it('convierte un monto semanal a mensual antes de derivar (25.000 semanal → 100.000 mensual)', async () => {
      mockTarifaRepo.findAll.mockResolvedValue([]);
      mockTarifaRepo.save.mockImplementation((t: Tarifa) =>
        Promise.resolve(t),
      );

      const resultado = await service.crearVersiones(
        'proyecto-1',
        'tenant-1',
        'SEMANAL',
        2_500_000, // $25.000
        '2026-09-01',
      );

      const porModalidad = Object.fromEntries(
        resultado.map((t) => [t.modalidad, t.monto]),
      );
      expect(porModalidad['MENSUAL']).toBe(10_000_000);
      expect(porModalidad['QUINCENAL']).toBe(5_000_000);
      expect(porModalidad['SEMANAL']).toBe(2_500_000);
    });

    it('redondea los montos no divisibles (mensual 99.999 → semanal 25.000 / quincenal 50.000)', async () => {
      mockTarifaRepo.findAll.mockResolvedValue([]);
      mockTarifaRepo.save.mockImplementation((t: Tarifa) =>
        Promise.resolve(t),
      );

      const resultado = await service.crearVersiones(
        'proyecto-1',
        'tenant-1',
        'MENSUAL',
        9_999_900, // $99.999
        '2026-09-01',
      );

      const porModalidad = Object.fromEntries(
        resultado.map((t) => [t.modalidad, t.monto]),
      );
      expect(porModalidad['MENSUAL']).toBe(9_999_900);
      expect(porModalidad['QUINCENAL']).toBe(4_999_950); // round(9999900/2)
      expect(porModalidad['SEMANAL']).toBe(2_499_975); // round(9999900/4)
    });

    it('desactiva futuras tarifas activas de cada modalidad antes de crear las nuevas', async () => {
      const semanalActivaFutura = crearTarifa('SEMANAL', 2_000_000, '2026-10-01');
      const mensualActivaAnterior = crearTarifa('MENSUAL', 8_000_000, '2026-01-01');
      mockTarifaRepo.findAll.mockResolvedValue([
        semanalActivaFutura,
        mensualActivaAnterior,
      ]);
      mockTarifaRepo.save.mockImplementation((t: Tarifa) =>
        Promise.resolve(t),
      );

      await service.crearVersiones(
        'proyecto-1',
        'tenant-1',
        'MENSUAL',
        10_000_000,
        '2026-09-01',
      );

      // La semanal con fecha >= vigencia se desactivó y se guardó
      expect(semanalActivaFutura.activa).toBe(false);
      expect(mockTarifaRepo.save).toHaveBeenCalledWith(semanalActivaFutura);
      // La mensual anterior (fecha < vigencia) NO se toca
      expect(mensualActivaAnterior.activa).toBe(true);
    });
  });

  describe('actualizarActivas', () => {
    it('actualiza solo las 3 tarifas activas vigentes con los montos derivados', async () => {
      const activas = [
        crearTarifa('SEMANAL', 1_000_000, '2026-01-01'),
        crearTarifa('QUINCENAL', 2_000_000, '2026-01-01'),
        crearTarifa('MENSUAL', 4_000_000, '2026-01-01'),
      ];
      const inactivaVieja = crearTarifa('MENSUAL', 999, '2025-01-01', false);
      mockTarifaRepo.findAll.mockResolvedValue([...activas, inactivaVieja]);
      mockTarifaRepo.save.mockImplementation((t: Tarifa) =>
        Promise.resolve(t),
      );

      const resultado = await service.actualizarActivas(
        'proyecto-1',
        'tenant-1',
        'MENSUAL',
        10_000_000,
      );

      expect(resultado).toHaveLength(3);
      const porModalidad = Object.fromEntries(
        resultado.map((t) => [t.modalidad, t.monto]),
      );
      expect(porModalidad).toEqual({
        SEMANAL: 2_500_000,
        QUINCENAL: 5_000_000,
        MENSUAL: 10_000_000,
      });
      // La inactiva no se modifica ni se guarda
      expect(inactivaVieja.monto).toBe(999);
      expect(mockTarifaRepo.save).not.toHaveBeenCalledWith(inactivaVieja);
    });

    it('retorna solo las modalidades que tenían tarifa activa (sin crear faltantes)', async () => {
      const soloMensual = [crearTarifa('MENSUAL', 4_000_000, '2026-01-01')];
      mockTarifaRepo.findAll.mockResolvedValue(soloMensual);
      mockTarifaRepo.save.mockImplementation((t: Tarifa) =>
        Promise.resolve(t),
      );

      const resultado = await service.actualizarActivas(
        'proyecto-1',
        'tenant-1',
        'MENSUAL',
        10_000_000,
      );

      expect(resultado).toHaveLength(1);
      expect(resultado[0].modalidad).toBe('MENSUAL');
      expect(resultado[0].monto).toBe(10_000_000);
      expect(mockTarifaRepo.save).toHaveBeenCalledTimes(1);
    });
  });
});
