import {
  Controller,
  Get,
  Post,
  Delete,
  Param,
  Query,
  Body,
  UseGuards,
  NotFoundException,
} from '@nestjs/common';
import { ConfigurarMontoUseCase } from '../../application/use-cases/configurar-monto.use-case';
import { MontoPagoPredefinidoRepository } from '../persistence/monto-pago-predefinido.repository';
import { CrearMontoDto, ListarMontosQueryDto } from './dtos/montos.dto';
import { JwtAuthGuard } from '../../../shared/auth/jwt-auth.guard';
import { RolesGuard } from '../../../shared/auth/guards/roles.guard';
import { Roles } from '../../../shared/auth/decorators/roles.decorator';
import { CurrentTenant } from '../../../shared/tenant/current-tenant.decorator';
import { RolUsuario } from '../../../iam/domain/usuario.entity';

@Controller('montos-predefinidos')
@UseGuards(JwtAuthGuard)
export class MontosController {
  constructor(
    private readonly configurarMontoUseCase: ConfigurarMontoUseCase,
    private readonly montoRepository: MontoPagoPredefinidoRepository,
  ) {}

  @Post()
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async crear(@Body() dto: CrearMontoDto, @CurrentTenant() tenantId: string) {
    return this.configurarMontoUseCase.execute({
      tenantId,
      conjuntoId: dto.conjuntoId,
      montoPesos: dto.monto,
      descripcion: dto.descripcion,
    });
  }

  @Get()
  async listar(@Query() query: ListarMontosQueryDto) {
    return this.montoRepository.findAllByConjunto(query.conjuntoId);
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async eliminar(@Param('id') id: string) {
    const monto = await this.montoRepository.findById(id);
    if (!monto) {
      throw new NotFoundException('Monto no encontrado');
    }
    await this.montoRepository.remove(id);
    return { message: 'Monto desactivado correctamente' };
  }
}
