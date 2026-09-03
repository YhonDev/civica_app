import {
  IsString,
  IsNotEmpty,
  IsOptional,
  MinLength,
  IsEnum,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { RolUsuario } from '../../../domain/usuario.entity';

export class RegisterDto {
  @ApiProperty({
    example: 'admin@civica.com',
    description: 'Email del usuario (se usa como username)',
  })
  @IsString()
  @IsNotEmpty({ message: 'El nombre de usuario es requerido' })
  username: string;

  @ApiProperty({
    example: 'SecureP@ss123',
    minLength: 6,
    description: 'Contraseña (mínimo 6 caracteres)',
  })
  @IsString()
  @IsNotEmpty()
  @MinLength(6, { message: 'La contraseña debe tener al menos 6 caracteres' })
  password: string;

  @ApiProperty({
    example: 'Juan Pérez',
    description: 'Nombre completo del usuario',
  })
  @IsString()
  @IsNotEmpty()
  @MinLength(2, { message: 'El nombre debe tener al menos 2 caracteres' })
  nombre: string;

  @ApiProperty({ enum: RolUsuario, description: 'Rol del usuario' })
  @IsEnum(RolUsuario, {
    message: 'El rol debe ser ADMIN, COBRADOR o RESIDENTE',
  })
  rol: RolUsuario;

  @ApiPropertyOptional({
    description: 'Tenant ID (asignado automáticamente en la mayoría de casos)',
  })
  @IsString()
  @IsOptional()
  tenantId?: string;

  @ApiPropertyOptional({
    description: 'ID del residente asociado (solo para rol RESIDENTE)',
  })
  @IsString()
  @IsOptional()
  residenteId?: string;
}

export class LoginDto {
  @ApiProperty({
    example: 'admin@civica.com',
    description: 'Email / username del usuario',
  })
  @IsString()
  @IsNotEmpty({ message: 'El nombre de usuario es requerido' })
  username: string;

  @ApiProperty({
    example: 'SecureP@ss123',
    description: 'Contraseña del usuario',
  })
  @IsString()
  @IsNotEmpty({ message: 'La contraseña es requerida' })
  password: string;

  @ApiPropertyOptional({ description: 'ID único del dispositivo' })
  @IsString()
  @IsOptional()
  deviceId?: string;

  @ApiPropertyOptional({ description: 'Nombre descriptivo del dispositivo' })
  @IsString()
  @IsOptional()
  deviceName?: string;
}

export class RefreshDto {
  @ApiProperty({ description: 'Refresh token obtenido en el login' })
  @IsString()
  @IsNotEmpty({ message: 'El token de refresco es requerido' })
  refreshToken: string;
}
