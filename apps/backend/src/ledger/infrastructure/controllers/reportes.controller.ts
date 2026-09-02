import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../../shared/auth/jwt-auth.guard';
import { RolesGuard } from '../../../shared/auth/guards/roles.guard';
import { Roles } from '../../../shared/auth/decorators/roles.decorator';
import { RolUsuario } from '../../../iam/domain/usuario.entity';
import { CurrentTenant } from '../../../shared/tenant/current-tenant.decorator';
import { GenerarReporteUseCase } from '../../application/use-cases/generar-reporte.use-case';

@ApiTags('Reportes')
@ApiBearerAuth('jwt-auth')
@Controller('reportes')
@UseGuards(JwtAuthGuard, RolesGuard)
export class ReportesController {
  constructor(private readonly generarReporteUseCase: GenerarReporteUseCase) {}

  @Get('recaudo')
  @Roles(RolUsuario.ADMIN)
  async getReporteRecaudo(
    @CurrentTenant() tenantId: string,
    @Query('proyectoId') proyectoId: string,
    @Query('mes') mesQuery?: string,
    @Query('anio') anioQuery?: string,
    @Query('etapaId') etapaId?: string,
  ) {
    const hoy = new Date();
    const mes = mesQuery ? parseInt(mesQuery, 10) : hoy.getMonth() + 1;
    const anio = anioQuery ? parseInt(anioQuery, 10) : hoy.getFullYear();
    return this.generarReporteUseCase.execute({
      proyectoId,
      mes,
      anio,
      etapaId,
      tenantId,
    });
  }
}
