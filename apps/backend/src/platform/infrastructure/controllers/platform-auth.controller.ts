import { Body, Controller, Post, Req } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { IsEmail, IsNotEmpty, IsString } from 'class-validator';
import type { Request } from 'express';
import { PlatformAuthService } from '../../application/platform-auth.service';

class PlatformLoginDto {
  @IsEmail()
  email: string;

  @IsString()
  @IsNotEmpty()
  password: string;
}

@ApiTags('Platform Auth')
@Controller('platform/auth')
export class PlatformAuthController {
  constructor(private readonly authService: PlatformAuthService) {}

  @Post('login')
  @ApiOperation({ summary: 'Autenticación exclusiva de Cuentiva Platform' })
  login(@Body() dto: PlatformLoginDto, @Req() request: Request) {
    return this.authService.login(
      dto.email,
      dto.password,
      request.header('x-request-id') ?? undefined,
    );
  }
}
