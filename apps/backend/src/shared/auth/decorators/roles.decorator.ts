import { SetMetadata } from '@nestjs/common';
import { RolUsuario } from '../../../iam/domain/usuario.entity';

export const ROLES_KEY = 'roles';

/**
 * Decorador para asignar roles requeridos a un controlador o ruta.
 * Uso: @Roles(RolUsuario.ADMIN) o @Roles(RolUsuario.ADMIN, RolUsuario.COBRADOR)
 */
export const Roles = (...roles: RolUsuario[]) =>
  SetMetadata(ROLES_KEY, roles);
