import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Solicitud, SolicitudEstado } from '../../domain/solicitud.entity';

@Injectable()
export class SolicitudRepository {
  constructor(
    @InjectRepository(Solicitud)
    private readonly repo: Repository<Solicitud>,
  ) {}

  async findByUsuario(usuarioId: string): Promise<Solicitud[]> {
    return this.repo.find({
      where: { usuarioId },
      order: { fecha: 'DESC' },
    });
  }

  async findByTenant(tenantId: string): Promise<Solicitud[]> {
    return this.repo.find({
      where: { tenantId },
      relations: { usuario: true },
      order: { fecha: 'DESC' },
    });
  }

  async findPendingByUsuario(usuarioId: string): Promise<Solicitud[]> {
    return this.repo.find({
      where: [
        { usuarioId, estado: SolicitudEstado.PENDIENTE },
        { usuarioId, estado: SolicitudEstado.EN_REVISION },
      ],
      relations: { usuario: true },
      order: { fecha: 'DESC' },
    });
  }

  async findPendingByTenant(tenantId: string): Promise<Solicitud[]> {
    return this.repo.find({
      where: [
        { tenantId, estado: SolicitudEstado.PENDIENTE },
        { tenantId, estado: SolicitudEstado.EN_REVISION },
      ],
      relations: { usuario: true },
      order: { fecha: 'DESC' },
    });
  }

  async findById(id: string): Promise<Solicitud | null> {
    return this.repo.findOne({ where: { id } });
  }

  async save(solicitud: Solicitud): Promise<Solicitud> {
    return this.repo.save(solicitud);
  }
}
