import {
  IsString,
  IsNotEmpty,
  IsNumber,
  IsEnum,
  IsDateString,
  IsOptional,
  Min,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { type ModalidadRecaudo } from '../../../../shared/common/value-objects';

export class CrearTarifaDto {
  @ApiProperty({ description: 'UUID del proyecto' })
  @IsString()
  @IsNotEmpty()
  proyectoId: string;

  @ApiProperty({
    enum: ['SEMANAL', 'QUINCENAL', 'MENSUAL'],
    description: 'Modalidad de recaudo',
  })
  @IsEnum(['SEMANAL', 'QUINCENAL', 'MENSUAL'] as const, {
    message: 'La modalidad debe ser SEMANAL, QUINCENAL o MENSUAL',
  })
  modalidad: ModalidadRecaudo;

  @ApiProperty({ example: 4000000, description: 'Monto en centavos COP' })
  @IsNumber()
  @Min(1, { message: 'El monto debe ser mayor a cero' })
  monto: number;

  @ApiProperty({
    example: '2026-09-01',
    description: 'Fecha de vigencia desde (ISO date)',
  })
  @IsDateString({}, { message: 'fechaVigencia debe ser una fecha válida' })
  fechaVigencia: string;
}

export class ActualizarTarifaDto {
  @ApiPropertyOptional({
    example: 4500000,
    description: 'Nuevo monto en centavos COP',
  })
  @IsNumber()
  @Min(1)
  @IsOptional()
  monto?: number;

  @ApiPropertyOptional({
    example: '2026-10-01',
    description: 'Nueva fecha de vigencia',
  })
  @IsDateString()
  @IsOptional()
  fechaVigencia?: string;
}

export class ListarTarifasQueryDto {
  @ApiPropertyOptional({ description: 'Filtrar por UUID del proyecto' })
  @IsString()
  @IsOptional()
  proyectoId?: string;
}

export class TarifasVigentesQueryDto {
  @ApiProperty({ description: 'UUID del proyecto (requerido)' })
  @IsString()
  @IsNotEmpty({ message: 'proyectoId es requerido' })
  proyectoId: string;
}
