import {
  IsString,
  IsNotEmpty,
  IsOptional,
  MinLength,
  IsDateString,
  IsIn,
} from 'class-validator';
import { type Frecuencia } from '../../../../shared/common/value-objects';

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

  @IsString()
  @IsOptional()
  @IsIn(['SEMANAL', 'QUINCENAL', 'MENSUAL'])
  modalidadPago?: Frecuencia;
}
