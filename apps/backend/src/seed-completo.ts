import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { GenerarCobrosUseCase } from './ledger/application/use-cases/generar-cobros.use-case';
import { RegistrarPagoUseCase } from './ledger/application/use-cases/registrar-pago.use-case';
import { PlanDeCobroRepository } from './ledger/infrastructure/persistence/plan-de-cobro.repository';
import { Usuario, RolUsuario } from './iam/domain/usuario.entity';
import { DataSource, Between } from 'typeorm';
import { PlanDeCobro } from './ledger/domain/plan-de-cobro.entity';
import { Cobro } from './ledger/domain/cobro.entity';
import { Tarifa } from './ledger/domain/tarifa.entity';
import { PeriodoCobro } from './ledger/domain/periodo-cobro.entity';
import { Pago } from './ledger/domain/pago.entity';
import { Ticket } from './ledger/domain/ticket.entity';

async function bootstrap() {
  console.log('Iniciando CLEAN seed de Junio y Julio 2026...');
  const app = await NestFactory.createApplicationContext(AppModule);
  const dataSource = app.get(DataSource);

  const planRepo = app.get(PlanDeCobroRepository);
  const generarCobros = app.get(GenerarCobrosUseCase);
  const registrarPago = app.get(RegistrarPagoUseCase);

  const cobradorRepo = dataSource.getRepository(Usuario);
  const cobrador = await cobradorRepo.findOne({
    where: { rol: RolUsuario.COBRADOR },
  });
  if (!cobrador) {
    console.error('No hay cobrador en la DB');
    process.exit(1);
  }

  // 1. DELETE everything from June and July to start clean
  console.log('Limpiando datos anteriores de Junio y Julio 2026...');
  await dataSource.query('DELETE FROM solicitudes');
  await dataSource.query('DELETE FROM tickets');
  await dataSource.query('DELETE FROM pagos');
  await dataSource.query('DELETE FROM cobros');
  await dataSource.query('DELETE FROM periodos_cobro');

  // 2. Fetch all active planes and setup Tarifa
  const planes = await planRepo.findAllActivos();
  if (planes.length === 0) {
    console.error('No hay planes activos');
    process.exit(1);
  }

  const primerPlan = planes[0];
  const proyectoId = primerPlan.proyectoId;
  const tenantId = primerPlan.tenantId;

  const tarifaRepo = dataSource.getRepository(Tarifa);

  // Crear tarifas vigentes desde el 1 de Junio
  const modalidades = [
    { mod: 'SEMANAL', monto: 1000000 },
    { mod: 'QUINCENAL', monto: 2000000 },
    { mod: 'MENSUAL', monto: 4000000 },
  ];

  for (const m of modalidades) {
    const existe = await tarifaRepo.findOne({
      where: {
        proyectoId,
        modalidad: m.mod as any,
        fechaVigencia: '2026-06-01',
      },
    });
    if (!existe) {
      const tarifa = new Tarifa();
      tarifa.proyectoId = proyectoId;
      tarifa.tenantId = tenantId;
      tarifa.modalidad = m.mod as any;
      tarifa.monto = m.monto;
      tarifa.fechaVigencia = '2026-06-01';
      tarifa.activa = true;
      await tarifaRepo.save(tarifa);
      console.log(
        `Tarifa ${m.mod} creada para Junio/Julio: ${m.monto} centavos`,
      );
    }
  }

  // 3. Reset planes: remove hardcoded valorMensual and backdate
  const ormPlanRepo = dataSource.getRepository(PlanDeCobro);
  for (const plan of planes) {
    let changed = false;
    if (plan.fechaActivacion > '2026-06-01') {
      plan.fechaActivacion = '2026-06-01';
      changed = true;
    }
    if (plan.valorMensual !== null) {
      plan.valorMensual = null;
      changed = true;
    }
    if (changed) await ormPlanRepo.save(plan);
  }

  // 4. Generate Cobros for JUNE
  console.log('--- GENERANDO JUNIO ---');
  await generarCobros.execute();

  // 5. Register ALL payments for previous period (fully paid)
  console.log('--- REGISTRANDO PAGOS CON MOTOR REAL ---');
  const ormCobroRepo = dataSource.getRepository(Cobro);
  let cobrosAPagar = await ormCobroRepo.find({
    where: { periodoInicio: '2026-05-01' },
  });
  if (cobrosAPagar.length === 0) {
    cobrosAPagar = await ormCobroRepo.find();
  }

  for (const cobro of cobrosAPagar) {
    const plan = planes.find(
      (p: PlanDeCobro) => p.residenteId === cobro.residenteId,
    );
    if (!plan) continue;

    const numPagos =
      plan.modalidad === 'SEMANAL' ? 4 : plan.modalidad === 'QUINCENAL' ? 2 : 1;
    const montoCuota = Math.floor(cobro.monto / numPagos);

    for (let i = 1; i <= numPagos; i++) {
      const fechaDia = String(((i * 7) % 28) + 1).padStart(2, '0');
      try {
        await registrarPago.execute({
          clientPaymentId: `seed-pago-${cobro.id}-${i}`,
          tenantId: cobro.tenantId,
          monto: montoCuota,
          fechaPago: `2026-06-${fechaDia}T10:00:00.000Z`,
          cobradorId: cobrador.id,
          cobradorNombre: cobrador.nombre,
          residenteId: cobro.residenteId,
        });
      } catch (_) {
        // Cobro fully paid for this resident
        break;
      }
    }
  }

  // 6. Generate Cobros for JULY
  console.log('--- GENERANDO JULIO ---');
  await generarCobros.execute();

  console.log(
    'SEED COMPLETO EXITOSO! DB lista con datos reales de Junio (Pagado) y Julio (En Recaudo).',
  );
  await app.close();
  process.exit(0);
}

bootstrap().catch((err) => {
  console.error('Error en seed:', err);
  process.exit(1);
});
