import { IsString, IsNotEmpty, IsOptional, IsBoolean } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CrearProyectoDto {
  @ApiProperty({
    example: 'Residencial El Parque',
    description: 'Nombre del proyecto urbanístico',
  })
  @IsString()
  @IsNotEmpty()
  nombre: string;
}

export class CrearEtapaDto {
  @ApiProperty({ example: 'Etapa 1', description: 'Nombre de la etapa' })
  @IsString()
  @IsNotEmpty()
  nombre: string;
}

export class CrearManzanaDto {
  @ApiProperty({ example: 'Manzana A', description: 'Nombre de la manzana' })
  @IsString()
  @IsNotEmpty()
  nombre: string;
}

export class RegistrarCasaDto {
  @ApiProperty({
    example: 'Casa 101',
    description: 'Dirección interna de la casa',
  })
  @IsString()
  @IsNotEmpty()
  direccionInterna: string;
}

export class ActualizarAjustesProyectoDto {
  @ApiPropertyOptional({
    description: 'Habilitar recordatorios automáticos de cobro',
  })
  @IsOptional()
  @IsBoolean()
  recordatoriosAutomaticos?: boolean;

  @ApiPropertyOptional({ description: 'Permitir pagos parciales' })
  @IsOptional()
  @IsBoolean()
  permitePagosParciales?: boolean;

  @ApiPropertyOptional({ description: 'Activar/desactivar modo mantenimiento' })
  @IsOptional()
  @IsBoolean()
  modoMantenimiento?: boolean;
}
