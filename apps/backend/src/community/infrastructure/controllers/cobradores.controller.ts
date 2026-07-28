import {
  Controller,
  Post,
  Body,
  UseGuards,
} from '@nestjs/common';
import { CrearCobradorUseCase } from '../../application/use-cases/crear-cobrador.use-case';
import { CrearCobradorDto } from './dtos/cobradores.dto';
import { JwtAuthGuard } from '../../../shared/auth/jwt-auth.guard';
import { RolesGuard } from '../../../shared/auth/guards/roles.guard';
import { Roles } from '../../../shared/auth/decorators/roles.decorator';
import { CurrentTenant } from '../../../shared/tenant/current-tenant.decorator';
import { RolUsuario } from '../../../iam/domain/usuario.entity';

@Controller('cobradores')
@UseGuards(JwtAuthGuard)
export class CobradoresController {
  constructor(
    private readonly crearCobradorUseCase: CrearCobradorUseCase,
  ) {}

  @Post()
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async crear(
    @Body() dto: CrearCobradorDto,
    @CurrentTenant() tenantId: string,
  ) {
    return this.crearCobradorUseCase.execute({
      nombre: dto.nombre,
      telefono: dto.telefono,
      tenantId,
      etapaIds: dto.etapaIds,
    });
  }
}
