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
import { Casa } from './casa.entity';

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
  conjunto: Conjunto;

  @OneToMany(() => Casa, (casa) => casa.etapa, { cascade: true })
  casas: Casa[];

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  // --- Domain behavior ---

  static crear(nombre: string, conjunto: Conjunto): Etapa {
    const etapa = new Etapa();
    etapa.nombre = nombre;
    etapa.conjunto = conjunto;
    etapa.conjuntoId = conjunto.id;
    etapa.casas = [];
    return etapa;
  }

  crearCasa(direccionInterna: string): Casa {
    const casa = Casa.crear(direccionInterna, this);
    this.casas.push(casa);
    return casa;
  }
}
