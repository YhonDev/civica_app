import { Repository, SelectQueryBuilder, ObjectLiteral } from 'typeorm';

/**
 * Base class for repositories that require mandatory tenant isolation.
 * Provides helper methods to standardize filtering by tenantId.
 */
export abstract class BaseTenantRepository<T extends ObjectLiteral> {
  constructor(protected readonly repo: Repository<T>) {}

  /**
   * Standardized find by tenant.
   * Merges provided where options with the mandatory tenantId.
   */
  protected async findByTenant(
    tenantId: string,
    options: any = {},
  ): Promise<T[]> {
    return this.repo.find({
      ...options,
      where: { ...options.where, tenantId },
    });
  }

  /**
   * Standardized count by tenant.
   */
  protected async countByTenant(
    tenantId: string,
    options: any = {},
  ): Promise<number> {
    return this.repo.count({
      where: { ...options, tenantId },
    });
  }

  /**
   * Applies the mandatory tenant filter to a QueryBuilder.
   * Should be called as the first filter in the chain to use .where().
   */
  protected applyTenantFilter(
    qb: SelectQueryBuilder<T>,
    tenantId: string,
    alias: string,
  ): SelectQueryBuilder<T> {
    return qb.where(`${alias}.tenantId = :tenantId`, { tenantId });
  }

  /**
   * Generic save method to avoid repetition.
   */
  async save(entity: T): Promise<T> {
    return this.repo.save(entity);
  }

  /**
   * Generic delete method to avoid repetition.
   */
  async delete(id: any): Promise<void> {
    await this.repo.delete(id);
  }
}
