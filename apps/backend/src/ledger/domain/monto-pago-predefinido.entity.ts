import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';
import { Money } from '../../shared/common/value-objects';

@Entity('montos_predefinidos')
export class MontoPagoPredefinido {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'tenant_id', type: 'uuid' })
  tenantId: string;

  @Column({ name: 'conjunto_id', type: 'uuid' })
  conjuntoId: string;

  @Column({ name: 'monto', type: 'integer' })
  monto: number; // en centavos COP

  @Column({ name: 'descripcion', type: 'varchar', length: 255 })
  descripcion: string;

  @Column({ name: 'activo', type: 'boolean', default: true })
  activo: boolean;

  @Column({ name: 'orden', type: 'integer', default: 0 })
  orden: number;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  static crear(
    tenantId: string,
    conjuntoId: string,
    monto: Money,
    descripcion: string,
    orden: number,
  ): MontoPagoPredefinido {
    const mpp = new MontoPagoPredefinido();
    mpp.tenantId = tenantId;
    mpp.conjuntoId = conjuntoId;
    mpp.monto = monto.amount;
    mpp.descripcion = descripcion;
    mpp.activo = true;
    mpp.orden = orden;
    return mpp;
  }

  getMonto(): Money {
    return new Money(this.monto, 'COP');
  }

  desactivar(): void {
    this.activo = false;
  }
}
