import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, ILike } from 'typeorm';
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
    tipo?: string,
  ): Promise<Solicitud[]> {
    const where: any = {};
    if (tipo) {
      const tipoLower = tipo.toLowerCase();
      if (tipoLower.includes('revision') || tipoLower === 'sr') {
        where.tipo = ILike('%revisi%');
      } else if (tipoLower.includes('cobro') || tipoLower === 'sc') {
        where.tipo = ILike('%cobro%');
      }
    }

    return super.findByTenant(tenantId, {
      where,
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

  async findPendingByTenant(
    tenantId: string,
    tipo?: string,
  ): Promise<Solicitud[]> {
    const where: any = {};
    if (tipo) {
      const tipoLower = tipo.toLowerCase();
      if (tipoLower.includes('revision') || tipoLower === 'sr') {
        where.tipo = ILike('%revisi%');
      } else if (tipoLower.includes('cobro') || tipoLower === 'sc') {
        where.tipo = ILike('%cobro%');
      }
    }

    const results = await super.findByTenant(tenantId, {
      where,
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

  async findActiveRevisionByPagoOrCobro(
    tenantId: string,
    pagoId?: string,
    cobroId?: string,
  ): Promise<Solicitud | null> {
    const activeStates = [
      SolicitudEstado.PENDIENTE,
      SolicitudEstado.EN_ESPERA,
      SolicitudEstado.EN_REVISION,
    ];
    const qb = this.repo
      .createQueryBuilder('s')
      .where('s.tenantId = :tenantId', { tenantId })
      .andWhere('s.estado IN (:...activeStates)', { activeStates });

    if (pagoId && cobroId) {
      qb.andWhere(
        '(s.pagoId = :pagoId OR (s.cobroId = :cobroId AND (s.tipo ILIKE :revisi OR s.nroRecibo LIKE :srPrefix)))',
        {
          pagoId,
          cobroId,
          revisi: '%revisi%',
          srPrefix: 'SR-%',
        },
      );
    } else if (pagoId) {
      qb.andWhere('s.pagoId = :pagoId', { pagoId });
    } else if (cobroId) {
      qb.andWhere(
        's.cobroId = :cobroId AND (s.tipo ILIKE :revisi OR s.nroRecibo LIKE :srPrefix)',
        {
          cobroId,
          revisi: '%revisi%',
          srPrefix: 'SR-%',
        },
      );
    } else {
      return null;
    }

    return qb.getOne();
  }

  async findActiveCobroByResidente(
    tenantId: string,
    usuarioId: string,
    residenteId?: string | null,
    cobroId?: string,
  ): Promise<Solicitud | null> {
    const activeStates = [
      SolicitudEstado.PENDIENTE,
      SolicitudEstado.EN_ESPERA,
      SolicitudEstado.EN_CAMINO,
    ];
    const qb = this.repo
      .createQueryBuilder('s')
      .where('s.tenantId = :tenantId', { tenantId })
      .andWhere('s.estado IN (:...activeStates)', { activeStates })
      .andWhere('(s.tipo ILIKE :cobro OR s.nroRecibo LIKE :scPrefix)', {
        cobro: '%cobro%',
        scPrefix: 'SC-%',
      });

    if (cobroId) {
      qb.andWhere('s.cobroId = :cobroId', { cobroId });
    } else if (residenteId) {
      qb.andWhere('(s.usuarioId = :usuarioId OR s.residenteId = :residenteId)', {
        usuarioId,
        residenteId,
      });
    } else {
      qb.andWhere('s.usuarioId = :usuarioId', { usuarioId });
    }

    return qb.getOne();
  }

  async delete(id: string): Promise<void> {
    await this.repo.delete(id);
  }
}
