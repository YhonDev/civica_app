import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { EntityManager, Repository } from 'typeorm';
import { Ticket } from '../../domain/ticket.entity';
import { TicketCobro } from '../../domain/ticket-cobro.entity';
import { BaseTenantRepository } from '../../../shared/common/infrastructure/base-tenant.repository';

@Injectable()
export class TicketRepository extends BaseTenantRepository<Ticket> {
  constructor(
    @InjectRepository(Ticket)
    protected readonly repo: Repository<Ticket>,
  ) {
    super(repo);
  }

  async save(ticket: Ticket): Promise<Ticket> {
    return this.repo.save(ticket);
  }

  async findById(id: string, tenantId: string): Promise<Ticket | null> {
    return this.repo.findOne({ where: { id, tenantId } });
  }

  async findByNumero(tenantId: string, numero: string): Promise<Ticket | null> {
    return this.repo.findOne({ where: { tenantId, numero } });
  }

  async findByPago(
    pagoId: string,
    tenantId: string,
  ): Promise<TicketCobro | null> {
    return this.repo.findOne({
      where: { tipo: 'COBRO', pagoId, tenantId } as any,
    }) as Promise<TicketCobro | null>;
  }

  async findByResidente(
    residenteId: string,
    tenantId: string,
    options?: { limit?: number },
  ): Promise<Ticket[]> {
    return this.repo.find({
      where: { residenteId, tenantId },
      order: { fecha: 'DESC' },
      take: options?.limit,
    });
  }

  async findByTenantPaginated(
    tenantId: string,
    options?: { limit?: number; offset?: number },
  ): Promise<Ticket[]> {
    return this.repo.find({
      where: { tenantId },
      order: { fecha: 'DESC' },
      take: options?.limit,
      skip: options?.offset,
    });
  }

  /**
   * Generates the next sequential ticket number for a tenant+year.
   * Format: TKT-YYYY-NNNNNN
   *
   * Uses MAX on the numero column filtered by tenant and year prefix
   * to guarantee sequential ordering.
   */
  async nextNumero(tenantId: string): Promise<string> {
    const year = new Date().getFullYear();
    const prefix = `TKT-${year}-`;

    const result = await this.repo
      .createQueryBuilder('ticket')
      .select('MAX(ticket.numero)', 'maxNumero')
      .where('ticket.tenant_id = :tenantId', { tenantId })
      .andWhere('ticket.numero LIKE :prefix', { prefix: `${prefix}%` })
      .getRawOne();

    let nextSeq = 1;
    if (result?.maxNumero) {
      const currentMax = result.maxNumero as string;
      const seqPart = currentMax.replace(prefix, '');
      nextSeq = parseInt(seqPart, 10) + 1;
    }

    return `${prefix}${String(nextSeq).padStart(6, '0')}`;
  }

  /**
   * Generates the next sequential ticket number within a transaction,
   * serializing concurrent calls per tenant via a Postgres advisory lock.
   *
   * Prevents the MAX(numero)+1 race where two concurrent payments for the
   * same tenant could compute the same sequence and duplicate a ticket number.
   * Must be called inside an active transaction.
   */
  async nextNumeroLocked(
    manager: EntityManager,
    tenantId: string,
  ): Promise<string> {
    const year = new Date().getFullYear();
    const prefix = `TKT-${year}-`;

    // Advisory lock scoped to the transaction: serializa la numeración
    // por tenant dentro de la transacción del pago.
    await manager.query('SELECT pg_advisory_xact_lock(hashtextextended($1, 0))', [
      `ticket-num:${tenantId}`,
    ]);

    const result = await manager
      .createQueryBuilder(Ticket, 'ticket')
      .select('MAX(ticket.numero)', 'maxNumero')
      .where('ticket.tenant_id = :tenantId', { tenantId })
      .andWhere('ticket.numero LIKE :prefix', { prefix: `${prefix}%` })
      .getRawOne();

    let nextSeq = 1;
    if (result?.maxNumero) {
      const currentMax = result.maxNumero as string;
      const seqPart = currentMax.replace(prefix, '');
      nextSeq = parseInt(seqPart, 10) + 1;
    }

    return `${prefix}${String(nextSeq).padStart(6, '0')}`;
  }
}
