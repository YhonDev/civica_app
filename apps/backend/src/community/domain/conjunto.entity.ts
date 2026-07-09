import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
} from 'typeorm';
import { Etapa } from './etapa.entity';

@Entity('conjuntos')
export class Conjunto {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'nombre', type: 'varchar', length: 255 })
  nombre: string;

  @Column({ name: 'tenant_id', type: 'uuid' })
  tenantId: string;

  @OneToMany(() => Etapa, (etapa) => etapa.conjunto, { cascade: true })
  etapas: Etapa[];

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  // --- Domain behavior ---

  static crear(nombre: string, tenantId: string): Conjunto {
    const conjunto = new Conjunto();
    conjunto.nombre = nombre;
    conjunto.tenantId = tenantId;
    conjunto.etapas = [];
    return conjunto;
  }

  agregarEtapa(nombre: string): Etapa {
    const etapa = Etapa.crear(nombre, this);
    this.etapas.push(etapa);
    return etapa;
  }

  eliminarEtapa(etapaId: string): void {
    this.etapas = this.etapas.filter((e) => e.id !== etapaId);
  }
}
