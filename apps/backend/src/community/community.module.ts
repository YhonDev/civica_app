import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Conjunto } from './domain/conjunto.entity';
import { Etapa } from './domain/etapa.entity';
import { Casa } from './domain/casa.entity';
import { Manzana } from './domain/manzana.entity';
import { Propietario } from './domain/propietario.entity';
import { Tenencia } from './domain/tenencia.entity';
import { ConjuntoRepository } from './infrastructure/conjunto.repository';
import { PropietarioRepository } from './infrastructure/propietario.repository';
import { CrearConjuntoUseCase } from './application/use-cases/crear-conjunto.use-case';
import { CrearEtapaUseCase } from './application/use-cases/crear-etapa.use-case';
import { CrearManzanaUseCase } from './application/use-cases/crear-manzana.use-case';
import { RegistrarCasaUseCase } from './application/use-cases/registrar-casa.use-case';
import { RegistrarPropietarioUseCase } from './application/use-cases/registrar-propietario.use-case';
import { EliminarPropietarioUseCase } from './application/use-cases/eliminar-propietario.use-case';
import { ActualizarPropietarioUseCase } from './application/use-cases/actualizar-propietario.use-case';
import { AgregarTenenciaUseCase } from './application/use-cases/agregar-tenencia.use-case';
import { ConjuntosController } from './infrastructure/controllers/conjuntos.controller';
import { PropietariosController } from './infrastructure/controllers/propietarios.controller';
import { NotificationsModule } from '../notifications/notifications.module';
import { ActividadInterceptor } from '../shared/common/decorators/registrar-actividad.decorator';
import { Reflector } from '@nestjs/core';

@Module({
  imports: [
    TypeOrmModule.forFeature([Conjunto, Etapa, Manzana, Casa, Propietario, Tenencia]),
    NotificationsModule,
  ],
  controllers: [ConjuntosController, PropietariosController],
  providers: [
    // Repositories
    ConjuntoRepository,
    PropietarioRepository,
    // Use cases
    CrearConjuntoUseCase,
    CrearEtapaUseCase,
    CrearManzanaUseCase,
    RegistrarCasaUseCase,
    RegistrarPropietarioUseCase,
    EliminarPropietarioUseCase,
    ActualizarPropietarioUseCase,
    AgregarTenenciaUseCase,
    // Interceptors
    Reflector,
    ActividadInterceptor,
  ],
  exports: [TypeOrmModule, ConjuntoRepository, PropietarioRepository],
})
export class CommunityModule {}
