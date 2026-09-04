import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ConflictException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { Usuario } from '../../domain/usuario.entity';
import { AsignacionEtapa } from '../../domain/asignacion-etapa.entity';

interface AsignarEtapaParams {
  usuarioId: string;
  etapaId: string;
  tenantId: string;
}

@Injectable()
export class AsignarEtapaUseCase {
  constructor(
    @InjectRepository(Usuario)
    private readonly usuarioRepository: Repository<Usuario>,
    @InjectRepository(AsignacionEtapa)
    private readonly asignacionRepository: Repository<AsignacionEtapa>,
    private readonly dataSource: DataSource,
  ) {}

  async execute(params: AsignarEtapaParams): Promise<AsignacionEtapa> {
    // Validar que el usuario existe
    const usuario = await this.usuarioRepository.findOne({
      where: { id: params.usuarioId },
    });
    if (!usuario) {
      throw new NotFoundException(
        `Usuario con id ${params.usuarioId} no encontrado`,
      );
    }

    // Validar que pertenece al mismo tenant
    if (usuario.tenantId !== params.tenantId) {
      throw new BadRequestException(
        'El usuario no pertenece al tenant especificado',
      );
    }

    // Validar que la etapa existe y pertenece al tenant
    const etapaExists = await this.dataSource
      .createQueryBuilder()
      .select('1')
      .from('etapas', 'e')
      .innerJoin('proyectos', 'p', 'e.proyecto_id = p.id')
      .where('e.id = :etapaId', { etapaId: params.etapaId })
      .andWhere('p.tenant_id = :tenantId', { tenantId: params.tenantId })
      .getRawOne();

    if (!etapaExists) {
      throw new NotFoundException(
        `Etapa con id ${params.etapaId} no encontrada`,
      );
    }

    // Validar que no esté ya asignada
    const asignacionExistente = await this.asignacionRepository.findOne({
      where: {
        usuarioId: params.usuarioId,
        etapaId: params.etapaId,
      },
    });
    if (asignacionExistente) {
      throw new ConflictException(
        `El usuario ya tiene asignada la etapa ${params.etapaId}`,
      );
    }

    // Crear la asignación
    const asignacion = AsignacionEtapa.crear(
      params.usuarioId,
      params.etapaId,
      params.tenantId,
    );

    return this.asignacionRepository.save(asignacion);
  }
}
