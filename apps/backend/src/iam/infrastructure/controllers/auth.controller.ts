import {
  Controller,
  Post,
  Body,
  UseGuards,
} from '@nestjs/common';
import { AuthService } from '../../../shared/auth/auth.service';
import { JwtAuthGuard } from '../../../shared/auth/jwt-auth.guard';
import { RolesGuard } from '../../../shared/auth/guards/roles.guard';
import { Roles } from '../../../shared/auth/decorators/roles.decorator';
import { CurrentUser } from '../../../shared/tenant/current-user.decorator';
import { CrearUsuarioUseCase } from '../../application/use-cases/crear-usuario.use-case';
import { Usuario, RolUsuario } from '../../domain/usuario.entity';
import { RegisterDto, LoginDto, RefreshDto } from './dtos/auth.dto';

@Controller('auth')
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly crearUsuarioUseCase: CrearUsuarioUseCase,
  ) {}

  @Post('register')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async register(@Body() dto: RegisterDto) {
    return this.crearUsuarioUseCase.execute({
      email: dto.email,
      password: dto.password,
      nombre: dto.nombre,
      rol: dto.rol,
      tenantId: dto.tenantId,
      propietarioId: dto.propietarioId,
    });
  }

  @Post('login')
  async login(@Body() dto: LoginDto) {
    const usuario = await this.authService.validateUser(
      dto.email,
      dto.password,
    );
    return this.authService.login(usuario);
  }

  @Post('refresh')
  async refresh(@Body() dto: RefreshDto) {
    return this.authService.refreshToken(dto.refreshToken);
  }
}
