import { Reflector } from '@nestjs/core';
import { PATH_METADATA } from '@nestjs/common/constants';
import { RolUsuario } from '../../../iam/domain/usuario.entity';
import { AuthController } from '../../../iam/infrastructure/controllers/auth.controller';
import { UsuariosController } from '../../../iam/infrastructure/controllers/usuarios.controller';
import { ProyectosController } from '../../../community/infrastructure/controllers/proyectos.controller';
import { ResidentesController } from '../../../community/infrastructure/controllers/residentes.controller';
import { CobradoresController } from '../../../community/infrastructure/controllers/cobradores.controller';
import { CobrosController } from '../../../ledger/infrastructure/controllers/cobros.controller';
import { PagosController } from '../../../ledger/infrastructure/controllers/pagos.controller';
import { SolicitudesController } from '../../../ledger/infrastructure/controllers/solicitudes.controller';
import { DashboardController } from '../../../ledger/infrastructure/controllers/dashboard.controller';
import { TarifasController } from '../../../ledger/infrastructure/controllers/tarifas.controller';
import { MontosController } from '../../../ledger/infrastructure/controllers/montos.controller';
import { PlanesDeCobroController } from '../../../ledger/infrastructure/controllers/planes-de-cobro.controller';
import { ReportesController } from '../../../ledger/infrastructure/controllers/reportes.controller';
import { TicketsController } from '../../../ledger/infrastructure/controllers/tickets.controller';
import { NotificacionesController } from '../../../notifications/infrastructure/controllers/notificaciones.controller';
import { HealthController } from '../../health/health.controller';
import { MetricsController } from '../../observability/metrics.controller';

/**
 * Suite de Verificación Estática de la Matriz de Autorización
 * ═══════════════════════════════════════════════════════════════
 * Garantiza que ningún endpoint nuevo o modificado quede expuesto
 * sin autenticación o sin restricción de roles explícita en NestJS.
 */
describe('Matriz de Autorización — Verificación Estática de Controladores', () => {
  const reflector = new Reflector();

  const PUBLIC_ENDPOINTS = new Set([
    'AuthController.login',
    'AuthController.refresh',
    'AuthController.logout',
    'HealthController.check',
  ]);

  // Endpoints autenticados que gestionan su propio usuario sin requerir @Roles estático
  const AUTH_SELF_ENDPOINTS = new Set([
    'AuthController.logoutAll',
    'AuthController.getSessions',
    'AuthController.revokeSession',
    'HealthController.dependencies',
  ]);

  const CONTROLLERS = [
    AuthController,
    UsuariosController,
    ProyectosController,
    ResidentesController,
    CobradoresController,
    CobrosController,
    PagosController,
    SolicitudesController,
    DashboardController,
    TarifasController,
    MontosController,
    PlanesDeCobroController,
    ReportesController,
    TicketsController,
    NotificacionesController,
    HealthController,
    MetricsController,
  ];

  it('todos los endpoints protegidos deben declarar roles autorizados (@Roles)', () => {
    const unmappedEndpoints: string[] = [];

    for (const ControllerClass of CONTROLLERS) {
      const controllerName = ControllerClass.name;
      const prototype = ControllerClass.prototype as Record<string, any>;
      const methods = Object.getOwnPropertyNames(prototype).filter(
        (prop) =>
          prop !== 'constructor' && typeof prototype[prop] === 'function',
      );

      for (const method of methods) {
        const handler = prototype[method];
        const isRoute = reflector.get(PATH_METADATA, handler) !== undefined;
        if (!isRoute) {
          continue; // Método auxiliar interno de la clase, no es ruta HTTP
        }

        const endpointKey = `${controllerName}.${method}`;

        if (
          PUBLIC_ENDPOINTS.has(endpointKey) ||
          AUTH_SELF_ENDPOINTS.has(endpointKey)
        ) {
          continue;
        }

        const roles = reflector.getAllAndOverride<RolUsuario[]>('roles', [
          handler,
          ControllerClass,
        ]);

        if (!roles || roles.length === 0) {
          unmappedEndpoints.push(endpointKey);
        }
      }
    }

    expect(unmappedEndpoints).toEqual([]);
  });

  describe('Restricciones de alto privilegio — Solo ADMIN', () => {
    it('ReportesController solo debe permitir ADMIN', () => {
      const roles = reflector.getAllAndOverride<RolUsuario[]>('roles', [
        ReportesController.prototype.getReporteRecaudo,
        ReportesController,
      ]);
      expect(roles).toEqual([RolUsuario.ADMIN]);
    });

    it('PlanesDeCobroController solo debe permitir ADMIN', () => {
      const roles = reflector.getAllAndOverride<RolUsuario[]>('roles', [
        PlanesDeCobroController.prototype.listar,
        PlanesDeCobroController,
      ]);
      expect(roles).toEqual([RolUsuario.ADMIN]);
    });

    it('NotificacionesController solo debe permitir ADMIN', () => {
      const roles = reflector.getAllAndOverride<RolUsuario[]>('roles', [
        NotificacionesController.prototype.listarFallidas,
        NotificacionesController,
      ]);
      expect(roles).toEqual([RolUsuario.ADMIN]);
    });

    it('MetricsController solo debe permitir ADMIN', () => {
      const roles = reflector.getAllAndOverride<RolUsuario[]>('roles', [
        MetricsController.prototype.getMetrics,
        MetricsController,
      ]);
      expect(roles).toEqual([RolUsuario.ADMIN]);
    });
  });

  describe('Segregación territorial y de residentes', () => {
    it('Dashboard de residente solo debe permitir RESIDENTE', () => {
      const roles = reflector.getAllAndOverride<RolUsuario[]>('roles', [
        DashboardController.prototype.getDashboardResidente,
        DashboardController,
      ]);
      expect(roles).toEqual([RolUsuario.RESIDENTE]);
    });

    it('Dashboard de cobrador solo debe permitir COBRADOR', () => {
      const roles = reflector.getAllAndOverride<RolUsuario[]>('roles', [
        DashboardController.prototype.getDashboardCobrador,
        DashboardController,
      ]);
      expect(roles).toEqual([RolUsuario.COBRADOR]);
    });
  });
});
