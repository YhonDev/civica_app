import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Pago } from './pago.entity';
import { Cobro } from './cobro.entity';

/**
 * Vínculo entre un Pago y cada uno de los Cobros que afectó (FIFO).
 * Permite revertir un pago de forma EXACTA, independientemente de cuántos
 * cobros tocó, en lugar de depender del LIFO inverso sobre todos los cobros
 * del residente (que corrompía el ledger cuando un pago cruzaba varias cuotas).
 */
@Entity('pago_cobros')
export class PagoCobro {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'pago_id', type: 'uuid' })
  pagoId: string;

  @ManyToOne(() => Pago, { createForeignKeyConstraints: false })
  @JoinColumn({ name: 'pago_id' })
  pago: Pago;

  @Column({ name: 'cobro_id', type: 'uuid' })
  cobroId: string;

  @ManyToOne(() => Cobro, { createForeignKeyConstraints: false })
  @JoinColumn({ name: 'cobro_id' })
  cobro: Cobro;

  @Column({ name: 'monto_aplicado', type: 'integer' })
  montoAplicado: number; // centavos COP aplicados a este cobro

  @Column({ name: 'tenant_id', type: 'uuid' })
  tenantId: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  static crear(
    pagoId: string,
    cobroId: string,
    montoAplicado: number,
    tenantId: string,
  ): PagoCobro {
    const vinculo = new PagoCobro();
    vinculo.pagoId = pagoId;
    vinculo.cobroId = cobroId;
    vinculo.montoAplicado = montoAplicado;
    vinculo.tenantId = tenantId;
    return vinculo;
  }
}
