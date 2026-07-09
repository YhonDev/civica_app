import {
  IsString,
  IsNotEmpty,
  IsOptional,
  MinLength,
  IsDateString,
} from 'class-validator';

export class RegistrarPropietarioDto {
  @IsString()
  @IsNotEmpty()
  @MinLength(2)
  nombre: string;

  @IsString()
  @IsNotEmpty()
  telefono: string;

  @IsString()
  @IsOptional()
  email?: string;

  @IsString()
  @IsNotEmpty()
  tenantId: string;

  @IsString()
  @IsOptional()
  casaId?: string;

  @IsDateString()
  @IsOptional()
  fechaInicio?: string;
}
