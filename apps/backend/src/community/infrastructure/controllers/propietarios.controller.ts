import {
  Controller,
  Get,
  Post,
  Query,
  Body,
} from '@nestjs/common';
import { RegistrarPropietarioUseCase } from '../../application/use-cases/registrar-propietario.use-case';
import { PropietarioRepository } from '../../infrastructure/propietario.repository';
import { RegistrarPropietarioDto } from './dtos/propietarios.dto';

@Controller('propietarios')
export class PropietariosController {
  constructor(
    private readonly registrarPropietarioUseCase: RegistrarPropietarioUseCase,
    private readonly propietarioRepository: PropietarioRepository,
  ) {}

  @Post()
  async registrar(@Body() dto: RegistrarPropietarioDto) {
    return this.registrarPropietarioUseCase.execute({
      nombre: dto.nombre,
      telefono: dto.telefono,
      email: dto.email ?? null,
      tenantId: dto.tenantId,
      casaId: dto.casaId,
      fechaInicio: dto.fechaInicio ? new Date(dto.fechaInicio) : undefined,
    });
  }

  @Get()
  async listar(
    @Query('tenantId') tenantId: string,
    @Query('etapa') etapaId?: string,
    @Query('casa') casaId?: string,
  ) {
    return this.propietarioRepository.buscarPorFiltros({
      tenantId,
      etapaId,
      casaId,
    });
  }
}
