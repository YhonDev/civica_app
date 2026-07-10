import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Usuario } from './domain/usuario.entity';
import { AsignacionEtapa } from './domain/asignacion-etapa.entity';
import { AuthModule } from '../shared/auth/auth.module';
import { CrearUsuarioUseCase } from './application/use-cases/crear-usuario.use-case';
import { AsignarEtapaUseCase } from './application/use-cases/asignar-etapa.use-case';
import { AuthController } from './infrastructure/controllers/auth.controller';
import { UsuariosController } from './infrastructure/controllers/usuarios.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([Usuario, AsignacionEtapa]),
    AuthModule,
  ],
  controllers: [AuthController, UsuariosController],
  providers: [CrearUsuarioUseCase, AsignarEtapaUseCase],
  exports: [TypeOrmModule, CrearUsuarioUseCase, AsignarEtapaUseCase],
})
export class IamModule {}
