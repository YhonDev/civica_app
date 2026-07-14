import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  OneToMany,
} from 'typeorm';
import { PlanDeCobro } from './plan-de-cobro.entity';
import { Cobro } from './cobro.entity';

/**
 * PeriodoCobro representa un período mensual dentro de un PlanDeCobro.
 * Cada período contiene los cobros generados para ese mes.
 */
@Entity('periodos_cobro')
export class PeriodoCobro {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'plan_id', type: 'uuid' })
  planId: string;

  @ManyToOne(() => PlanDeCobro, (plan) => plan.periodos)
  @JoinColumn({ name: 'plan_id' })
  plan: PlanDeCobro;

  @Column({ type: 'integer' })
  mes: number;

  @Column({ type: 'integer' })
  anio: number;

  @Column({ name: 'fecha_inicio', type: 'date' })
  fechaInicio: string;

  @Column({ name: 'fecha_fin', type: 'date' })
  fechaFin: string;

  @Column({ name: 'estado', type: 'varchar', length: 20, default: 'ACTIVO' })
  estado: 'ACTIVO' | 'CERRADO';

  @Column({ name: 'tenant_id', type: 'uuid' })
  tenantId: string;

  @OneToMany(() => Cobro, (cobro) => cobro.periodo)
  cobros: Cobro[];

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  static crear(
    planId: string,
    mes: number,
    anio: number,
    fechaInicio: string,
    fechaFin: string,
    tenantId: string,
  ): PeriodoCobro {
    const periodo = new PeriodoCobro();
    periodo.planId = planId;
    periodo.mes = mes;
    periodo.anio = anio;
    periodo.fechaInicio = fechaInicio;
    periodo.fechaFin = fechaFin;
    periodo.tenantId = tenantId;
    periodo.estado = 'ACTIVO';
    periodo.cobros = [];
    return periodo;
  }

  cerrar(): void {
    this.estado = 'CERRADO';
  }

  estaActivo(): boolean {
    return this.estado === 'ACTIVO';
  }
}
