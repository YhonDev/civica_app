import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Etapa } from './etapa.entity';

@Entity('casas')
export class Casa {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'direccion_interna', type: 'varchar', length: 255 })
  direccionInterna: string;

  @Column({ name: 'etapa_id', type: 'uuid' })
  etapaId: string;

  @ManyToOne(() => Etapa, (etapa) => etapa.casas, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'etapa_id' })
  etapa: Etapa;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  // --- Domain behavior ---

  static crear(direccionInterna: string, etapa: Etapa): Casa {
    const casa = new Casa();
    casa.direccionInterna = direccionInterna;
    casa.etapa = etapa;
    casa.etapaId = etapa.id;
    return casa;
  }
}
