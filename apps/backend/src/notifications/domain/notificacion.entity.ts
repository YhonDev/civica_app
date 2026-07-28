import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

export enum EstadoNotificacion {
  PENDIENTE = 'PENDIENTE',
  ENVIADA = 'ENVIADA',
  FALLIDA = 'FALLIDA',
}

@Entity('notificaciones')
export class Notificacion {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'tipo', type: 'varchar', length: 50, default: 'CUOTA_VENCIDA' })
  tipo: string;

  @Column({ name: 'destinatario_email', type: 'varchar', length: 255 })
  destinatarioEmail: string;

  @Column({ name: 'asunto', type: 'varchar', length: 255 })
  asunto: string;

  @Column({ name: 'cuerpo', type: 'text' })
  cuerpo: string;

  @Column({ name: 'estado', type: 'varchar', length: 20, default: EstadoNotificacion.PENDIENTE })
  estado: EstadoNotificacion;

  @Column({ name: 'intentos', type: 'int', default: 0 })
  intentos: number;

  @Column({ name: 'ultimo_intento', type: 'timestamp', nullable: true })
  ultimoIntento: Date | null;

  @Column({ name: 'cobro_id', type: 'uuid', nullable: true })
  cobroId: string | null;

  @Column({ name: 'tenant_id', type: 'uuid' })
  tenantId: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  static crear(
    destinatarioEmail: string,
    asunto: string,
    cuerpo: string,
    tenantId: string,
    cobroId?: string,
  ): Notificacion {
    const notif = new Notificacion();
    notif.tipo = 'CUOTA_VENCIDA';
    notif.destinatarioEmail = destinatarioEmail;
    notif.asunto = asunto;
    notif.cuerpo = cuerpo;
    notif.estado = EstadoNotificacion.PENDIENTE;
    notif.intentos = 0;
    notif.tenantId = tenantId;
    notif.cobroId = cobroId ?? null;
    return notif;
  }
}
