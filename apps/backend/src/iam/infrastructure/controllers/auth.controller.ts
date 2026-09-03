import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Req,
  UseGuards,
} from '@nestjs/common';
import type { Request } from 'express';
import { Throttle } from '@nestjs/throttler';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { AuthService } from '../../../shared/auth/auth.service';
import { CrearUsuarioUseCase } from '../../application/use-cases/crear-usuario.use-case';
import { RegisterDto, LoginDto, RefreshDto } from './dtos/auth.dto';
import { JwtAuthGuard } from '../../../shared/auth/jwt-auth.guard';
import { RolesGuard } from '../../../shared/auth/guards/roles.guard';
import { Roles } from '../../../shared/auth/decorators/roles.decorator';
import { CurrentTenant } from '../../../shared/tenant/current-tenant.decorator';
import { CurrentUser } from '../../../shared/tenant/current-user.decorator';
import { RolUsuario, Usuario } from '../../../iam/domain/usuario.entity';

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly crearUsuarioUseCase: CrearUsuarioUseCase,
  ) {}

  @Post('register')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RolUsuario.ADMIN)
  @ApiBearerAuth('jwt-auth')
  @ApiOperation({ summary: 'Registrar usuario (solo ADMIN)' })
  @ApiResponse({ status: 201, description: 'Usuario creado exitosamente' })
  @ApiResponse({ status: 401, description: 'No autenticado' })
  @ApiResponse({ status: 403, description: 'Sin permisos de ADMIN' })
  async register(@Body() dto: RegisterDto, @CurrentTenant() tenantId: string) {
    return this.crearUsuarioUseCase.execute({
      username: dto.username,
      password: dto.password,
      nombre: dto.nombre,
      rol: dto.rol,
      tenantId,
      residenteId: dto.residenteId,
    });
  }

  /** Login: 5 intentos por minuto para prevenir fuerza bruta. */
  @Post('login')
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @ApiOperation({
    summary: 'Iniciar sesión',
    description: 'Rate limit: 5 intentos por minuto',
  })
  @ApiResponse({
    status: 200,
    description:
      'Login exitoso — retorna accessToken, refreshToken y datos del usuario',
  })
  @ApiResponse({ status: 401, description: 'Credenciales inválidas' })
  @ApiResponse({
    status: 429,
    description: 'Demasiados intentos — intenta en 1 minuto',
  })
  async login(@Body() dto: LoginDto, @Req() req: any) {
    const usuario = await this.authService.validateUser(
      dto.username,
      dto.password,
    );

    const ipAddress = req?.headers
      ? (req.headers['x-forwarded-for'] as string) ||
        req.socket?.remoteAddress ||
        undefined
      : undefined;
    const userAgent = req?.headers
      ? req.headers['user-agent'] || undefined
      : undefined;

    return this.authService.login(usuario, {
      deviceId: dto.deviceId,
      deviceName: dto.deviceName,
      ipAddress,
      userAgent,
    });
  }

  @Post('refresh')
  @ApiOperation({
    summary: 'Refrescar tokens',
    description:
      'Intercambia un refresh token válido por nuevos tokens con rotación',
  })
  @ApiResponse({ status: 200, description: 'Tokens renovados' })
  @ApiResponse({
    status: 401,
    description: 'Refresh token inválido, expirado o revocado',
  })
  async refresh(@Body() dto: RefreshDto) {
    return this.authService.refreshToken(dto.refreshToken);
  }

  @Post('logout')
  @ApiOperation({
    summary: 'Cerrar sesión',
    description: 'Revoca la sesión actual en la base de datos',
  })
  @ApiResponse({ status: 200, description: 'Sesión cerrada' })
  async logout(@Body() dto: { refreshToken?: string }) {
    if (dto.refreshToken) {
      await this.authService.revokeRefreshToken(dto.refreshToken);
    }
    return { success: true };
  }

  @Post('logout-all')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('jwt-auth')
  @ApiOperation({ summary: 'Cerrar todas las sesiones activas del usuario' })
  @ApiResponse({
    status: 200,
    description: 'Todas las sesiones fueron revocadas',
  })
  async logoutAll(@CurrentUser() user: Usuario) {
    await this.authService.revokeAllSessionsForUser(user.id);
    return { success: true, message: 'Todas las sesiones fueron cerradas.' };
  }

  @Get('sessions')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('jwt-auth')
  @ApiOperation({ summary: 'Listar sesiones activas del usuario' })
  @ApiResponse({ status: 200, description: 'Lista de sesiones activas' })
  async getSessions(@CurrentUser() user: Usuario) {
    return this.authService.getUserSessions(user.id);
  }

  @Delete('sessions/:id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('jwt-auth')
  @ApiOperation({ summary: 'Revocar una sesión específica' })
  @ApiResponse({ status: 200, description: 'Sesión revocada' })
  async revokeSession(
    @Param('id') sessionId: string,
    @CurrentUser() user: Usuario,
  ) {
    await this.authService.revokeSessionById(sessionId, user.id);
    return { success: true, message: 'Sesión revocada exitosamente.' };
  }

  @Post('reset-password')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RolUsuario.ADMIN)
  @ApiBearerAuth('jwt-auth')
  @ApiOperation({ summary: 'Resetear contraseña de usuario (solo ADMIN)' })
  @ApiResponse({ status: 200, description: 'Nueva contraseña generada' })
  async resetPassword(
    @Body() dto: { residenteId?: string; usuarioId?: string },
    @CurrentTenant() tenantId: string,
  ) {
    return this.authService.resetPasswordForUser({
      residenteId: dto.residenteId,
      usuarioId: dto.usuarioId,
      tenantId,
    });
  }

  /** Admin: obtiene el username de cualquier usuario. */
  @Get('credentials/:usuarioId')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RolUsuario.ADMIN)
  @ApiBearerAuth('jwt-auth')
  @ApiOperation({ summary: 'Obtener credenciales de usuario (solo ADMIN)' })
  @ApiResponse({ status: 200, description: 'Username del usuario' })
  async getCredentials(
    @Param('usuarioId') usuarioId: string,
    @CurrentTenant() tenantId: string,
  ) {
    return this.authService.getCredentials(usuarioId, tenantId);
  }

  /** Admin o propio: actualiza username y/o password. */
  @Patch('credentials')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RolUsuario.ADMIN, RolUsuario.RESIDENTE, RolUsuario.COBRADOR)
  @ApiBearerAuth('jwt-auth')
  @ApiOperation({ summary: 'Actualizar credenciales (username y/o password)' })
  @ApiResponse({ status: 200, description: 'Credenciales actualizadas' })
  async updateCredentials(
    @Body()
    dto: {
      usuarioId?: string;
      currentPassword?: string;
      newUsername?: string;
      newPassword?: string;
    },
    @CurrentTenant() tenantId: string,
    @CurrentUser() user: Usuario,
  ) {
    const targetId =
      user.rol === RolUsuario.ADMIN ? (dto.usuarioId ?? user.id) : user.id;

    return this.authService.updateCredentials({
      usuarioId: targetId,
      tenantId,
      newUsername: dto.newUsername,
      newPassword: dto.newPassword,
      currentPassword: dto.currentPassword,
    });
  }
}
