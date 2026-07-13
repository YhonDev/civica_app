import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
} from 'typeorm';
import { Tenencia } from './tenencia.entity';
import { Cuota } from '../../ledger/domain/cuota.entity';
import { type Frecuencia } from '../../shared/common/value-objects';

@Entity('propietarios')
export class Propietario {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'nombre', type: 'varchar', length: 255 })
  nombre: string;

  @Column({ name: 'telefono', type: 'varchar', length: 20 })
  telefono: string;

  @Column({ name: 'email', type: 'varchar', length: 255, nullable: true })
  email: string | null;

  @Column({ name: 'tenant_id', type: 'uuid' })
  tenantId: string;

  @Column({ name: 'modalidad_pago', type: 'varchar', length: 20, default: 'MENSUAL' })
  modalidadPago: Frecuencia;

  @OneToMany(() => Tenencia, (tenencia) => tenencia.propietario, { cascade: true })
  tenencias: Tenencia[];

  @OneToMany(() => Cuota, (cuota) => cuota.propietario)
  cuotas: Cuota[];

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
  ): Propietario {
    const propietario = new Propietario();
    propietario.nombre = nombre;
    propietario.telefono = telefono;
    propietario.email = email;
    propietario.tenantId = tenantId;
    propietario.modalidadPago = modalidadPago;
    propietario.tenencias = [];
    propietario.cuotas = [];
    return propietario;
  }

  agregarTenencia(casaId: string, fechaInicio: Date): Tenencia {
    // Invariante: no duplicar tenencia activa para la misma casa
    const activaExistente = this.tenencias.find(
      (t) => t.casaId === casaId && t.fechaFin === null,
    );
    if (activaExistente) {
      throw new Error(
        `El propietario ya tiene una tenencia activa para la casa ${casaId}`,
      );
    }

    const tenencia = Tenencia.crear(this.id, casaId, fechaInicio);
    tenencia.propietario = this;
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
