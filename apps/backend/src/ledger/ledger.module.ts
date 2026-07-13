import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ScheduleModule } from '@nestjs/schedule';
import { Tarifa } from './domain/tarifa.entity';
import { MontoPagoPredefinido } from './domain/monto-pago-predefinido.entity';
import { Cuota } from './domain/cuota.entity';
import { CuentaDeCartera } from './domain/cuenta-de-cartera.entity';
import { Pago } from './domain/pago.entity';
import { Solicitud } from './domain/solicitud.entity';

// Repositories
import { TarifaRepository } from './infrastructure/persistence/tarifa.repository';
import { MontoPagoPredefinidoRepository } from './infrastructure/persistence/monto-pago-predefinido.repository';
import { CuentaCarteraRepository } from './infrastructure/persistence/cuenta-cartera.repository';
import { CuotaRepository } from './infrastructure/persistence/cuota.repository';
import { PagoRepository } from './infrastructure/persistence/pago.repository';
import { SolicitudRepository } from './infrastructure/persistence/solicitud.repository';

// Use cases
import { ConfigurarTarifaUseCase } from './application/use-cases/configurar-tarifa.use-case';
import { ActualizarTarifaUseCase } from './application/use-cases/actualizar-tarifa.use-case';
import { ConfigurarMontoUseCase } from './application/use-cases/configurar-monto.use-case';
import { GenerarCuotasUseCase } from './application/use-cases/generar-cuotas.use-case';
import { RegistrarPagoUseCase } from './application/use-cases/registrar-pago.use-case';
import { EliminarPagoUseCase } from './application/use-cases/eliminar-pago.use-case';
import { EliminarCuotaUseCase } from './application/use-cases/eliminar-cuota.use-case';
import { MarcarVencidasUseCase } from './application/use-cases/marcar-vencidas.use-case';
import { TarifaDerivacionService } from './application/services/tarifa-derivacion.service';

// Queries
import { DashboardQuery } from './application/queries/dashboard.query';

// Controllers
import { TarifasController } from './infrastructure/controllers/tarifas.controller';
import { MontosController } from './infrastructure/controllers/montos.controller';
import { CuotasController } from './infrastructure/controllers/cuotas.controller';
import { CuentasCarteraController } from './infrastructure/controllers/cuentas-cartera.controller';
import { PagosController } from './infrastructure/controllers/pagos.controller';
import { DashboardController } from './infrastructure/controllers/dashboard.controller';
import { SolicitudesController } from './infrastructure/controllers/solicitudes.controller';

// Jobs
import { GenerarCuotasJob } from './infrastructure/jobs/generar-cuotas.job';
import { MarcarVencidasJob } from './infrastructure/jobs/marcar-vencidas.job';

// Shared
import { NotificationsModule } from '../notifications/notifications.module';
import { CommunityModule } from '../community/community.module';
import { ActividadInterceptor } from '../shared/common/decorators/registrar-actividad.decorator';
import { Reflector } from '@nestjs/core';

@Module({
  imports: [
    TypeOrmModule.forFeature([Tarifa, MontoPagoPredefinido, Cuota, CuentaDeCartera, Pago, Solicitud]),
    ScheduleModule.forRoot(),
    NotificationsModule,
    CommunityModule,
  ],
  controllers: [
    TarifasController,
    MontosController,
    CuotasController,
    CuentasCarteraController,
    PagosController,
    DashboardController,
    SolicitudesController,
  ],
  providers: [
    // Repositories
    TarifaRepository,
    MontoPagoPredefinidoRepository,
    CuentaCarteraRepository,
    CuotaRepository,
    PagoRepository,
    SolicitudRepository,

    // Use cases
    ConfigurarTarifaUseCase,
    ActualizarTarifaUseCase,
    ConfigurarMontoUseCase,
    GenerarCuotasUseCase,
    RegistrarPagoUseCase,
    EliminarPagoUseCase,
    EliminarCuotaUseCase,
    MarcarVencidasUseCase,

    // Services
    TarifaDerivacionService,

    // Queries
    DashboardQuery,

    // Jobs
    GenerarCuotasJob,
    MarcarVencidasJob,

    // Interceptors
    Reflector,
    ActividadInterceptor,
  ],
  exports: [
    TypeOrmModule,
    TarifaRepository,
    CuotaRepository,
    CuentaCarteraRepository,
    PagoRepository,
    SolicitudRepository,
  ],
})
export class LedgerModule {}
