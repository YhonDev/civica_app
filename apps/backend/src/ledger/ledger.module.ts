import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ScheduleModule } from '@nestjs/schedule';
import { Tarifa } from './domain/tarifa.entity';
import { MontoPagoPredefinido } from './domain/monto-pago-predefinido.entity';
import { Cobro } from './domain/cobro.entity';
import { PlanDeCobro } from './domain/plan-de-cobro.entity';
import { PeriodoCobro } from './domain/periodo-cobro.entity';
import { Pago } from './domain/pago.entity';
import { Solicitud } from './domain/solicitud.entity';
import { PagoEdicion } from './domain/pago-edicion.entity';
import { Ticket } from './domain/ticket.entity';
import { TicketCobro } from './domain/ticket-cobro.entity';

// Repositories
import { TarifaRepository } from './infrastructure/persistence/tarifa.repository';
import { MontoPagoPredefinidoRepository } from './infrastructure/persistence/monto-pago-predefinido.repository';
import { PlanDeCobroRepository } from './infrastructure/persistence/plan-de-cobro.repository';
import { PeriodoCobroRepository } from './infrastructure/persistence/periodo-cobro.repository';
import { CobroRepository } from './infrastructure/persistence/cobro.repository';
import { PagoRepository } from './infrastructure/persistence/pago.repository';
import { SolicitudRepository } from './infrastructure/persistence/solicitud.repository';
import { TicketRepository } from './infrastructure/persistence/ticket.repository';

// Use cases
import { ConfigurarTarifaUseCase } from './application/use-cases/configurar-tarifa.use-case';
import { ActualizarTarifaUseCase } from './application/use-cases/actualizar-tarifa.use-case';
import { ConfigurarMontoUseCase } from './application/use-cases/configurar-monto.use-case';
import { GenerarCobrosUseCase } from './application/use-cases/generar-cobros.use-case';
import { RegistrarPagoUseCase } from './application/use-cases/registrar-pago.use-case';
import { EliminarPagoUseCase } from './application/use-cases/eliminar-pago.use-case';
import { EliminarCobroUseCase } from './application/use-cases/eliminar-cobro.use-case';
import { MarcarVencidasUseCase } from './application/use-cases/marcar-vencidas.use-case';
import { TarifaDerivacionService } from './application/services/tarifa-derivacion.service';
import { CorregirPagoUseCase } from './application/use-cases/corregir-pago.use-case';
import { ValidarPagoUseCase } from './application/use-cases/validar-pago.use-case';
import { GenerarTicketUseCase } from './application/use-cases/generar-ticket.use-case';

import { GenerarReporteUseCase } from './application/use-cases/generar-reporte.use-case';

// Queries
import { DashboardQuery } from './application/queries/dashboard.query';
import { CarteraViviendaResumenQuery } from './application/queries/cartera-vivienda-resumen.query';

// Controllers
import { TarifasController } from './infrastructure/controllers/tarifas.controller';
import { MontosController } from './infrastructure/controllers/montos.controller';
import { CobrosController } from './infrastructure/controllers/cobros.controller';
import { PlanesDeCobroController } from './infrastructure/controllers/planes-de-cobro.controller';
import { PagosController } from './infrastructure/controllers/pagos.controller';
import { DashboardController } from './infrastructure/controllers/dashboard.controller';
import { SolicitudesController } from './infrastructure/controllers/solicitudes.controller';
import { ReportesController } from './infrastructure/controllers/reportes.controller';
import { TicketsController } from './infrastructure/controllers/tickets.controller';

// Jobs
import { GenerarCobrosJob } from './infrastructure/jobs/generar-cobros.job';
import { MarcarVencidasJob } from './infrastructure/jobs/marcar-vencidas.job';

// Shared
import { NotificationsModule } from '../notifications/notifications.module';
import { CommunityModule } from '../community/community.module';
import { ActividadInterceptor } from '../shared/common/decorators/registrar-actividad.decorator';
import { Reflector } from '@nestjs/core';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Tarifa,
      MontoPagoPredefinido,
      Cobro,
      PlanDeCobro,
      PeriodoCobro,
      Pago,
      Solicitud,
      PagoEdicion,
      Ticket,
      TicketCobro,
    ]),
    ScheduleModule.forRoot(),
    NotificationsModule,
    forwardRef(() => CommunityModule),
  ],
  controllers: [
    TarifasController,
    MontosController,
    CobrosController,
    PlanesDeCobroController,
    PagosController,
    DashboardController,
    SolicitudesController,
    ReportesController,
    TicketsController,
  ],
  providers: [
    // Repositories
    TarifaRepository,
    MontoPagoPredefinidoRepository,
    PlanDeCobroRepository,
    PeriodoCobroRepository,
    CobroRepository,
    PagoRepository,
    SolicitudRepository,
    TicketRepository,

    // Use cases
    ConfigurarTarifaUseCase,
    ActualizarTarifaUseCase,
    ConfigurarMontoUseCase,
    GenerarCobrosUseCase,
    RegistrarPagoUseCase,
    EliminarPagoUseCase,
    EliminarCobroUseCase,
    MarcarVencidasUseCase,
    GenerarReporteUseCase,
    CorregirPagoUseCase,
    ValidarPagoUseCase,
    GenerarTicketUseCase,

    // Services
    TarifaDerivacionService,

    // Queries
    DashboardQuery,
    CarteraViviendaResumenQuery,

    // Jobs
    GenerarCobrosJob,
    MarcarVencidasJob,

    // Interceptors
    Reflector,
    ActividadInterceptor,
  ],
  exports: [
    TypeOrmModule,
    TarifaRepository,
    CobroRepository,
    PlanDeCobroRepository,
    PagoRepository,
    SolicitudRepository,
    GenerarCobrosUseCase,
    CarteraViviendaResumenQuery,
  ],
})
export class LedgerModule {}

