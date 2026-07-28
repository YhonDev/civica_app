import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ResidenteRepository } from '../../infrastructure/residente.repository';
import { ResidenteDetailDto } from '../dtos/residente-detail.dto';
import { Usuario } from '../../../iam/domain/usuario.entity';

@Injectable()
export class ResidenteDetailQuery {
  constructor(
    private readonly residenteRepository: ResidenteRepository,
    @InjectRepository(Usuario)
    private readonly usuarioRepository: Repository<Usuario>,
  ) {}

  async execute(id: string, tenantId: string): Promise<ResidenteDetailDto> {
    const residente = await this.residenteRepository.findByIdWithRelations(id);

    if (!residente) {
      throw new NotFoundException('Residente no encontrado');
    }

    // Buscar el username del usuario asociado a este residente
    const usuario = await this.usuarioRepository.findOne({
      where: { residenteId: id },
    });

    return {
      id: residente.id,
      tipo: residente.tipo ?? 'PROPIETARIO',
      nombre: residente.nombre,
      telefono: residente.telefono,
      email: residente.email,
      documento: residente.documento ?? null,
      casaActualId: residente.casaActualId,
      modalidadPago: residente.modalidadPago,
      tenantId: residente.tenantId,
      username: usuario?.email ?? null,
      tenencias: (residente.tenencias ?? []).map((t) => ({
        id: t.id,
        casaId: t.casaId,
        fechaInicio: t.fechaInicio,
        fechaFin: t.fechaFin,
        casa: t.casa
          ? {
              direccionInterna: t.casa.direccionInterna,
              manzana: t.casa.manzana
                ? {
                    nombre: t.casa.manzana.nombre,
                    etapa: t.casa.manzana.etapa
                      ? { nombre: t.casa.manzana.etapa.nombre }
                      : undefined,
                  }
                : undefined,
            }
          : undefined,
      })),
    };
  }
}
