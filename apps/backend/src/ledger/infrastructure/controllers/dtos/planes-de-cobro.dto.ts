import { IsString, IsNotEmpty, IsOptional, IsBoolean } from 'class-validator';

export class CrearPlanDeCobroDto {
  @IsString()
  @IsNotEmpty()
  casaId: string;

  @IsString()
  @IsNotEmpty()
  residenteId: string;

  @IsString()
  @IsNotEmpty()
  tenantId: string;

  @IsString()
  @IsNotEmpty()
  proyectoId: string;

  @IsString()
  @IsNotEmpty()
  modalidad: string;

  @IsString()
  @IsNotEmpty()
  fechaActivacion: string;

  @IsString()
  @IsOptional()
  valorMensual?: number;
}
