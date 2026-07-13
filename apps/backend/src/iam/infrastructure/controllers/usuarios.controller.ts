import {
  Controller,
  Get,
  Post,
  Param,
  Body,
  UseGuards,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { IsString, IsNotEmpty } from 'class-validator';
import { Repository } from 'typeorm';
import { JwtAuthGuard } from '../../../shared/auth/jwt-auth.guard';
import { RolesGuard } from '../../../shared/auth/guards/roles.guard';
import { Roles } from '../../../shared/auth/decorators/roles.decorator';
import { CurrentUser } from '../../../shared/tenant/current-user.decorator';
import { CurrentTenant } from '../../../shared/tenant/current-tenant.decorator';
import { AsignarEtapaUseCase } from '../../application/use-cases/asignar-etapa.use-case';
import { Usuario, RolUsuario } from '../../domain/usuario.entity';
import { AsignacionEtapa } from '../../domain/asignacion-etapa.entity';

class AsignarEtapaDto {
  @IsString()
  @IsNotEmpty()
  etapaId: string;
}

@Controller('usuarios')
@UseGuards(JwtAuthGuard)
export class UsuariosController {
  constructor(
    @InjectRepository(AsignacionEtapa)
    private readonly asignacionRepository: Repository<AsignacionEtapa>,
    @InjectRepository(Usuario)
    private readonly usuarioRepository: Repository<Usuario>,
    private readonly asignarEtapaUseCase: AsignarEtapaUseCase,
  ) {}

  @Get()
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async listar(@CurrentTenant() tenantId: string) {
    return this.usuarioRepository.find({
      where: { tenantId, rol: RolUsuario.COBRADOR },
      relations: {
        asignaciones: {
          etapa: true
        }
      }
    });
  }

  @Get(':id/etapas')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN, RolUsuario.COBRADOR)
  async obtenerEtapas(
    @Param('id') usuarioId: string,
    @CurrentUser() currentUser: Usuario,
  ) {
    // ADMIN puede ver etapas de cualquier usuario del mismo tenant
    // COBRADOR solo puede ver sus propias etapas
    if (
      currentUser.rol !== RolUsuario.ADMIN &&
      currentUser.id !== usuarioId
    ) {
      return [];
    }

    const asignaciones = await this.asignacionRepository.find({
      where: { usuarioId },
    });
    return asignaciones.map((a) => ({
      id: a.id,
      etapaId: a.etapaId,
      createdAt: a.createdAt,
    }));
  }

  @Post(':id/etapas')
  @UseGuards(RolesGuard)
  @Roles(RolUsuario.ADMIN)
  async asignarEtapa(
    @Param('id') usuarioId: string,
    @Body() dto: AsignarEtapaDto,
    @CurrentUser() currentUser: Usuario,
  ) {
    return this.asignarEtapaUseCase.execute({
      usuarioId,
      etapaId: dto.etapaId,
      tenantId: currentUser.tenantId,
    });
  }
}
