import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Usuario } from '../../iam/domain/usuario.entity';

interface JwtPayload {
  sub: string;
  email: string;
  rol: string;
  tenantId: string;
  type?: string;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    @InjectRepository(Usuario)
    private readonly usuarioRepository: Repository<Usuario>,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey:
        process.env.JWT_SECRET ||
        (() => {
          throw new Error('JWT_SECRET debe estar configurado');
        })(),
    });
  }

  async validate(payload: JwtPayload): Promise<Usuario> {
    // Reject refresh tokens used as access tokens — they have a 30d TTL
    // and must never grant API access.
    if (payload.type === 'refresh') {
      throw new UnauthorizedException(
        'Token de refresco no es válido para acceso a la API',
      );
    }

    const user = await this.usuarioRepository.findOne({
      where: { id: payload.sub },
    });

    if (!user || !user.activo) {
      throw new UnauthorizedException('Token inválido o usuario inactivo');
    }

    // El tenant del token debe coincidir con el actual del usuario: si fue
    // movido de tenant, los access tokens emitidos antes quedan inválidos
    // de inmediato (ventana máxima: TTL del access token, 15 min).
    if (payload.tenantId && user.tenantId !== payload.tenantId) {
      throw new UnauthorizedException('Token emitido para otro tenant');
    }

    return user;
  }
}
