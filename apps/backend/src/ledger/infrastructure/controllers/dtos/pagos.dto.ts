import {
  IsString,
  IsNotEmpty,
  IsNumber,
  IsDateString,
  Min,
  IsOptional,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class RegistrarPagoDto {
  @ApiProperty({
    example: 'PAY-20260901-001',
    description: 'ID único del pago generado por el cliente (idempotencia)',
  })
  @IsString()
  @IsNotEmpty()
  clientPaymentId: string;

  @ApiProperty({
    example: 4000000,
    description: 'Monto en centavos COP (ej: 4000000 = $40.000 COP)',
  })
  @IsNumber()
  @Min(1, { message: 'El monto debe ser mayor a cero (en centavos)' })
  monto: number;

  @ApiProperty({
    example: '2026-09-01',
    description: 'Fecha del pago (ISO date)',
  })
  @IsDateString({}, { message: 'fechaPago debe ser una fecha ISO válida' })
  fechaPago: string;

  @ApiProperty({ description: 'UUID del residente que realiza el pago' })
  @IsString()
  @IsNotEmpty()
  residenteId: string;

  @ApiPropertyOptional({
    description:
      'UUID de la solicitud asociada (cierra la solicitud al registrar el pago)',
  })
  @IsOptional()
  @IsString()
  solicitudId?: string;
}
