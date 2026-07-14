import { Injectable, NotFoundException } from '@nestjs/common';
import { ResidenteRepository } from '../../infrastructure/residente.repository';
import { ResidenteDetailDto } from '../dtos/residente-detail.dto';

@Injectable()
export class ResidenteDetailQuery {
  constructor(private readonly residenteRepository: ResidenteRepository) {}

  async execute(id: string, tenantId: string): Promise<ResidenteDetailDto> {
    const residente = await this.residenteRepository.findByIdWithRelations(id);

    if (!residente) {
      throw new NotFoundException('Residente no encontrado');
    }

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
