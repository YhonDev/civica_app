import {
  Controller,
  Get,
  Post,
  Put,
  Patch,
  Param,
  Body,
  UseGuards,
  BadRequestException,
  NotFoundException,
  Delete,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { IsString, IsNotEmpty, IsOptional, MinLength, IsArray } from 'class-validator';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { JwtAuthGuard } from '../../../shared/auth/jwt-auth.guard';
import { RolesGuard } from '../../../shared/auth/guards/roles.guard';
import { Roles } from '../../../shared/auth/decorators/roles.decorator';
import { CurrentUser } from '../../../shared/tenant/current-user.decorator';
import { CurrentTenant } from '../../../shared/tenant/current-tenant.decorator';
import { AsignarEtapaUseCase } from '../../application/use-cases/asignar-etapa.use-case';
import { Usuario, RolUsuario } from '../../domain/usuario.entity';
import { AsignacionEtapa } from '../../domain/asignacion-etapa.entity';

class AsignarEtapaDto {
  @IsString()
  @IsNotEmpty()
  etapaId: string;
}

class AsignarEtapasBulkDto {
  @IsArray()
  @IsString({ each: true })
  etapaIds: string[];
}

class CambiarPasswordDto {
  @IsString()
  @IsNotEmpty()
  @MinLength(6, { message: 'La contraseña debe tener al menos 6 caracteres' })
  newPassword: string;
}

class ResetPasswordDto {
  @IsString()
  @IsOptional()
  @MinLength(6, { message: 'La contraseña debe tener al menos 6 caracteres' })
  password?: string; // Si no se provee, se genera una automática
}

@Controller('usuarios')
@UseGuards(JwtAuthGuard)
export class UsuariosController {
  constructor(
    @InjectRepository(AsignacionEtapa)
    private readonly asignacionRepository: Repository<AsignacionEtapa>,
    @InjectRepository(Usuario)
    private readonly usuarioRepository: Repository<Usuario>,
    private readonly asignarEtapaUseCase: AsignarEtapaUseCase,
  ) {}

  // ════════════════════════════════════════════════════════════
  // ADMIN: Gestionar usuarios y contraseñas
  // ════════════════════════════════════════════════════════════

  /**
   * Listar todos los residentes con sus emails (solo Admin).
   * Útil para el módulo Community donde Admin ve credenciales.
   * IMPORTANTE: Esta ruta DEBE estar ANTES de /:id/etapas
   * para evitar que NestJS la interprete como un :id.
   */
  @Get('residentes')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async listarResidentes(@CurrentTenant() tenantId: string) {
    const usuarios = await this.usuarioRepository.find({
      where: { tenantId, rol: RolUsuario.RESIDENTE },
      order: { nombre: 'ASC' },
    });

    return usuarios.map((u) => ({
      id: u.id,
      email: u.email,
      nombre: u.nombre,
      activo: u.activo,
      residenteId: u.residenteId,
      createdAt: u.createdAt,
    }));
  }

  @Get()
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async listar(@CurrentTenant() tenantId: string) {
    return this.usuarioRepository.find({
      where: { tenantId, rol: RolUsuario.COBRADOR },
      relations: {
        asignaciones: {
          etapa: true
        }
      }
    });
  }

  @Get(':id/etapas')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN, RolUsuario.COBRADOR)
  async obtenerEtapas(
    @Param('id') usuarioId: string,
    @CurrentUser() currentUser: Usuario,
  ) {
    // ADMIN puede ver etapas de cualquier usuario del mismo tenant
    // COBRADOR solo puede ver sus propias etapas
    if (
      currentUser.rol !== RolUsuario.ADMIN &&
      currentUser.id !== usuarioId
    ) {
      return [];
    }

    const asignaciones = await this.asignacionRepository.find({
      where: { usuarioId },
    });
    return asignaciones.map((a) => ({
      id: a.id,
      etapaId: a.etapaId,
      createdAt: a.createdAt,
    }));
  }

  @Post(':id/etapas')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async asignarEtapa(
    @Param('id') usuarioId: string,
    @Body() dto: AsignarEtapaDto,
    @CurrentUser() currentUser: Usuario,
  ) {
    return this.asignarEtapaUseCase.execute({
      usuarioId,
      etapaId: dto.etapaId,
      tenantId: currentUser.tenantId,
    });
  }

  @Put(':id/etapas')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async reemplazarEtapas(
    @Param('id') usuarioId: string,
    @Body() dto: AsignarEtapasBulkDto,
    @CurrentUser() currentUser: Usuario,
  ) {
    await this.asignacionRepository.delete({ usuarioId });
    const asignaciones = dto.etapaIds.map((etapaId) =>
      AsignacionEtapa.crear(usuarioId, etapaId, currentUser.tenantId),
    );
    if (asignaciones.length > 0) {
      await this.asignacionRepository.save(asignaciones);
    }
    return { success: true, count: asignaciones.length };
  }

  @Delete(':id/etapas/:etapaId')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async desasignarEtapa(
    @Param('id') usuarioId: string,
    @Param('etapaId') etapaId: string,
  ) {
    const result = await this.asignacionRepository.delete({
      usuarioId,
      etapaId,
    });
    if (result.affected === 0) {
      throw new NotFoundException('Asignación no encontrada');
    }
    return { success: true };
  }

  /**
   * Cambiar contraseña de un usuario (solo Admin).
   * PATCH /usuarios/:id/password
   */
  @Patch(':id/password')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async cambiarPassword(
    @Param('id') usuarioId: string,
    @Body() dto: CambiarPasswordDto,
    @CurrentUser() currentUser: Usuario,
  ) {
    const usuario = await this.usuarioRepository.findOne({
      where: { id: usuarioId, tenantId: currentUser.tenantId },
    });

    if (!usuario) {
      throw new NotFoundException('Usuario no encontrado');
    }

    const passwordHash = await bcrypt.hash(dto.newPassword, 10);
    usuario.passwordHash = passwordHash;
    await this.usuarioRepository.save(usuario);

    return {
      message: `Contraseña actualizada para ${usuario.nombre}`,
      email: usuario.email,
    };
  }

  /**
   * Resetear contraseña de un usuario a una temporal (solo Admin).
   * Si no se provee password, se genera una automáticamente.
   * POST /usuarios/:id/reset-password
   */
  @Post(':id/reset-password')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async resetearPassword(
    @Param('id') usuarioId: string,
    @Body() dto: ResetPasswordDto,
    @CurrentUser() currentUser: Usuario,
  ) {
    const usuario = await this.usuarioRepository.findOne({
      where: { id: usuarioId, tenantId: currentUser.tenantId },
    });

    if (!usuario) {
      throw new NotFoundException('Usuario no encontrado');
    }

    // Generar contraseña temporal si no se provee
    const tempPassword = dto.password || this.generarPasswordTemporal();
    const passwordHash = await bcrypt.hash(tempPassword, 10);
    usuario.passwordHash = passwordHash;
    await this.usuarioRepository.save(usuario);

    return {
      message: `Contraseña reseteada para ${usuario.nombre}`,
      email: usuario.email,
      tempPassword: tempPassword, // Solo se muestra una vez
    };
  }

  /**
   * Genera una contraseña temporal con el patrón Civica+year+!+4digits
   */
  private generarPasswordTemporal(): string {
    const year = new Date().getFullYear();
    const digits = String(Math.floor(1000 + Math.random() * 9000));
    return `Civica${year}!${digits}`;
  }
}
