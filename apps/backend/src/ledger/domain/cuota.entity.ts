import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Money, type EstadoCuota } from '../../shared/common/value-objects';
import { Propietario } from '../../community/domain/propietario.entity';

@Entity('cuotas')
export class Cuota {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'propietario_id', type: 'uuid' })
  propietarioId: string;

  @ManyToOne(() => Propietario, { createForeignKeyConstraints: false })
  @JoinColumn({ name: 'propietario_id' })
  propietario: Propietario;

  @Column({ name: 'tenant_id', type: 'uuid' })
  tenantId: string;

  @Column({ name: 'tarifa_id', type: 'uuid', nullable: true })
  tarifaId: string | null;

  @Column({ name: 'concepto', type: 'varchar', length: 255 })
  concepto: string;

  @Column({ name: 'monto', type: 'integer' })
  monto: number; // en centavos COP

  @Column({ name: 'monto_pagado', type: 'integer', default: 0 })
  montoPagado: number; // en centavos COP

  @Column({ name: 'periodo_inicio', type: 'date' })
  periodoInicio: string;

  @Column({ name: 'periodo_fin', type: 'date' })
  periodoFin: string;

  @Column({ name: 'fecha_vencimiento', type: 'date' })
  fechaVencimiento: string;

  @Column({ name: 'estado', type: 'varchar', length: 20, default: 'PENDIENTE' })
  estado: EstadoCuota;

  @Column({ name: 'notificacion_enviada', type: 'boolean', default: false })
  notificacionEnviada: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  static crear(
    propietarioId: string,
    tenantId: string,
    concepto: string,
    monto: Money,
    periodoInicio: string,
    periodoFin: string,
    fechaVencimiento: string,
    tarifaId?: string,
  ): Cuota {
    const cuota = new Cuota();
    cuota.propietarioId = propietarioId;
    cuota.tenantId = tenantId;
    cuota.tarifaId = tarifaId ?? null;
    cuota.concepto = concepto;
    cuota.monto = monto.amount;
    cuota.montoPagado = 0;
    cuota.periodoInicio = periodoInicio;
    cuota.periodoFin = periodoFin;
    cuota.fechaVencimiento = fechaVencimiento;
    cuota.estado = 'PENDIENTE';
    cuota.notificacionEnviada = false;
    return cuota;
  }

  getMonto(): Money {
    return new Money(this.monto, 'COP');
  }

  getMontoPagado(): Money {
    return new Money(this.montoPagado, 'COP');
  }

  saldo(): Money {
    return new Money(this.monto - this.montoPagado, 'COP');
  }

  /**
   * Aplica un pago parcial o total a esta cuota.
   * Retorna el excedente (si el pago supera el saldo).
   */
  aplicarPago(montoPago: Money): Money {
    if (this.estado === 'PAGADA') {
      throw new Error('No se puede pagar una cuota ya PAGADA');
    }

    const saldoActual = this.saldo();

    if (montoPago.amount >= saldoActual.amount) {
      // Pago completo o con excedente
      const excedenteAmount = montoPago.amount - saldoActual.amount;
      this.montoPagado += saldoActual.amount;
      this.estado = 'PAGADA';
      return Money.ofCOP(excedenteAmount);
    } else {
      // Pago parcial
      this.montoPagado += montoPago.amount;
      this.estado = 'PARCIAL';
      return Money.ofCOP(0);
    }
  }

  marcarVencida(): void {
    if (this.estado === 'PENDIENTE' || this.estado === 'PARCIAL') {
      this.estado = 'VENCIDA';
    }
  }

  estaPagada(): boolean {
    return this.estado === 'PAGADA';
  }

  estaVencida(): boolean {
    return this.estado === 'VENCIDA';
  }

  estaPendiente(): boolean {
    return this.estado === 'PENDIENTE';
  }
}
