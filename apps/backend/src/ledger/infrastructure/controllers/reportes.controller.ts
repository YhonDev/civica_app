import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../../../shared/auth/jwt-auth.guard';
import { RolesGuard } from '../../../shared/auth/guards/roles.guard';
import { Roles } from '../../../shared/auth/decorators/roles.decorator';
import { RolUsuario } from '../../../iam/domain/usuario.entity';
import { GenerarReporteUseCase } from '../../application/use-cases/generar-reporte.use-case';

@Controller('reportes')
@UseGuards(JwtAuthGuard, RolesGuard)
export class ReportesController {
  constructor(private readonly generarReporteUseCase: GenerarReporteUseCase) {}

  @Get('recaudo')
  @Roles(RolUsuario.ADMIN)
  async getReporteRecaudo(
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
    });
  }
}
