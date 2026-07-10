import {
  Injectable,
  UnauthorizedException,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { Usuario } from '../../iam/domain/usuario.entity';

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(Usuario)
    private readonly usuarioRepository: Repository<Usuario>,
    private readonly jwtService: JwtService,
  ) {}

  async validateUser(email: string, password: string): Promise<Usuario> {
    const user = await this.usuarioRepository.findOne({ where: { email } });
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
  ): Promise<{ accessToken: string; refreshToken: string }> {
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

      return { accessToken, refreshToken };
    } catch (error) {
      if (error instanceof UnauthorizedException || error instanceof NotFoundException) {
        throw error;
      }
      throw new UnauthorizedException('Token de refresco inválido o expirado');
    }
  }
}
