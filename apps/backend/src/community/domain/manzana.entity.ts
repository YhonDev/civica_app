import { Exclude } from 'class-transformer';
import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  OneToMany,
} from 'typeorm';
import { Etapa } from './etapa.entity';
import { Casa } from './casa.entity';

@Entity('manzanas')
export class Manzana {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'nombre', type: 'varchar', length: 255 })
  nombre: string;

  @Column({ name: 'etapa_id', type: 'uuid' })
  etapaId: string;

  @ManyToOne(() => Etapa, (etapa) => etapa.manzanas, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'etapa_id' })
  etapa: Etapa;

  @OneToMany(() => Casa, (casa) => casa.manzana, { cascade: true })
  casas: Casa[];

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  // --- Domain behavior ---

  static crear(nombre: string, etapa: Etapa): Manzana {
    const manzana = new Manzana();
    manzana.nombre = nombre;
    manzana.etapa = etapa;
    manzana.etapaId = etapa.id;
    manzana.casas = [];
    return manzana;
  }

  crearCasa(direccionInterna: string): Casa {
    const casa = Casa.crear(direccionInterna, this);
    this.casas.push(casa);
    return casa;
  }
}
