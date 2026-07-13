import { Exclude } from 'class-transformer';
import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Manzana } from './manzana.entity';

@Entity('casas')
export class Casa {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'direccion_interna', type: 'varchar', length: 255 })
  direccionInterna: string;

  @Column({ name: 'manzana_id', type: 'uuid' })
  manzanaId: string;

  @ManyToOne(() => Manzana, (manzana) => manzana.casas, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'manzana_id' })
  manzana: Manzana;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  // --- Domain behavior ---

  static crear(direccionInterna: string, manzana: Manzana): Casa {
    const casa = new Casa();
    casa.direccionInterna = direccionInterna;
    casa.manzana = manzana;
    casa.manzanaId = manzana.id;
    return casa;
  }
}
