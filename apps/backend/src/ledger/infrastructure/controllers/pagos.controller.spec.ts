import { PagosController } from './pagos.controller';
import { RolUsuario, Usuario } from '../../../iam/domain/usuario.entity';

describe('PagosController', () => {
  let controller: PagosController;

  const mockPagoRepo = {
    findByPropietario: jest.fn(),
  };

  const mockPago = {
    id: 'pago-1',
    clientPaymentId: null,
    residente: { id: 'res-1', nombre: 'Carlos' },
    cobrador: { nombre: 'Admin' },
    cobro: null,
  } as any;

  const crearUser = (
    rol: RolUsuario,
    residenteId: string | null = null,
  ): Usuario =>
    ({
      id: 'user-1',
      rol,
      residenteId,
      tenantId: 'tenant-1',
    }) as unknown as Usuario;

  beforeEach(() => {
    jest.clearAllMocks();
    mockPagoRepo.findByPropietario.mockResolvedValue([mockPago]);

    controller = new PagosController(
      {} as any, // registrarPagoUC
      {} as any, // eliminarPagoUC
      {} as any, // corregirPagoUC
      {} as any, // validarPagoUC
      mockPagoRepo as any,
      {} as any, // mantenimientoService
    );
  });

  describe('[regresion C5] GET /pagos no permite IDOR a residentes', () => {
    it('residente con residenteId: ignora el residenteId del query aunque lo envie', async () => {
      const user = crearUser(RolUsuario.RESIDENTE, 'res-1');

      await controller.listByResidente('res-AJENO', user, 'tenant-1');

      // Debe consultar SOLO su propio id, nunca el del query
      expect(mockPagoRepo.findByPropietario).toHaveBeenCalledWith(
        'res-1',
        'tenant-1',
      );
    });

    it('residente sin residenteId (null) + ?residenteId=ajeno: devuelve vacio, no pagos de terceros', async () => {
      const user = crearUser(RolUsuario.RESIDENTE, null);

      const result = await controller.listByResidente('res-AJENO', user, 'tenant-1');

      // Antes del fix: fallback al query => exfiltra pagos de res-AJENO (IDOR)
      expect(mockPagoRepo.findByPropietario).not.toHaveBeenCalledWith(
        'res-AJENO',
        'tenant-1',
      );
      expect(mockPagoRepo.findByPropietario).not.toHaveBeenCalled();
      expect(result).toEqual([]);
    });

    it('residente sin query param: consulta sus propios pagos normalmente', async () => {
      const user = crearUser(RolUsuario.RESIDENTE, 'res-1');

      const result = await controller.listByResidente(undefined as any, user, 'tenant-1');

      expect(mockPagoRepo.findByPropietario).toHaveBeenCalledWith('res-1', 'tenant-1');
      expect(result).toHaveLength(1);
      expect(result[0]).toMatchObject({ residenteNombre: 'Carlos' });
    });
  });

  describe('admin/cobrador sin regresion', () => {
    it('admin con query param consulta los pagos pedidos', async () => {
      const user = crearUser(RolUsuario.ADMIN, null);

      await controller.listByResidente('res-2', user, 'tenant-1');

      expect(mockPagoRepo.findByPropietario).toHaveBeenCalledWith('res-2', 'tenant-1');
    });

    it('admin sin query param ni residenteId devuelve vacio', async () => {
      const user = crearUser(RolUsuario.ADMIN, null);

      const result = await controller.listByResidente(undefined as any, user, 'tenant-1');

      expect(mockPagoRepo.findByPropietario).not.toHaveBeenCalled();
      expect(result).toEqual([]);
    });

    it('cobrador sin query param usa su residenteId si lo tuviera (flujo legacy)', async () => {
      const user = crearUser(RolUsuario.COBRADOR, 'res-cobrador');

      await controller.listByResidente(undefined as any, user, 'tenant-1');

      expect(mockPagoRepo.findByPropietario).toHaveBeenCalledWith('res-cobrador', 'tenant-1');
    });
  });
});
