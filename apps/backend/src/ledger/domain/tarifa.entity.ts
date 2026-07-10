import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';
import { type Frecuencia, Money } from '../../shared/common/value-objects';

@Entity('tarifas')
export class Tarifa {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'tenant_id', type: 'uuid' })
  tenantId: string;

  @Column({ name: 'conjunto_id', type: 'uuid' })
  conjuntoId: string;

  @Column({ name: 'frecuencia', type: 'varchar', length: 20 })
  frecuencia: Frecuencia;

  @Column({ name: 'monto', type: 'integer' })
  monto: number; // en centavos COP

  @Column({ name: 'fecha_vigencia', type: 'date' })
  fechaVigencia: string; // ISO date string

  @Column({ name: 'activa', type: 'boolean', default: true })
  activa: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  static crear(
    conjuntoId: string,
    tenantId: string,
    frecuencia: Frecuencia,
    monto: Money,
    fechaVigencia: string,
  ): Tarifa {
    const tarifa = new Tarifa();
    tarifa.conjuntoId = conjuntoId;
    tarifa.tenantId = tenantId;
    tarifa.frecuencia = frecuencia;
    tarifa.monto = monto.amount;
    tarifa.fechaVigencia = fechaVigencia;
    tarifa.activa = true;
    return tarifa;
  }

  getMonto(): Money {
    return new Money(this.monto, 'COP');
  }

  desactivar(): void {
    this.activa = false;
  }
}
