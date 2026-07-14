import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Proyecto } from './domain/proyecto.entity';
import { Etapa } from './domain/etapa.entity';
import { Casa } from './domain/casa.entity';
import { Manzana } from './domain/manzana.entity';
import { Residente } from './domain/residente.entity';
import { Tenencia } from './domain/tenencia.entity';
import { ProyectoRepository } from './infrastructure/proyecto.repository';
import { ResidenteRepository } from './infrastructure/residente.repository';
import { ResidenteDetailQuery } from './application/queries/residente-detail.query';
import { CrearProyectoUseCase } from './application/use-cases/crear-proyecto.use-case';
import { CrearEtapaUseCase } from './application/use-cases/crear-etapa.use-case';
import { CrearManzanaUseCase } from './application/use-cases/crear-manzana.use-case';
import { RegistrarCasaUseCase } from './application/use-cases/registrar-casa.use-case';
import { RegistrarResidenteUseCase } from './application/use-cases/registrar-residente.use-case';
import { EliminarResidenteUseCase } from './application/use-cases/eliminar-residente.use-case';
import { ActualizarResidenteUseCase } from './application/use-cases/actualizar-residente.use-case';
import { AgregarTenenciaUseCase } from './application/use-cases/agregar-tenencia.use-case';
import { CrearCobradorUseCase } from './application/use-cases/crear-cobrador.use-case';
import { ProyectosController } from './infrastructure/controllers/proyectos.controller';
import { ResidentesController } from './infrastructure/controllers/residentes.controller';
import { IamModule } from '../iam/iam.module';
import { LedgerModule } from '../ledger/ledger.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { ActividadInterceptor } from '../shared/common/decorators/registrar-actividad.decorator';
import { Reflector } from '@nestjs/core';

@Module({
  imports: [
    TypeOrmModule.forFeature([Proyecto, Etapa, Manzana, Casa, Residente, Tenencia]),
    IamModule,
    forwardRef(() => LedgerModule),
    NotificationsModule,
  ],
  controllers: [ProyectosController, ResidentesController],
  providers: [
    // Repositories
    ProyectoRepository,
    ResidenteRepository,
    // Queries
    ResidenteDetailQuery,
    // Use cases
    CrearProyectoUseCase,
    CrearEtapaUseCase,
    CrearManzanaUseCase,
    RegistrarCasaUseCase,
    RegistrarResidenteUseCase,
    EliminarResidenteUseCase,
    ActualizarResidenteUseCase,
    AgregarTenenciaUseCase,
    CrearCobradorUseCase,
    // Interceptors
    Reflector,
    ActividadInterceptor,
  ],
  exports: [TypeOrmModule, ProyectoRepository, ResidenteRepository],
})
export class CommunityModule {}
