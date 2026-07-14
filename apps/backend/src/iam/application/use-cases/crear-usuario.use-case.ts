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
  username: string;
  password: string;
  nombre: string;
  rol: RolUsuario;
  tenantId: string;
  residenteId?: string;
}

@Injectable()
export class CrearUsuarioUseCase {
  constructor(
    @InjectRepository(Usuario)
    private readonly usuarioRepository: Repository<Usuario>,
  ) {}

  async execute(params: CrearUsuarioParams): Promise<Usuario> {
    // Validar username
    if (!params.username || params.username.trim().length < 3) {
      throw new BadRequestException(
        'El nombre de usuario debe tener al menos 3 caracteres',
      );
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

    // Verificar unicidad del username
    const existingUser = await this.usuarioRepository.findOne({
      where: { email: params.username },
    });
    if (existingUser) {
      throw new ConflictException(
        `Ya existe un usuario con el nombre de usuario ${params.username}`,
      );
    }

    // Hash de la contraseña
    const passwordHash = await bcrypt.hash(params.password, 10);

    // Crear entidad de dominio
    // El campo 'email' en la BD se usa para almacenar el username
    const usuario = Usuario.crear(
      params.username,
      passwordHash,
      params.nombre,
      params.rol,
      params.tenantId,
      params.residenteId,
    );

    return this.usuarioRepository.save(usuario);
  }
}
