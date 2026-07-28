import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  TableInheritance,
} from 'typeorm';

export type TipoTicket = 'COBRO' | 'REVISION' | 'ANULACION';
export type EstadoTicket = 'EMITIDO' | 'ANULADO';

/**
 * Base entity for all tickets (receipts).
 *
 * Uses Single Table Inheritance (STI): one `tickets` table,
 * discriminated by the `tipo` column.
 *
 * A ticket is an IMMUTABLE DOCUMENT emitted at a point in time.
 * All contextual data (residente name, casa address, etc.) is
 * snapshotted at emission — never references live data.
 */
@Entity('tickets')
@TableInheritance({ column: { type: 'varchar', name: 'tipo' } })
export class Ticket {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  /** Discriminator — set by @ChildEntity */
  @Column({ name: 'tipo', type: 'varchar', length: 20 })
  tipo: TipoTicket;

  /** Sequential number per tenant per year: TKT-2026-000001 */
  @Column({ name: 'numero', type: 'varchar', length: 20 })
  numero: string;

  @Column({ name: 'fecha', type: 'timestamptz', default: () => 'now()' })
  fecha: Date;

  @Column({ name: 'tenant_id', type: 'uuid' })
  tenantId: string;

  // ── Snapshot: Residente ────────────────────────────────

  @Column({ name: 'residente_id', type: 'uuid' })
  residenteId: string;

  @Column({ name: 'residente_nombre', type: 'varchar', length: 255 })
  residenteNombre: string;

  @Column({ name: 'residente_documento', type: 'varchar', length: 50, nullable: true })
  residenteDocumento: string | null;

  // ── Snapshot: Ubicación ────────────────────────────────

  @Column({ name: 'casa_direccion', type: 'varchar', length: 255 })
  casaDireccion: string;

  @Column({ name: 'etapa', type: 'varchar', length: 255 })
  etapa: string;

  @Column({ name: 'manzana', type: 'varchar', length: 255 })
  manzana: string;

  // ── State ──────────────────────────────────────────────

  @Column({ name: 'estado', type: 'varchar', length: 20, default: 'EMITIDO' })
  estado: EstadoTicket;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  // ── Domain behavior ────────────────────────────────────

  anular(): void {
    if (this.estado === 'ANULADO') {
      throw new Error(`Ticket ${this.numero} ya está anulado`);
    }
    this.estado = 'ANULADO';
  }

  estaEmitido(): boolean {
    return this.estado === 'EMITIDO';
  }
}
