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
      secretOrKey: process.env.JWT_SECRET || 'dev-secret-change-in-production',
    });
  }

  async validate(payload: JwtPayload): Promise<Usuario> {
    const user = await this.usuarioRepository.findOne({
      where: { id: payload.sub },
    });

    if (!user || !user.activo) {
      throw new UnauthorizedException('Token inválido o usuario inactivo');
    }

    return user;
  }
}
