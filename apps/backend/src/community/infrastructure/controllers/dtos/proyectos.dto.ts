import { IsString, IsNotEmpty, IsOptional } from 'class-validator';

export class CrearProyectoDto {
  @IsString()
  @IsNotEmpty()
  nombre: string;

  @IsString()
  @IsNotEmpty()
  tenantId: string;
}

export class CrearEtapaDto {
  @IsString()
  @IsNotEmpty()
  nombre: string;
}

export class CrearManzanaDto {
  @IsString()
  @IsNotEmpty()
  nombre: string;
}

export class RegistrarCasaDto {
  @IsString()
  @IsNotEmpty()
  direccionInterna: string;
}
