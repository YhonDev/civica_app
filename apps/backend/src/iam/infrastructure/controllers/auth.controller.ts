import {
  Controller,
  Post,
  Body,
} from '@nestjs/common';
import { AuthService } from '../../../shared/auth/auth.service';
import { CrearUsuarioUseCase } from '../../application/use-cases/crear-usuario.use-case';
import { RegisterDto, LoginDto, RefreshDto } from './dtos/auth.dto';

@Controller('auth')
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly crearUsuarioUseCase: CrearUsuarioUseCase,
  ) {}

  @Post('register')
  async register(@Body() dto: RegisterDto) {
    return this.crearUsuarioUseCase.execute({
      email: dto.email,
      password: dto.password,
      nombre: dto.nombre,
      rol: dto.rol,
      tenantId: dto.tenantId,
      residenteId: dto.residenteId,
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
