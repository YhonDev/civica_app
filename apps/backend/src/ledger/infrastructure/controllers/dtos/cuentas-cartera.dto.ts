import {
  IsString,
  IsNotEmpty,
  IsEnum,
  IsDateString,
} from 'class-validator';
import { type Frecuencia } from '../../../../shared/common/value-objects';

export class CrearCuentaCarteraDto {
  @IsString()
  @IsNotEmpty()
  propietarioId: string;

  @IsString()
  @IsNotEmpty()
  conjuntoId: string;

  @IsEnum(['SEMANAL', 'QUINCENAL', 'MENSUAL'] as const, {
    message: 'La frecuencia debe ser SEMANAL, QUINCENAL o MENSUAL',
  })
  frecuencia: Frecuencia;

  @IsDateString({}, { message: 'fechaActivacion debe ser una fecha válida' })
  fechaActivacion: string;
}

export class ActualizarFrecuenciaDto {
  @IsEnum(['SEMANAL', 'QUINCENAL', 'MENSUAL'] as const, {
    message: 'La frecuencia debe ser SEMANAL, QUINCENAL o MENSUAL',
  })
  frecuencia: Frecuencia;
}
