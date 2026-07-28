import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  UseGuards,
} from '@nestjs/common';
import { AuthService } from '../../../shared/auth/auth.service';
import { CrearUsuarioUseCase } from '../../application/use-cases/crear-usuario.use-case';
import { RegisterDto, LoginDto, RefreshDto } from './dtos/auth.dto';
import { JwtAuthGuard } from '../../../shared/auth/jwt-auth.guard';
import { RolesGuard } from '../../../shared/auth/guards/roles.guard';
import { Roles } from '../../../shared/auth/decorators/roles.decorator';
import { CurrentTenant } from '../../../shared/tenant/current-tenant.decorator';
import { CurrentUser } from '../../../shared/tenant/current-user.decorator';
import { RolUsuario, Usuario } from '../../../iam/domain/usuario.entity';

@Controller('auth')
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly crearUsuarioUseCase: CrearUsuarioUseCase,
  ) {}

  @Post('register')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async register(
    @Body() dto: RegisterDto,
    @CurrentTenant() tenantId: string,
  ) {
    return this.crearUsuarioUseCase.execute({
      username: dto.username,
      password: dto.password,
      nombre: dto.nombre,
      rol: dto.rol,
      tenantId,
      residenteId: dto.residenteId,
    });
  }

  @Post('login')
  async login(@Body() dto: LoginDto) {
    const usuario = await this.authService.validateUser(
      dto.username,
      dto.password,
    );
    return this.authService.login(usuario);
  }

  @Post('refresh')
  async refresh(@Body() dto: RefreshDto) {
    return this.authService.refreshToken(dto.refreshToken);
  }

  @Post('logout')
  async logout(@Body() dto: { refreshToken?: string }) {
    if (dto.refreshToken) {
      this.authService.revokeRefreshToken(dto.refreshToken);
    }
    return { success: true };
  }

  @Post('reset-password')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RolUsuario.ADMIN)
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
  async updateCredentials(
    @Body() dto: {
      usuarioId?: string;
      currentPassword?: string;
      newUsername?: string;
      newPassword?: string;
    },
    @CurrentTenant() tenantId: string,
    @CurrentUser() user: Usuario,
  ) {
    // Si no es admin, solo puede modificar sus propias credenciales
    const targetId = user.rol === RolUsuario.ADMIN
      ? (dto.usuarioId ?? user.id)
      : user.id;

    return this.authService.updateCredentials({
      usuarioId: targetId,
      tenantId,
      newUsername: dto.newUsername,
      newPassword: dto.newPassword,
      currentPassword: dto.currentPassword,
    });
  }
}
