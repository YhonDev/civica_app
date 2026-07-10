import { IsString, IsOptional, IsEnum } from 'class-validator';
import { type EstadoCuota } from '../../../../shared/common/value-objects';

export class GenerarCuotasDto {
  @IsString()
  @IsOptional()
  conjuntoId?: string;
}

export class ListarCuotasQueryDto {
  @IsString()
  @IsOptional()
  estado?: string;

  @IsEnum(['PENDIENTE', 'PARCIAL', 'PAGADA', 'VENCIDA'] as const)
  @IsOptional()
  estadoFilter?: EstadoCuota;
}
