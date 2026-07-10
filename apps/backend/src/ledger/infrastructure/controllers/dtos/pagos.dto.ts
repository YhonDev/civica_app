import { IsString, IsNotEmpty, IsNumber, IsDateString, Min } from 'class-validator';

export class RegistrarPagoDto {
  @IsString()
  @IsNotEmpty()
  clientPaymentId: string;

  @IsNumber()
  @Min(1, { message: 'El monto debe ser mayor a cero (en centavos)' })
  monto: number;

  @IsDateString({}, { message: 'fechaPago debe ser una fecha ISO válida' })
  fechaPago: string;

  @IsString()
  @IsNotEmpty()
  propietarioId: string;
}
