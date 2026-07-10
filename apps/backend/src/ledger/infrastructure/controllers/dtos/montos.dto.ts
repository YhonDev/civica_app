import {
  IsString,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  Min,
  MinLength,
} from 'class-validator';

export class CrearMontoDto {
  @IsString()
  @IsNotEmpty()
  conjuntoId: string;

  @IsNumber()
  @Min(1, { message: 'El monto debe ser mayor a cero' })
  monto: number;

  @IsString()
  @IsNotEmpty()
  @MinLength(2, { message: 'La descripción debe tener al menos 2 caracteres' })
  descripcion: string;
}

export class ListarMontosQueryDto {
  @IsString()
  @IsNotEmpty()
  conjuntoId: string;
}
