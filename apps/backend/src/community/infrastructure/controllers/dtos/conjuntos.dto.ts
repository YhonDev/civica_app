import { IsString, IsNotEmpty, MinLength } from 'class-validator';

export class CrearConjuntoDto {
  @IsString()
  @IsNotEmpty()
  @MinLength(2)
  nombre: string;

  @IsString()
  @IsNotEmpty()
  tenantId: string;
}

export class CrearEtapaDto {
  @IsString()
  @IsNotEmpty()
  @MinLength(2)
  nombre: string;
}

export class RegistrarCasaDto {
  @IsString()
  @IsNotEmpty()
  direccionInterna: string;
}
