import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
} from 'typeorm';
import { Etapa } from './etapa.entity';

@Entity('proyectos')
export class Proyecto {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'nombre', type: 'varchar', length: 255 })
  nombre: string;

  @Column({ name: 'tenant_id', type: 'uuid' })
  tenantId: string;

  @Column({ name: 'recordatorios_automaticos', type: 'boolean', default: true })
  recordatoriosAutomaticos: boolean;

  @Column({ name: 'permite_pagos_parciales', type: 'boolean', default: false })
  permitePagosParciales: boolean;

  @Column({ name: 'modo_mantenimiento', type: 'boolean', default: false })
  modoMantenimiento: boolean;

  @Column({ name: 'fecha_mantenimiento', type: 'timestamptz', nullable: true })
  fechaMantenimiento: Date | null;

  @OneToMany(() => Etapa, (etapa) => etapa.proyecto, { cascade: true })
  etapas: Etapa[];

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  // --- Domain behavior ---

  static crear(nombre: string, tenantId: string): Proyecto {
    const proyecto = new Proyecto();
    proyecto.nombre = nombre;
    proyecto.tenantId = tenantId;
    proyecto.recordatoriosAutomaticos = true;
    proyecto.permitePagosParciales = false;
    proyecto.modoMantenimiento = false;
    proyecto.fechaMantenimiento = null;
    proyecto.etapas = [];
    return proyecto;
  }

  activarMantenimiento(): void {
    this.modoMantenimiento = true;
    this.fechaMantenimiento = new Date();
  }

  desactivarMantenimiento(): void {
    this.modoMantenimiento = false;
    this.fechaMantenimiento = null;
  }

  agregarEtapa(nombre: string): Etapa {
    const etapa = Etapa.crear(nombre, this);
    this.etapas.push(etapa);
    return etapa;
  }

  eliminarEtapa(etapaId: string): void {
    this.etapas = this.etapas.filter((e) => e.id !== etapaId);
  }
}
