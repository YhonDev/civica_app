import { Exclude } from 'class-transformer';
import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Usuario } from './usuario.entity';

@Entity('auth_sessions')
export class AuthSession {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'usuario_id', type: 'uuid' })
  usuarioId: string;

  @ManyToOne(() => Usuario, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'usuario_id' })
  usuario: Usuario;

  @Column({ name: 'refresh_token_hash', type: 'varchar', length: 255 })
  @Exclude()
  refreshTokenHash: string;

  @Column({ name: 'device_id', type: 'varchar', length: 255, nullable: true })
  deviceId: string | null;

  @Column({ name: 'device_name', type: 'varchar', length: 255, nullable: true })
  deviceName: string | null;

  @Column({ name: 'ip_address', type: 'varchar', length: 64, nullable: true })
  ipAddress: string | null;

  @Column({ name: 'user_agent', type: 'varchar', length: 255, nullable: true })
  userAgent: string | null;

  @Column({ name: 'is_revoked', type: 'boolean', default: false })
  isRevoked: boolean;

  @Column({ name: 'expires_at', type: 'timestamptz' })
  expiresAt: Date;

  @Column({
    name: 'last_used_at',
    type: 'timestamptz',
    default: () => 'CURRENT_TIMESTAMP',
  })
  lastUsedAt: Date;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
