import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Pago } from './pago.entity';

@Entity('pago_ediciones')
export class PagoEdicion {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'pago_id', type: 'uuid' })
  pagoId: string;

  @ManyToOne(() => Pago, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'pago_id' })
  pago: Pago;

  @Column({ name: 'tenant_id', type: 'uuid' })
  tenantId: string;

  @Column({ name: 'monto_anterior', type: 'integer' })
  montoAnterior: number; // en centavos COP

  @Column({ name: 'monto_nuevo', type: 'integer' })
  montoNuevo: number; // en centavos COP

  @Column({ name: 'motivo', type: 'text' })
  motivo: string;

  @Column({ name: 'usuario_id', type: 'uuid' })
  usuarioId: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  static crear(
    pagoId: string,
    tenantId: string,
    montoAnterior: number,
    montoNuevo: number,
    motivo: string,
    usuarioId: string,
  ): PagoEdicion {
    const edicion = new PagoEdicion();
    edicion.pagoId = pagoId;
    edicion.tenantId = tenantId;
    edicion.montoAnterior = montoAnterior;
    edicion.montoNuevo = montoNuevo;
    edicion.motivo = motivo;
    edicion.usuarioId = usuarioId;
    return edicion;
  }
}
