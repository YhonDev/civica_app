import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Tenencia } from './tenencia.entity';
import { Casa } from './casa.entity';
import { Cobro } from '../../ledger/domain/cobro.entity';
import { type Frecuencia } from '../../shared/common/value-objects';

@Entity('residentes')
export class Residente {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: 20, default: 'PROPIETARIO' })
  tipo: 'PROPIETARIO' | 'INQUILINO';

  @Column({ name: 'nombre', type: 'varchar', length: 255 })
  nombre: string;

  @Column({ name: 'telefono', type: 'varchar', length: 20 })
  telefono: string;

  @Column({ name: 'email', type: 'varchar', length: 255, nullable: true })
  email: string | null;

  @Column({ type: 'varchar', length: 50, nullable: true })
  documento: string | null;

  @Column({ name: 'casa_actual_id', type: 'uuid', nullable: true })
  casaActualId: string | null;

  @Column({ name: 'tenant_id', type: 'uuid' })
  tenantId: string;

  @Column({ name: 'modalidad_pago', type: 'varchar', length: 20, default: 'MENSUAL' })
  modalidadPago: Frecuencia;

  @ManyToOne(() => Casa)
  @JoinColumn({ name: 'casa_actual_id' })
  casaActual: Casa;

  @OneToMany(() => Tenencia, (tenencia) => tenencia.residente, { cascade: true })
  tenencias: Tenencia[];

  @OneToMany(() => Cobro, (cobro) => cobro.residente)
  cobros: Cobro[];

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  // --- Domain behavior ---

  static crear(
    nombre: string,
    telefono: string,
    email: string | null,
    tenantId: string,
    modalidadPago: Frecuencia = 'MENSUAL',
    tipo: 'PROPIETARIO' | 'INQUILINO' = 'PROPIETARIO',
    casaActualId?: string,
  ): Residente {
    const residente = new Residente();
    residente.tipo = tipo;
    residente.nombre = nombre;
    residente.telefono = telefono;
    residente.email = email;
    residente.tenantId = tenantId;
    residente.modalidadPago = modalidadPago;
    residente.casaActualId = casaActualId ?? null;
    residente.tenencias = [];
    residente.cobros = [];
    return residente;
  }

  asignarCasa(casaId: string): void {
    this.casaActualId = casaId;
  }

  agregarTenencia(casaId: string, fechaInicio: Date): Tenencia {
    // Invariante: no duplicar tenencia activa para la misma casa
    const activaExistente = this.tenencias.find(
      (t) => t.casaId === casaId && t.fechaFin === null,
    );
    if (activaExistente) {
      throw new Error(
        `El residente ya tiene una tenencia activa para la casa ${casaId}`,
      );
    }

    const tenencia = Tenencia.crear(this.id, casaId, fechaInicio);
    tenencia.residente = this;
    this.tenencias.push(tenencia);
    return tenencia;
  }

  finalizarTenencia(casaId: string, fechaFin: Date): void {
    const tenencia = this.tenencias.find(
      (t) => t.casaId === casaId && t.fechaFin === null,
    );
    if (!tenencia) {
      throw new Error(
        `No se encontró una tenencia activa para la casa ${casaId}`,
      );
    }
    tenencia.finalizar(fechaFin);
  }
}
