import { Exclude } from 'class-transformer';
import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Residente } from './residente.entity';
import { Casa } from './casa.entity';

@Entity('tenencias')
export class Tenencia {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'residente_id', type: 'uuid' })
  residenteId: string;

  @Column({ name: 'casa_id', type: 'uuid' })
  casaId: string;

  @ManyToOne(() => Casa, { createForeignKeyConstraints: false })
  @JoinColumn({ name: 'casa_id' })
  casa: Casa;

  @Column({ name: 'fecha_inicio', type: 'date' })
  fechaInicio: Date;

  @Column({ name: 'fecha_fin', type: 'date', nullable: true })
  fechaFin: Date | null;

  @ManyToOne(() => Residente, (residente) => residente.tenencias, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'residente_id' })
  @Exclude()
  residente: Residente;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  // --- Domain behavior ---

  static crear(
    residenteId: string,
    casaId: string,
    fechaInicio: Date,
  ): Tenencia {
    if (fechaInicio > new Date()) {
      throw new Error('La fecha de inicio no puede ser futura');
    }

    const tenencia = new Tenencia();
    tenencia.residenteId = residenteId;
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
