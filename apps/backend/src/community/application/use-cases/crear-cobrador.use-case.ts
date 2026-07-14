import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { GenerarCredencialesService } from '../../../iam/application/services/generar-credenciales.service';
import { Usuario, RolUsuario } from '../../../iam/domain/usuario.entity';

interface CrearCobradorParams {
  nombre: string;
  telefono: string;
  tenantId: string;
  etapaIds?: string[];
}

interface ResultadoCrearCobrador {
  usuario: Usuario;
  credenciales: {
    username: string;
    password: string;
  };
}

/**
 * Crea un nuevo cobrador en el sistema.
 *
 * El backend genera automáticamente:
 * - username: "{nombre}{primerApellido}cobrador"
 * - password: "{nombre}{primerApellido}{añoActual}"
 *
 * También asigna las etapas especificadas al cobrador.
 */
@Injectable()
export class CrearCobradorUseCase {
  constructor(
    private readonly generarCredenciales: GenerarCredencialesService,
    @InjectRepository(Usuario)
    private readonly usuarioRepository: Repository<Usuario>,
    private readonly dataSource: DataSource,
  ) {}

  async execute(params: CrearCobradorParams): Promise<ResultadoCrearCobrador> {
    if (!params.nombre || params.nombre.trim().length < 3) {
      throw new BadRequestException(
        'El nombre debe tener al menos 3 caracteres',
      );
    }

    // Generar credenciales con el patrón
    const username = this.generarCredenciales.generarUsernameCobrador(
      params.nombre,
    );
    const password = this.generarCredenciales.generarPasswordCobrador(
      params.nombre,
    );

    // Verificar que el username no exista
    const existente = await this.usuarioRepository.findOne({
      where: { email: username },
    });
    if (existente) {
      throw new BadRequestException(
        `Ya existe un cobrador con el nombre ${params.nombre}`,
      );
    }

    const passwordHash = await bcrypt.hash(password, 10);

    // Crear usuario en transacción
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      const usuario = Usuario.crear(
        username,
        passwordHash,
        params.nombre,
        RolUsuario.COBRADOR,
        params.tenantId,
      );

      const usuarioGuardado = await queryRunner.manager.save(usuario);

      // Asignar etapas si se especificaron
      if (params.etapaIds && params.etapaIds.length > 0) {
        for (const etapaId of params.etapaIds) {
          await queryRunner.manager.query(
            `INSERT INTO asignaciones_etapa (id, usuario_id, etapa_id, tenant_id, created_at)
             VALUES (gen_random_uuid(), $1, $2, $3, NOW())
             ON CONFLICT (usuario_id, etapa_id) DO NOTHING`,
            [usuarioGuardado.id, etapaId, params.tenantId],
          );
        }
      }

      await queryRunner.commitTransaction();

      return {
        usuario: usuarioGuardado,
        credenciales: { username, password },
      };
    } catch (error) {
      await queryRunner.rollbackTransaction();
      throw error;
    } finally {
      await queryRunner.release();
    }
  }
}
