import { IsString, IsNotEmpty, IsOptional, IsBoolean } from 'class-validator';

export class CrearProyectoDto {
  @IsString()
  @IsNotEmpty()
  nombre: string;
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

export class ActualizarAjustesProyectoDto {
  @IsOptional()
  @IsBoolean()
  recordatoriosAutomaticos?: boolean;

  @IsOptional()
  @IsBoolean()
  permitePagosParciales?: boolean;

  @IsOptional()
  @IsBoolean()
  modoMantenimiento?: boolean;
}
