import {
  IsString,
  IsNotEmpty,
  IsNumber,
  IsEnum,
  IsDateString,
  IsOptional,
  Min,
} from 'class-validator';
import { type Frecuencia } from '../../../../shared/common/value-objects';

export class CrearTarifaDto {
  @IsString()
  @IsNotEmpty()
  conjuntoId: string;

  @IsEnum(['SEMANAL', 'QUINCENAL', 'MENSUAL'] as const, {
    message: 'La frecuencia debe ser SEMANAL, QUINCENAL o MENSUAL',
  })
  frecuencia: Frecuencia;

  @IsNumber()
  @Min(1, { message: 'El monto debe ser mayor a cero' })
  monto: number;

  @IsDateString({}, { message: 'fechaVigencia debe ser una fecha válida' })
  fechaVigencia: string;
}

export class ActualizarTarifaDto {
  @IsNumber()
  @Min(1)
  @IsOptional()
  monto?: number;

  @IsDateString()
  @IsOptional()
  fechaVigencia?: string;
}

export class ListarTarifasQueryDto {
  @IsString()
  @IsOptional()
  conjuntoId?: string;
}
