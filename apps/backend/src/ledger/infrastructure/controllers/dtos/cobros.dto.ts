import { IsString, IsNotEmpty, IsOptional, IsNumber } from 'class-validator';

export class CrearCobroDto {
  @IsString()
  @IsNotEmpty()
  residenteId: string;

  @IsString()
  @IsNotEmpty()
  tenantId: string;

  @IsString()
  @IsOptional()
  periodoId?: string;

  @IsString()
  @IsOptional()
  casaId?: string;

  @IsNumber()
  @IsNotEmpty()
  monto: number;

  @IsString()
  @IsNotEmpty()
  concepto: string;

  @IsString()
  @IsNotEmpty()
  periodoInicio: string;

  @IsString()
  @IsNotEmpty()
  periodoFin: string;

  @IsString()
  @IsNotEmpty()
  fechaVencimiento: string;
}
