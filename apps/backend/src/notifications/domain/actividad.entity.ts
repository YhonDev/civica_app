import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
} from 'typeorm';

@Entity('actividad')
export class Actividad {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'tenant_id', type: 'uuid' })
  tenantId: string;

  @Column({ name: 'tipo', type: 'varchar', length: 50 })
  tipo: string;

  @Column({ name: 'descripcion', type: 'text' })
  descripcion: string;

  @Column({ name: 'usuario_nombre', type: 'varchar', length: 255 })
  usuarioNombre: string;

  @Column({ name: 'usuario_id', type: 'uuid' })
  usuarioId: string;

  @Column({ name: 'metadata', type: 'jsonb', default: () => "'{}'" })
  metadata: Record<string, unknown>;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  static crear(
    tenantId: string,
    tipo: string,
    descripcion: string,
    usuarioNombre: string,
    usuarioId: string,
    metadata?: Record<string, unknown>,
  ): Actividad {
    const actividad = new Actividad();
    actividad.tenantId = tenantId;
    actividad.tipo = tipo;
    actividad.descripcion = descripcion;
    actividad.usuarioNombre = usuarioNombre;
    actividad.usuarioId = usuarioId;
    actividad.metadata = metadata ?? {};
    return actividad;
  }
}
