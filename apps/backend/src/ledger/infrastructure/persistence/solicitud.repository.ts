import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Solicitud, SolicitudEstado } from '../../domain/solicitud.entity';
import { BaseTenantRepository } from '../../../shared/common/infrastructure/base-tenant.repository';

@Injectable()
export class SolicitudRepository extends BaseTenantRepository<Solicitud> {
  constructor(
    @InjectRepository(Solicitud)
    protected readonly repo: Repository<Solicitud>,
  ) {
    super(repo);
  }

  async findByUsuario(
    usuarioId: string,
    tenantId: string,
    limit?: number,
    offset?: number,
  ): Promise<Solicitud[]> {
    // tenantId obligatorio: sin él, un usuarioId que colisionara entre
    // tenants filtraría solicitudes de otro tenant (fuga multi-tenant).
    return this.repo.find({
      where: { usuarioId, tenantId },
      relations: { usuario: true, cobro: true },
      order: { fecha: 'DESC' },
      take: limit ? Math.min(Number(limit), 100) : undefined,
      skip: offset ? Number(offset) : undefined,
    });
  }

  async findByTenant(
    tenantId: string,
    limit?: number,
    offset?: number,
  ): Promise<Solicitud[]> {
    return super.findByTenant(tenantId, {
      relations: { usuario: true, cobro: true },
      order: { fecha: 'DESC' },
      take: limit ? Math.min(Number(limit), 100) : undefined,
      skip: offset ? Number(offset) : undefined,
    });
  }

  async findPendingByUsuario(usuarioId: string): Promise<Solicitud[]> {
    return this.repo.find({
      where: [
        { usuarioId, estado: SolicitudEstado.PENDIENTE },
        { usuarioId, estado: SolicitudEstado.EN_ESPERA },
        { usuarioId, estado: SolicitudEstado.EN_CAMINO },
        { usuarioId, estado: SolicitudEstado.EN_REVISION },
      ],
      relations: { usuario: true, cobro: true },
      order: { fecha: 'DESC' },
    });
  }

  async findPendingByTenant(tenantId: string): Promise<Solicitud[]> {
    const results = await super.findByTenant(tenantId, {
      relations: { usuario: true, cobro: true },
      order: { fecha: 'DESC' },
    });

    return results.filter(
      (s) =>
        s.estado === SolicitudEstado.PENDIENTE ||
        s.estado === SolicitudEstado.EN_ESPERA ||
        s.estado === SolicitudEstado.EN_CAMINO ||
        s.estado === SolicitudEstado.EN_REVISION,
    );
  }

  async findById(id: string, tenantId: string): Promise<Solicitud | null> {
    return this.repo.findOne({ where: { id, tenantId } });
  }

  async delete(id: string): Promise<void> {
    await this.repo.delete(id);
  }
}
