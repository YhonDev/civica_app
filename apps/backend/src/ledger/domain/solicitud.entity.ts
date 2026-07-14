import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Usuario } from '../../iam/domain/usuario.entity';
import { Cobro } from './cobro.entity';

export enum SolicitudEstado {
  PENDIENTE = 'PENDIENTE',
  EN_REVISION = 'EN_REVISION',
  RESUELTA = 'RESUELTA',
  RECHAZADA = 'RECHAZADA',
  APROBADA = 'APROBADA',
}

@Entity('solicitudes')
export class Solicitud {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'tenant_id', type: 'uuid' })
  tenantId: string;

  @Column({ name: 'usuario_id', type: 'uuid' })
  usuarioId: string;

  @ManyToOne(() => Usuario)
  @JoinColumn({ name: 'usuario_id' })
  usuario: Usuario;

  @Column({ name: 'cobro_id', type: 'uuid' })
  cobroId: string;

  @ManyToOne(() => Cobro)
  @JoinColumn({ name: 'cobro_id' })
  cobro: Cobro;

  @Column({ name: 'nro_recibo', type: 'varchar', length: 20, unique: true })
  nroRecibo: string;

  @Column({ name: 'tipo', type: 'varchar', length: 255 })
  tipo: string;

  @Column({ name: 'descripcion', type: 'text' })
  descripcion: string;

  @Column({
    name: 'estado',
    type: 'varchar',
    length: 20,
    default: SolicitudEstado.EN_REVISION,
  })
  estado: SolicitudEstado;

  @Column({ name: 'fecha', type: 'timestamptz', default: () => 'CURRENT_TIMESTAMP' })
  fecha: Date;

  @Column({ name: 'respuesta', type: 'text', nullable: true })
  respuesta: string | null;

  @Column({ name: 'fecha_respuesta', type: 'timestamptz', nullable: true })
  fechaRespuesta: Date | null;

  @Column({ name: 'casa_id', type: 'uuid', nullable: true })
  casaId: string | null;

  @Column({ name: 'residente_id', type: 'uuid', nullable: true })
  residenteId: string | null;

  @Column({ name: 'pago_id', type: 'uuid', nullable: true })
  pagoId: string | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  static crear(
    tenantId: string,
    usuarioId: string,
    cobroId: string,
    tipo: string,
    descripcion: string,
  ): Solicitud {
    const solicitud = new Solicitud();
    solicitud.tenantId = tenantId;
    solicitud.usuarioId = usuarioId;
    solicitud.cobroId = cobroId;
    
    const randomNum = Math.floor(100000 + Math.random() * 900000);
    solicitud.nroRecibo = `TK-${randomNum}`;
    
    solicitud.tipo = tipo;
    solicitud.descripcion = descripcion;
    solicitud.estado = SolicitudEstado.EN_REVISION;
    solicitud.fecha = new Date();
    return solicitud;
  }
}
