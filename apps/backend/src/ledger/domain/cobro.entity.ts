import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Money, type EstadoCobro } from '../../shared/common/value-objects';
import { Residente } from '../../community/domain/residente.entity';
import { Casa } from '../../community/domain/casa.entity';
import { PeriodoCobro } from './periodo-cobro.entity';

@Entity('cobros')
export class Cobro {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'residente_id', type: 'uuid' })
  residenteId: string;

  @ManyToOne(() => Residente, {
    createForeignKeyConstraints: false,
    eager: true,
  })
  @JoinColumn({ name: 'residente_id' })
  residente: Residente;

  @Column({ name: 'periodo_id', type: 'uuid', nullable: true })
  periodoId: string | null;

  @ManyToOne(() => PeriodoCobro, { createForeignKeyConstraints: false })
  @JoinColumn({ name: 'periodo_id' })
  periodo: PeriodoCobro;

  @Column({ name: 'tenant_id', type: 'uuid' })
  tenantId: string;

  @Column({ name: 'casa_id', type: 'uuid', nullable: true })
  casaId: string | null;

  @ManyToOne(() => Casa, { createForeignKeyConstraints: false, eager: true })
  @JoinColumn({ name: 'casa_id' })
  casa: Casa;

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
  estado: EstadoCobro;

  @Column({ name: 'notificacion_enviada', type: 'boolean', default: false })
  notificacionEnviada: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  static crear(
    residenteId: string,
    tenantId: string,
    concepto: string,
    monto: Money,
    periodoInicio: string,
    periodoFin: string,
    fechaVencimiento: string,
    tarifaId?: string,
    periodoId?: string,
    casaId?: string,
  ): Cobro {
    const cobro = new Cobro();
    cobro.residenteId = residenteId;
    cobro.tenantId = tenantId;
    cobro.tarifaId = tarifaId ?? null;
    cobro.periodoId = periodoId ?? null;
    cobro.casaId = casaId ?? null;
    cobro.concepto = concepto;
    cobro.monto = monto.amount;
    cobro.montoPagado = 0;
    cobro.periodoInicio = periodoInicio;
    cobro.periodoFin = periodoFin;
    cobro.fechaVencimiento = fechaVencimiento;
    cobro.estado = 'PENDIENTE';
    cobro.notificacionEnviada = false;
    return cobro;
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
   * Aplica un pago parcial o total a este cobro.
   * Retorna el excedente (si el pago supera el saldo).
   */
  aplicarPago(montoPago: Money): Money {
    if (this.estado === 'PAGADA') {
      throw new Error('No se puede pagar un cobro ya PAGADO');
    }
    if (this.estado === 'ANULADO') {
      throw new Error('No se puede pagar un cobro en estado ANULADO');
    }

    const saldoActual = this.saldo();

    if (montoPago.amount >= saldoActual.amount) {
      const excedenteAmount = montoPago.amount - saldoActual.amount;
      this.montoPagado += saldoActual.amount;
      this.estado = 'PAGADA';
      return Money.ofCOP(excedenteAmount);
    } else {
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
