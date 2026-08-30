import { Injectable } from '@nestjs/common';
import { EntityManager } from 'typeorm';
import { PagoCobro } from '../../domain/pago-cobro.entity';

/**
 * Repositorio para los vínculos PagoCobro.
 *
 * Todos los métodos operan sobre un `entityManager` explícito para que las
 * lecturas/escrituras se ejecuten dentro de la transacción del use case que
 * los invoca (patrón consistente con findMasAntiguoConSaldoLocked).
 */
@Injectable()
export class PagoCobroRepository {
  async findByPago(entityManager: EntityManager, pagoId: string): Promise<PagoCobro[]> {
    return entityManager.find(PagoCobro, { where: { pagoId } });
  }

  async findByCobro(entityManager: EntityManager, cobroId: string): Promise<PagoCobro[]> {
    return entityManager.find(PagoCobro, { where: { cobroId } });
  }

  async save(entityManager: EntityManager, vinculo: PagoCobro): Promise<PagoCobro> {
    return entityManager.save(PagoCobro, vinculo);
  }

  async removeByPago(entityManager: EntityManager, pagoId: string): Promise<void> {
    await entityManager.delete(PagoCobro, { pagoId });
  }

  async removeByCobro(entityManager: EntityManager, cobroId: string): Promise<void> {
    await entityManager.delete(PagoCobro, { cobroId });
  }
}
