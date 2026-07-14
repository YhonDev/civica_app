import {
  IsString,
  IsNotEmpty,
  IsNumber,
  IsEnum,
  IsDateString,
  IsOptional,
  Min,
} from 'class-validator';
import { type ModalidadRecaudo } from '../../../../shared/common/value-objects';

export class CrearTarifaDto {
  @IsString()
  @IsNotEmpty()
  proyectoId: string;

  @IsEnum(['SEMANAL', 'QUINCENAL', 'MENSUAL'] as const, {
    message: 'La modalidad debe ser SEMANAL, QUINCENAL o MENSUAL',
  })
  modalidad: ModalidadRecaudo;

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
  proyectoId?: string;
}

export class TarifasVigentesQueryDto {
  @IsString()
  @IsNotEmpty({ message: 'proyectoId es requerido' })
  proyectoId: string;
}
