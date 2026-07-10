import {
  Injectable,
  BadRequestException,
  ConflictException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { Usuario, RolUsuario } from '../../domain/usuario.entity';

interface CrearUsuarioParams {
  email: string;
  password: string;
  nombre: string;
  rol: RolUsuario;
  tenantId: string;
  propietarioId?: string;
}

@Injectable()
export class CrearUsuarioUseCase {
  constructor(
    @InjectRepository(Usuario)
    private readonly usuarioRepository: Repository<Usuario>,
  ) {}

  async execute(params: CrearUsuarioParams): Promise<Usuario> {
    // Validar email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(params.email)) {
      throw new BadRequestException('El formato del email es inválido');
    }

    // Validar password
    if (params.password.length < 6) {
      throw new BadRequestException(
        'La contraseña debe tener al menos 6 caracteres',
      );
    }

    // Validar rol
    if (!Object.values(RolUsuario).includes(params.rol)) {
      throw new BadRequestException(`El rol ${params.rol} no es válido`);
    }

    // Validar tenantId
    if (!params.tenantId || params.tenantId.trim().length === 0) {
      throw new BadRequestException('El tenantId es requerido');
    }

    // Verificar unicidad del email
    const existingUser = await this.usuarioRepository.findOne({
      where: { email: params.email },
    });
    if (existingUser) {
      throw new ConflictException(
        `Ya existe un usuario con el email ${params.email}`,
      );
    }

    // Hash de la contraseña
    const passwordHash = await bcrypt.hash(params.password, 10);

    // Crear entidad de dominio
    const usuario = Usuario.crear(
      params.email,
      passwordHash,
      params.nombre,
      params.rol,
      params.tenantId,
      params.propietarioId,
    );

    return this.usuarioRepository.save(usuario);
  }
}
