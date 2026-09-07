import { EntityManager } from 'typeorm';
import { Pago } from '../../domain/pago.entity';
import { Cobro } from '../../domain/cobro.entity';
import { PagoCobroRepository } from '../../infrastructure/persistence/pago-cobro.repository';

/**
 * Recalcula el estado de un cobro luego de revertir(total o parcialmente) su monto
 * pagado. Misma lógica usada por eliminar/corregir/validar.
 */
function recalcularEstado(cobro: Cobro): void {
  if (cobro.montoPagado === 0) {
    if (new Date(cobro.fechaVencimiento).getTime() < new Date().getTime()) {
      cobro.estado = 'VENCIDA';
    } else {
      cobro.estado = 'PENDIENTE';
    }
  } else if (cobro.montoPagado < cobro.monto) {
    cobro.estado = 'PARCIAL';
  }
}

/**
 * Revierte el abono de un pago sobre los cobros que realmente afectó.
 *
 * - Si existen vínculos `pago_cobros` (pagos creados post-fix), revierte de forma
 *   EXACTA restando `montoAplicado` a cada cobro vinculado. Es el flujo correcto
 *   para pagos FIFO que cruzaron varias cuotas.
 * - Si NO existen vínculos (pagos legacy pre-fix), cae al comportamiento histórico
 *   (LIFO inverso sobre los cobros del residente) para no romper datos existentes.
 *
 * Siempre se lee con el `entityManager` de la transacción activa.
 *
 * @returns Los cobros que fueron modificados durante el reverso.
 */
export async function revertirAbonos(
  entityManager: EntityManager,
  pago: Pago,
  pagoCobroRepo: PagoCobroRepository,
): Promise<Cobro[]> {
  const vinculos = await pagoCobroRepo.findByPago(entityManager, pago.id);
  const cobrosRevertidos: Cobro[] = [];

  if (vinculos.length > 0) {
    // Reverso exacto vía vínculos
    for (const vinculo of vinculos) {
      if (vinculo.montoAplicado <= 0) continue;

      const cobro =
        typeof entityManager.createQueryBuilder === 'function'
          ? await entityManager
              .createQueryBuilder(Cobro, 'cobro')
              .where('cobro.id = :id', { id: vinculo.cobroId })
              .setLock('pessimistic_write', undefined, ['cobro'])
              .getOne()
          : await entityManager.findOne(Cobro, {
              where: { id: vinculo.cobroId },
              lock: { mode: 'pessimistic_write' },
            });
      if (!cobro) continue;

      cobro.montoPagado = Math.max(
        0,
        cobro.montoPagado - vinculo.montoAplicado,
      );
      recalcularEstado(cobro);
      await entityManager.save(Cobro, cobro);
      cobrosRevertidos.push(cobro);
    }

    // Eliminar los vínculos del pago (ya no se aplicarán a un cobro).
    await pagoCobroRepo.removeByPago(entityManager, pago.id);

    return cobrosRevertidos;
  }

  // Fallback legacy: LIFO inverso sobre todos los cobros del residente.
  let remainingToReverse = pago.monto;
  const cobros =
    typeof entityManager.createQueryBuilder === 'function'
      ? await entityManager
          .createQueryBuilder(Cobro, 'cobro')
          .where('cobro.residenteId = :residenteId', {
            residenteId: pago.residenteId,
          })
          .andWhere('cobro.tenantId = :tenantId', { tenantId: pago.tenantId })
          .orderBy('cobro.periodoInicio', 'DESC')
          .setLock('pessimistic_write', undefined, ['cobro'])
          .getMany()
      : await entityManager.getRepository(Cobro).find({
          where: { residenteId: pago.residenteId, tenantId: pago.tenantId },
          order: { periodoInicio: 'DESC' },
          lock: { mode: 'pessimistic_write' },
        });

  for (const cobro of cobros) {
    if (remainingToReverse <= 0) break;

    if (cobro.montoPagado > 0) {
      const amountToSubtract = Math.min(cobro.montoPagado, remainingToReverse);
      cobro.montoPagado -= amountToSubtract;
      remainingToReverse -= amountToSubtract;
      recalcularEstado(cobro);
      await entityManager.save(Cobro, cobro);
      cobrosRevertidos.push(cobro);
    }
  }

  return cobrosRevertidos;
}
