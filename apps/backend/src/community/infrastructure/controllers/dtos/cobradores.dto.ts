import { IsString, IsNotEmpty, IsOptional, IsArray } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CrearCobradorDto {
  @ApiProperty({ example: 'Carlos Rodríguez', description: 'Nombre completo del cobrador' })
  @IsString()
  @IsNotEmpty()
  nombre: string;

  @ApiPropertyOptional({ example: '3001234567', description: 'Número de teléfono del cobrador' })
  @IsString()
  @IsOptional()
  telefono?: string;

  @ApiPropertyOptional({ type: [String], description: 'IDs de las etapas asignadas al cobrador' })
  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  etapaIds?: string[];
}
