import { Body, Controller, Post, Req } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { IsEmail, IsNotEmpty, IsString, MinLength } from 'class-validator';
import type { Request } from 'express';
import { PlatformAuthService } from '../../application/platform-auth.service';
import { PlatformInvitationService } from '../../application/platform-invitation.service';

class PlatformLoginDto {
  @IsEmail()
  email: string;

  @IsString()
  @IsNotEmpty()
  password: string;
}

class AcceptInvitationDto {
  @IsString()
  @IsNotEmpty({ message: 'El token de invitación es obligatorio' })
  token: string;

  @IsString()
  @MinLength(8, { message: 'La contraseña debe tener al menos 8 caracteres' })
  password: string;
}

@ApiTags('Platform Auth')
@Controller('platform/auth')
export class PlatformAuthController {
  constructor(
    private readonly authService: PlatformAuthService,
    private readonly invitationService: PlatformInvitationService,
  ) {}

  @Post('login')
  @ApiOperation({ summary: 'Autenticación exclusiva de Cuentiva Platform' })
  login(@Body() dto: PlatformLoginDto, @Req() request: Request) {
    return this.authService.login(
      dto.email,
      dto.password,
      request.header('x-request-id') ?? undefined,
    );
  }

  @Post('accept-invitation')
  @ApiOperation({
    summary:
      'Acepta una invitación de administrador de tenant y establece su contraseña',
  })
  acceptInvitation(@Body() dto: AcceptInvitationDto, @Req() request: Request) {
    return this.invitationService.acceptInvitation(
      dto.token,
      dto.password,
      request.header('x-request-id') ?? undefined,
      request.ip,
    );
  }
}
