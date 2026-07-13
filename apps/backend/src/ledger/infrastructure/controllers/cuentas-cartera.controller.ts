import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  UseGuards,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { CuentaCarteraRepository } from '../persistence/cuenta-cartera.repository';
import { CuentaDeCartera } from '../../domain/cuenta-de-cartera.entity';
import {
  CrearCuentaCarteraDto,
  ActualizarFrecuenciaDto,
} from './dtos/cuentas-cartera.dto';
import { JwtAuthGuard } from '../../../shared/auth/jwt-auth.guard';
import { RolesGuard } from '../../../shared/auth/guards/roles.guard';
import { Roles } from '../../../shared/auth/decorators/roles.decorator';
import { CurrentTenant } from '../../../shared/tenant/current-tenant.decorator';
import { RolUsuario } from '../../../iam/domain/usuario.entity';

@Controller('cuentas-cartera')
@UseGuards(JwtAuthGuard)
export class CuentasCarteraController {
  constructor(
    private readonly cuentaCarteraRepository: CuentaCarteraRepository,
  ) {}

  @Post()
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async crear(
    @Body() dto: CrearCuentaCarteraDto,
    @CurrentTenant() tenantId: string,
  ) {
    // Check: propietario must not already have an account
    const existing =
      await this.cuentaCarteraRepository.findByPropietario(
        dto.propietarioId,
      );
    if (existing) {
      throw new BadRequestException(
        'El propietario ya tiene una cuenta de cartera',
      );
    }

    const cuenta = CuentaDeCartera.crear(
      dto.propietarioId,
      tenantId,
      dto.conjuntoId,
      dto.frecuencia,
      dto.fechaActivacion,
    );

    return this.cuentaCarteraRepository.save(cuenta);
  }

  @Get(':propietarioId')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN, RolUsuario.PROPIETARIO)
  async obtenerPorPropietario(
    @Param('propietarioId') propietarioId: string,
  ) {
    const cuenta =
      await this.cuentaCarteraRepository.findByPropietario(propietarioId);
    if (!cuenta) {
      throw new NotFoundException(
        'Cuenta de cartera no encontrada para este propietario',
      );
    }
    return cuenta;
  }

  @Patch(':id/frecuencia')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN, RolUsuario.PROPIETARIO)
  async actualizarFrecuencia(
    @Param('id') id: string,
    @Body() dto: ActualizarFrecuenciaDto,
  ) {
    const cuenta = await this.cuentaCarteraRepository.findById(id);
    if (!cuenta) {
      throw new NotFoundException('Cuenta de cartera no encontrada');
    }

    cuenta.cambiarFrecuencia(dto.frecuencia);
    return this.cuentaCarteraRepository.save(cuenta);
  }
}
