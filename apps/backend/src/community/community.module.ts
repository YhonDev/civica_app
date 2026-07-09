import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Conjunto } from './domain/conjunto.entity';
import { Etapa } from './domain/etapa.entity';
import { Casa } from './domain/casa.entity';
import { Propietario } from './domain/propietario.entity';
import { Tenencia } from './domain/tenencia.entity';
import { ConjuntoRepository } from './infrastructure/conjunto.repository';
import { PropietarioRepository } from './infrastructure/propietario.repository';
import { CrearConjuntoUseCase } from './application/use-cases/crear-conjunto.use-case';
import { CrearEtapaUseCase } from './application/use-cases/crear-etapa.use-case';
import { RegistrarCasaUseCase } from './application/use-cases/registrar-casa.use-case';
import { RegistrarPropietarioUseCase } from './application/use-cases/registrar-propietario.use-case';
import { AgregarTenenciaUseCase } from './application/use-cases/agregar-tenencia.use-case';
import { ConjuntosController } from './infrastructure/controllers/conjuntos.controller';
import { PropietariosController } from './infrastructure/controllers/propietarios.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([Conjunto, Etapa, Casa, Propietario, Tenencia]),
  ],
  controllers: [ConjuntosController, PropietariosController],
  providers: [
    // Repositories
    ConjuntoRepository,
    PropietarioRepository,
    // Use cases
    CrearConjuntoUseCase,
    CrearEtapaUseCase,
    RegistrarCasaUseCase,
    RegistrarPropietarioUseCase,
    AgregarTenenciaUseCase,
  ],
  exports: [TypeOrmModule, ConjuntoRepository, PropietarioRepository],
})
export class CommunityModule {}
