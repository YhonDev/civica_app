import { Exclude } from 'class-transformer';
import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
} from 'typeorm';
import { AsignacionEtapa } from './asignacion-etapa.entity';

export enum RolUsuario {
  ADMIN = 'ADMIN',
  COBRADOR = 'COBRADOR',
  RESIDENTE = 'RESIDENTE',
  /** @deprecated Use RESIDENTE — kept for DB migration compat. */
  PROPIETARIO = 'PROPIETARIO',
}

@Entity('usuarios')
export class Usuario {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'email', type: 'varchar', length: 255, unique: true })
  email: string;

  @Column({ name: 'password_hash', type: 'varchar', length: 255 })
  @Exclude()
  passwordHash: string;

  @Column({ name: 'nombre', type: 'varchar', length: 255 })
  nombre: string;

  @Column({ name: 'rol', type: 'varchar', length: 20, default: RolUsuario.COBRADOR })
  rol: RolUsuario;

  @Column({ name: 'residente_id', type: 'uuid', nullable: true })
  residenteId: string | null;

  @Column({ name: 'tenant_id', type: 'uuid' })
  tenantId: string;

  @Column({ name: 'activo', type: 'boolean', default: true })
  activo: boolean;

  @OneToMany(() => AsignacionEtapa, (asignacion) => asignacion.usuario, { cascade: true })
  asignaciones: AsignacionEtapa[];

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  static crear(
    email: string,
    passwordHash: string,
    nombre: string,
    rol: RolUsuario,
    tenantId: string,
    residenteId?: string,
  ): Usuario {
    const usuario = new Usuario();
    usuario.email = email;
    usuario.passwordHash = passwordHash;
    usuario.nombre = nombre;
    usuario.rol = rol;
    usuario.tenantId = tenantId;
    usuario.residenteId = residenteId ?? null;
    usuario.activo = true;
    usuario.asignaciones = [];
    return usuario;
  }

  desactivar(): void {
    this.activo = false;
  }

  activar(): void {
    this.activo = true;
  }

  esAdmin(): boolean {
    return this.rol === RolUsuario.ADMIN;
  }

  esCobrador(): boolean {
    return this.rol === RolUsuario.COBRADOR;
  }
}
