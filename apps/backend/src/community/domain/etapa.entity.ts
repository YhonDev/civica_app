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
import { Proyecto } from './proyecto.entity';
import { Manzana } from './manzana.entity';

@Entity('etapas')
export class Etapa {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'nombre', type: 'varchar', length: 255 })
  nombre: string;

  @Column({ name: 'proyecto_id', type: 'uuid' })
  proyectoId: string;

  @ManyToOne(() => Proyecto, (proyecto) => proyecto.etapas, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'proyecto_id' })
  @Exclude()
  proyecto: Proyecto;

  @OneToMany(() => Manzana, (manzana) => manzana.etapa, { cascade: true })
  manzanas: Manzana[];

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  // --- Domain behavior ---

  static crear(nombre: string, proyecto: Proyecto): Etapa {
    const etapa = new Etapa();
    etapa.nombre = nombre;
    etapa.proyecto = proyecto;
    etapa.proyectoId = proyecto.id;
    etapa.manzanas = [];
    return etapa;
  }

  crearManzana(nombre: string): Manzana {
    const manzana = Manzana.crear(nombre, this);
    this.manzanas.push(manzana);
    return manzana;
  }
}
