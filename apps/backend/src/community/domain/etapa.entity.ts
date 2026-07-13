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
import { Conjunto } from './conjunto.entity';
import { Manzana } from './manzana.entity';

@Entity('etapas')
export class Etapa {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'nombre', type: 'varchar', length: 255 })
  nombre: string;

  @Column({ name: 'conjunto_id', type: 'uuid' })
  conjuntoId: string;

  @ManyToOne(() => Conjunto, (conjunto) => conjunto.etapas, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'conjunto_id' })
  @Exclude()
  conjunto: Conjunto;

  @OneToMany(() => Manzana, (manzana) => manzana.etapa, { cascade: true })
  manzanas: Manzana[];

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  // --- Domain behavior ---

  static crear(nombre: string, conjunto: Conjunto): Etapa {
    const etapa = new Etapa();
    etapa.nombre = nombre;
    etapa.conjunto = conjunto;
    etapa.conjuntoId = conjunto.id;
    etapa.manzanas = [];
    return etapa;
  }

  crearManzana(nombre: string): Manzana {
    const manzana = Manzana.crear(nombre, this);
    this.manzanas.push(manzana);
    return manzana;
  }
}
