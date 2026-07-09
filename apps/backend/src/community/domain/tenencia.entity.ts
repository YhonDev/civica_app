import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Propietario } from './propietario.entity';

@Entity('tenencias')
export class Tenencia {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'propietario_id', type: 'uuid' })
  propietarioId: string;

  @Column({ name: 'casa_id', type: 'uuid' })
  casaId: string;

  @Column({ name: 'fecha_inicio', type: 'date' })
  fechaInicio: Date;

  @Column({ name: 'fecha_fin', type: 'date', nullable: true })
  fechaFin: Date | null;

  @ManyToOne(() => Propietario, (propietario) => propietario.tenencias, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'propietario_id' })
  propietario: Propietario;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  // --- Domain behavior ---

  static crear(
    propietarioId: string,
    casaId: string,
    fechaInicio: Date,
  ): Tenencia {
    if (fechaInicio > new Date()) {
      throw new Error('La fecha de inicio no puede ser futura');
    }

    const tenencia = new Tenencia();
    tenencia.propietarioId = propietarioId;
    tenencia.casaId = casaId;
    tenencia.fechaInicio = fechaInicio;
    tenencia.fechaFin = null;
    return tenencia;
  }

  finalizar(fechaFin: Date): void {
    if (fechaFin < this.fechaInicio) {
      throw new Error(
        'La fecha de fin no puede ser anterior a la fecha de inicio',
      );
    }
    this.fechaFin = fechaFin;
  }

  estaActiva(): boolean {
    return this.fechaFin === null;
  }
}
