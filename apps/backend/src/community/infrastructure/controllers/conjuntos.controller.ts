import {
  Controller,
  Get,
  Post,
  Param,
  Query,
  Body,
} from '@nestjs/common';
import { CrearConjuntoUseCase } from '../../application/use-cases/crear-conjunto.use-case';
import { CrearEtapaUseCase } from '../../application/use-cases/crear-etapa.use-case';
import { RegistrarCasaUseCase } from '../../application/use-cases/registrar-casa.use-case';
import { ConjuntoRepository } from '../../infrastructure/conjunto.repository';
import {
  CrearConjuntoDto,
  CrearEtapaDto,
  RegistrarCasaDto,
} from './dtos/conjuntos.dto';

@Controller('conjuntos')
export class ConjuntosController {
  constructor(
    private readonly crearConjuntoUseCase: CrearConjuntoUseCase,
    private readonly crearEtapaUseCase: CrearEtapaUseCase,
    private readonly registrarCasaUseCase: RegistrarCasaUseCase,
    private readonly conjuntoRepository: ConjuntoRepository,
  ) {}

  @Post()
  async crear(@Body() dto: CrearConjuntoDto) {
    return this.crearConjuntoUseCase.execute(dto.nombre, dto.tenantId);
  }

  @Post(':id/etapas')
  async crearEtapa(
    @Param('id') conjuntoId: string,
    @Body() dto: CrearEtapaDto,
  ) {
    return this.crearEtapaUseCase.execute(dto.nombre, conjuntoId);
  }

  @Post(':id/casas')
  async crearCasa(
    @Param('id') etapaId: string,
    @Body() dto: RegistrarCasaDto,
  ) {
    return this.registrarCasaUseCase.execute(dto.direccionInterna, etapaId);
  }

  @Get()
  async listar(@Query('tenantId') tenantId: string) {
    return this.conjuntoRepository.findByTenant(tenantId);
  }
}
