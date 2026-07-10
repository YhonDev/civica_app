import { Exclude } from 'class-transformer';
import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Usuario } from './usuario.entity';

@Entity('asignaciones_etapa')
export class AsignacionEtapa {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'usuario_id', type: 'uuid' })
  usuarioId: string;

  @ManyToOne(() => Usuario, (usuario) => usuario.asignaciones, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'usuario_id' })
  @Exclude()
  usuario: Usuario;

  @Column({ name: 'etapa_id', type: 'uuid' })
  etapaId: string;

  @Column({ name: 'tenant_id', type: 'uuid' })
  tenantId: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  static crear(usuarioId: string, etapaId: string, tenantId: string): AsignacionEtapa {
    const asignacion = new AsignacionEtapa();
    asignacion.usuarioId = usuarioId;
    asignacion.etapaId = etapaId;
    asignacion.tenantId = tenantId;
    return asignacion;
  }
}
