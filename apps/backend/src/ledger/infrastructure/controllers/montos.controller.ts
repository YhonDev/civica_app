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
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { ConfigurarMontoUseCase } from '../../application/use-cases/configurar-monto.use-case';
import { MontoPagoPredefinidoRepository } from '../persistence/monto-pago-predefinido.repository';
import { CrearMontoDto, ListarMontosQueryDto } from './dtos/montos.dto';
import { JwtAuthGuard } from '../../../shared/auth/jwt-auth.guard';
import { RolesGuard } from '../../../shared/auth/guards/roles.guard';
import { Roles } from '../../../shared/auth/decorators/roles.decorator';
import { CurrentTenant } from '../../../shared/tenant/current-tenant.decorator';
import { RolUsuario } from '../../../iam/domain/usuario.entity';

@ApiTags('Montos')
@ApiBearerAuth('jwt-auth')
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
  @ApiOperation({ summary: 'Crear monto predefinido' })
  async crear(@Body() dto: CrearMontoDto, @CurrentTenant() tenantId: string) {
    return this.configurarMontoUseCase.execute({
      tenantId,
      proyectoId: dto.proyectoId,
      montoPesos: dto.monto,
      descripcion: dto.descripcion,
    });
  }

  @Get()
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN, RolUsuario.RESIDENTE)
  @ApiOperation({ summary: 'Listar montos predefinidos por proyecto' })
  async listar(
    @Query() query: ListarMontosQueryDto,
    @CurrentTenant() tenantId: string,
  ) {
    return this.montoRepository.findAllByConjunto(query.proyectoId, tenantId);
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async eliminar(@Param('id') id: string, @CurrentTenant() tenantId: string) {
    const monto = await this.montoRepository.findById(id, tenantId);
    if (!monto) {
      throw new NotFoundException('Monto no encontrado');
    }
    await this.montoRepository.remove(id);
    return { message: 'Monto desactivado correctamente' };
  }
}
