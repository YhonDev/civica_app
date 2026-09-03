import { IsString, IsNotEmpty, IsOptional } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class RegistrarResidenteDto {
  @ApiProperty({
    example: 'María García',
    description: 'Nombre completo del residente',
  })
  @IsString()
  @IsNotEmpty()
  nombre: string;

  @ApiProperty({ example: '3109876543', description: 'Número de teléfono' })
  @IsString()
  @IsNotEmpty()
  telefono: string;

  @ApiPropertyOptional({
    example: 'maria@email.com',
    description: 'Email del residente',
  })
  @IsString()
  @IsOptional()
  email?: string;

  @ApiPropertyOptional({ description: 'ID de la casa a asignar' })
  @IsString()
  @IsOptional()
  casaId?: string;

  @ApiPropertyOptional({
    example: '2026-09-01',
    description: 'Fecha de inicio de tenencia (ISO date)',
  })
  @IsString()
  @IsOptional()
  fechaInicio?: string;

  @ApiPropertyOptional({
    enum: ['SEMANAL', 'QUINCENAL', 'MENSUAL'],
    description: 'Modalidad de pago del residente',
  })
  @IsString()
  @IsOptional()
  modalidadPago?: string;
}
