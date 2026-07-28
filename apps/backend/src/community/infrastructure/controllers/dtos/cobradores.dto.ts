import { IsString, IsNotEmpty, IsOptional, IsArray } from 'class-validator';

export class CrearCobradorDto {
  @IsString()
  @IsNotEmpty()
  nombre: string;

  @IsString()
  @IsOptional()
  telefono?: string;

  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  etapaIds?: string[];
}
