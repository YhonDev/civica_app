import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';
import { type Frecuencia } from '../../shared/common/value-objects';

/**
 * CuentaDeCartera es el agregado raíz del BC Cartera (Ledger).
 * Representa la cartera de un propietario: su frecuencia de pago y el conjunto al que pertenece.
 * Las cuotas y pagos se asocian a través del propietarioId.
 */
@Entity('cuentas_cartera')
export class CuentaDeCartera {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'propietario_id', type: 'uuid', unique: true })
  propietarioId: string;

  @Column({ name: 'tenant_id', type: 'uuid' })
  tenantId: string;

  @Column({ name: 'conjunto_id', type: 'uuid' })
  conjuntoId: string;

  @Column({ name: 'frecuencia', type: 'varchar', length: 20 })
  frecuencia: Frecuencia;

  @Column({ name: 'fecha_activacion', type: 'date' })
  fechaActivacion: string;

  @Column({ name: 'activa', type: 'boolean', default: true })
  activa: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  static crear(
    propietarioId: string,
    tenantId: string,
    conjuntoId: string,
    frecuencia: Frecuencia,
    fechaActivacion: string,
  ): CuentaDeCartera {
    const cuenta = new CuentaDeCartera();
    cuenta.propietarioId = propietarioId;
    cuenta.tenantId = tenantId;
    cuenta.conjuntoId = conjuntoId;
    cuenta.frecuencia = frecuencia;
    cuenta.fechaActivacion = fechaActivacion;
    cuenta.activa = true;
    return cuenta;
  }

  cambiarFrecuencia(frecuencia: Frecuencia): void {
    this.frecuencia = frecuencia;
  }

  desactivar(): void {
    this.activa = false;
  }
}
