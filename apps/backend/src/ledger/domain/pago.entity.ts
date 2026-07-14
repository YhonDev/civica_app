import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';
import { Money, type SyncStatus } from '../../shared/common/value-objects';

@Entity('pagos')
export class Pago {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'client_payment_id', type: 'varchar', length: 255 })
  clientPaymentId: string;

  @Column({ name: 'tenant_id', type: 'uuid' })
  tenantId: string;

  @Column({ name: 'cobro_id', type: 'uuid', nullable: true })
  cobroId: string | null;

  @Column({ name: 'monto', type: 'integer' })
  monto: number; // en centavos COP

  @Column({ name: 'fecha_pago', type: 'date' })
  fechaPago: string;

  @Column({ name: 'cobrador_id', type: 'uuid' })
  cobradorId: string;

  @Column({ name: 'residente_id', type: 'uuid' })
  residenteId: string;

  @Column({ name: 'fecha_sync', type: 'timestamptz', nullable: true })
  fechaSync: Date | null;

  @Column({ name: 'sync_status', type: 'varchar', length: 20, default: 'SYNC_OK' })
  syncStatus: SyncStatus;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  static crear(
    clientPaymentId: string,
    tenantId: string,
    monto: Money,
    fechaPago: string,
    cobradorId: string,
    residenteId: string,
    cobroId?: string,
  ): Pago {
    const pago = new Pago();
    pago.clientPaymentId = clientPaymentId;
    pago.tenantId = tenantId;
    pago.monto = monto.amount;
    pago.fechaPago = fechaPago;
    pago.cobradorId = cobradorId;
    pago.residenteId = residenteId;
    pago.cobroId = cobroId ?? null;
    pago.fechaSync = null;
    pago.syncStatus = 'SYNC_OK';
    return pago;
  }

  getMonto(): Money {
    return new Money(this.monto, 'COP');
  }

  marcarSync(fecha: Date): void {
    this.fechaSync = fecha;
    this.syncStatus = 'SYNC_OK';
  }
}
