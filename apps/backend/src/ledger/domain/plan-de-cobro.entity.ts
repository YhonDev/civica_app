import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
} from 'typeorm';
import { type ModalidadRecaudo } from '../../shared/common/value-objects';
import { PeriodoCobro } from './periodo-cobro.entity';

/**
 * PlanDeCobro representa el plan de recaudo asociado a una casa y su residente.
 * Reemplaza a CuentaDeCartera.
 * Los periodos y cobros se generan automáticamente a partir del plan.
 */
@Entity('planes_de_cobro')
export class PlanDeCobro {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'casa_id', type: 'uuid', nullable: true })
  casaId: string | null;

  @Column({ name: 'residente_id', type: 'uuid' })
  residenteId: string;

  @Column({ name: 'tenant_id', type: 'uuid' })
  tenantId: string;

  @Column({ name: 'proyecto_id', type: 'uuid' })
  proyectoId: string;

  @Column({ name: 'modalidad', type: 'varchar', length: 20 })
  modalidad: ModalidadRecaudo;

  @Column({ name: 'valor_mensual', type: 'integer', nullable: true })
  valorMensual: number | null;

  @Column({ name: 'fecha_activacion', type: 'date' })
  fechaActivacion: string;

  @Column({ name: 'activa', type: 'boolean', default: true })
  activa: boolean;

  @OneToMany(() => PeriodoCobro, (periodo) => periodo.plan)
  periodos: PeriodoCobro[];

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  static crear(
    casaId: string | null,
    residenteId: string,
    tenantId: string,
    proyectoId: string,
    modalidad: ModalidadRecaudo,
    fechaActivacion: string,
    valorMensual?: number,
  ): PlanDeCobro {
    const plan = new PlanDeCobro();
    plan.casaId = casaId;
    plan.residenteId = residenteId;
    plan.tenantId = tenantId;
    plan.proyectoId = proyectoId;
    plan.modalidad = modalidad;
    plan.fechaActivacion = fechaActivacion;
    plan.valorMensual = valorMensual ?? null;
    plan.activa = true;
    plan.periodos = [];
    return plan;
  }

  cambiarModalidad(modalidad: ModalidadRecaudo): void {
    this.modalidad = modalidad;
  }

  desactivar(): void {
    this.activa = false;
  }
}
