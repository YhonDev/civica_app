import {
  IsString,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  Min,
  MinLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CrearMontoDto {
  @ApiProperty({ description: 'UUID del proyecto' })
  @IsString()
  @IsNotEmpty()
  proyectoId: string;

  @ApiProperty({ example: 5000000, description: 'Monto en centavos COP' })
  @IsNumber()
  @Min(1, { message: 'El monto debe ser mayor a cero' })
  monto: number;

  @ApiProperty({
    example: 'Cuota de administración mensual',
    description: 'Descripción del monto',
  })
  @IsString()
  @IsNotEmpty()
  @MinLength(2, { message: 'La descripción debe tener al menos 2 caracteres' })
  descripcion: string;
}

export class ListarMontosQueryDto {
  @ApiProperty({ description: 'UUID del proyecto' })
  @IsString()
  @IsNotEmpty()
  proyectoId: string;
}
