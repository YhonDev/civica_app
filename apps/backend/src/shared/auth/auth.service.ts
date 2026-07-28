import {
  Injectable,
  UnauthorizedException,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { Usuario } from '../../iam/domain/usuario.entity';

@Injectable()
export class AuthService {
  // Blacklist de refresh tokens revocados (en memoria; en producción usar Redis o DB)
  private readonly revokedRefreshTokens = new Set<string>();

  constructor(
    @InjectRepository(Usuario)
    private readonly usuarioRepository: Repository<Usuario>,
    private readonly jwtService: JwtService,
  ) {}

  async validateUser(username: string, password: string): Promise<Usuario> {
    const user = await this.usuarioRepository.findOne({
      where: { email: username },
    });
    if (!user) {
      throw new UnauthorizedException('Credenciales inválidas');
    }

    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Credenciales inválidas');
    }

    if (!user.activo) {
      throw new UnauthorizedException('Usuario inactivo');
    }

    return user;
  }

  async login(
    usuario: Usuario,
  ): Promise<{ accessToken: string; refreshToken: string; usuario: Usuario }> {
    const payload = {
      sub: usuario.id,
      email: usuario.email,
      rol: usuario.rol,
      tenantId: usuario.tenantId,
    };

    const accessToken = this.jwtService.sign(payload, { expiresIn: '1h' });
    const refreshToken = this.jwtService.sign(
      { sub: usuario.id, type: 'refresh' },
      { expiresIn: '30d' },
    );

    return { accessToken, refreshToken, usuario };
  }

  async refreshToken(
    token: string,
  ): Promise<{ accessToken: string; refreshToken: string; usuario: Usuario }> {
    // Verificar si el refresh token fue revocado
    if (this.revokedRefreshTokens.has(token)) {
      throw new UnauthorizedException('Sesión cerrada. Inicia sesión nuevamente.');
    }

    try {
      const payload = this.jwtService.verify<{
        sub: string;
        type: string;
      }>(token);

      if (payload.type !== 'refresh') {
        throw new UnauthorizedException('Token de refresco inválido');
      }

      const user = await this.usuarioRepository.findOne({
        where: { id: payload.sub },
      });

      if (!user) {
        throw new NotFoundException('Usuario no encontrado');
      }

      if (!user.activo) {
        throw new UnauthorizedException('Usuario inactivo');
      }

      const newPayload = {
        sub: user.id,
        email: user.email,
        rol: user.rol,
        tenantId: user.tenantId,
      };

        const accessToken = this.jwtService.sign(newPayload, { expiresIn: '1h' });
        const refreshToken = this.jwtService.sign(
          { sub: user.id, type: 'refresh' },
          { expiresIn: '30d' },
        );

        return { accessToken, refreshToken, usuario: user };
    } catch (error) {
      if (error instanceof UnauthorizedException || error instanceof NotFoundException) {
        throw error;
      }
      throw new UnauthorizedException('Token de refresco inválido o expirado');
    }
  }

  /** Revoca un refresh token (logout). Idempotente. */
  revokeRefreshToken(token: string): void {
    this.revokedRefreshTokens.add(token);
  }

  /** Regenera la password de un usuario (residente o cobrador) y retorna las nuevas credenciales. */
  async resetPasswordForUser(params: {
    residenteId?: string;
    usuarioId?: string;
    tenantId: string;
  }): Promise<{ username: string; password: string }> {
    let usuario: Usuario | null = null;

    if (params.usuarioId) {
      // Buscar por ID de usuario directo (para cobradores)
      usuario = await this.usuarioRepository.findOne({
        where: { id: params.usuarioId, tenantId: params.tenantId },
      });
    } else if (params.residenteId) {
      // Buscar por residenteId (para residentes)
      usuario = await this.usuarioRepository.findOne({
        where: { residenteId: params.residenteId, tenantId: params.tenantId },
      });
    }

    if (!usuario) {
      throw new NotFoundException('No se encontró usuario para este ID');
    }

    // Generar nueva password de 10 caracteres
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
    let nuevaPassword = '';
    for (let i = 0; i < 10; i++) {
      nuevaPassword += chars.charAt(Math.floor(Math.random() * chars.length));
    }

    const passwordHash = await bcrypt.hash(nuevaPassword, 10);
    usuario.passwordHash = passwordHash;
    await this.usuarioRepository.save(usuario);

    return { username: usuario.email, password: nuevaPassword };
  }

  /** Actualiza credenciales (username y/o password) de un usuario. */
  async updateCredentials(params: {
    usuarioId?: string;
    tenantId: string;
    newUsername?: string;
    newPassword?: string;
    currentPassword?: string;
  }): Promise<{ username: string }> {
    const usuario = await this.usuarioRepository.findOne({
      where: { id: params.usuarioId, tenantId: params.tenantId },
    });

    if (!usuario) {
      throw new NotFoundException('Usuario no encontrado');
    }

    // Si se proporciona password actual, verificarla
    if (params.currentPassword) {
      const valid = await bcrypt.compare(params.currentPassword, usuario.passwordHash);
      if (!valid) {
        throw new UnauthorizedException('La contraseña actual es incorrecta');
      }
    }

    // Actualizar username si se proporciona
    if (params.newUsername && params.newUsername !== usuario.email) {
      // Verificar que el nuevo username no exista
      const existente = await this.usuarioRepository.findOne({
        where: { email: params.newUsername, tenantId: params.tenantId },
      });
      if (existente && existente.id !== usuario.id) {
        throw new BadRequestException('Este nombre de usuario ya está en uso');
      }
      usuario.email = params.newUsername;
    }

    // Actualizar password si se proporciona
    if (params.newPassword) {
      const passwordHash = await bcrypt.hash(params.newPassword, 10);
      usuario.passwordHash = passwordHash;
    }

    await this.usuarioRepository.save(usuario);

    return { username: usuario.email };
  }

  /** Retorna el username de un usuario (para admin). */
  async getCredentials(usuarioId: string, tenantId: string): Promise<{ username: string }> {
    const usuario = await this.usuarioRepository.findOne({
      where: { id: usuarioId, tenantId },
    });

    if (!usuario) {
      throw new NotFoundException('Usuario no encontrado');
    }

    return { username: usuario.email };
  }
}
