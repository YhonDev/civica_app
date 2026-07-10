import {
  IsString,
  IsEmail,
  IsNotEmpty,
  IsOptional,
  MinLength,
  IsEnum,
} from 'class-validator';
import { RolUsuario } from '../../../domain/usuario.entity';

export class RegisterDto {
  @IsEmail({}, { message: 'El email debe tener un formato válido' })
  email: string;

  @IsString()
  @IsNotEmpty()
  @MinLength(6, { message: 'La contraseña debe tener al menos 6 caracteres' })
  password: string;

  @IsString()
  @IsNotEmpty()
  @MinLength(2, { message: 'El nombre debe tener al menos 2 caracteres' })
  nombre: string;

  @IsEnum(RolUsuario, { message: 'El rol debe ser ADMIN, COBRADOR o PROPIETARIO' })
  rol: RolUsuario;

  @IsString()
  @IsNotEmpty({ message: 'El tenantId es requerido' })
  tenantId: string;

  @IsString()
  @IsOptional()
  propietarioId?: string;
}

export class LoginDto {
  @IsEmail({}, { message: 'El email debe tener un formato válido' })
  email: string;

  @IsString()
  @IsNotEmpty({ message: 'La contraseña es requerida' })
  password: string;
}

export class RefreshDto {
  @IsString()
  @IsNotEmpty({ message: 'El token de refresco es requerido' })
  refreshToken: string;
}
