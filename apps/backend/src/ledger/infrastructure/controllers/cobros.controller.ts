import {
  Controller,
  Get,
  Post,
  Param,
  Body,
  Delete,
  UseGuards,
} from '@nestjs/common';
import { DataSource } from 'typeorm';
import { JwtAuthGuard } from '../../../shared/auth/jwt-auth.guard';
import { RolesGuard } from '../../../shared/auth/guards/roles.guard';
import { Roles } from '../../../shared/auth/decorators/roles.decorator';
import { CurrentTenant } from '../../../shared/tenant/current-tenant.decorator';
import { RolUsuario } from '../../../iam/domain/usuario.entity';
import { CobroRepository } from '../../infrastructure/persistence/cobro.repository';
import { EliminarCobroUseCase } from '../../application/use-cases/eliminar-cobro.use-case';

@Controller('cobros')
@UseGuards(JwtAuthGuard)
export class CobrosController {
  constructor(
    private readonly cobroRepository: CobroRepository,
    private readonly eliminarCobroUseCase: EliminarCobroUseCase,
    private readonly dataSource: DataSource,
  ) {}

  @Get()
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async listar(
    @CurrentTenant() tenantId: string,
  ) {
    if (!tenantId) return [];
    return this.cobroRepository.findPendientesByTenant(tenantId);
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async eliminar(@Param('id') id: string) {
    await this.eliminarCobroUseCase.execute(id);
    return { success: true };
  }
}
