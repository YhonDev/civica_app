import { Exclude } from 'class-transformer';
import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  Unique,
} from 'typeorm';
import { Usuario } from './usuario.entity';
import { Etapa } from '../../community/domain/etapa.entity';

@Entity('asignaciones_etapa')
@Unique(['usuarioId', 'etapaId'])
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

  @ManyToOne(() => Etapa, { createForeignKeyConstraints: false })
  @JoinColumn({ name: 'etapa_id' })
  etapa: Etapa;

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
