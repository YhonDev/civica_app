import { Injectable, NotFoundException } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { randomUUID } from 'node:crypto';
import { TenantStatus } from '../domain/tenant-status.enum';

export interface PlatformTenantSummary {
  id: string;
  name: string;
  status: TenantStatus;
  createdAt: Date;
  updatedAt: Date;
  users: number;
  projects: number;
  residents: number;
  houses: number;
}

@Injectable()
export class PlatformOverviewService {
  constructor(private readonly dataSource: DataSource) {}

  async listTenants(
    page: number,
    limit: number,
    status?: TenantStatus,
  ): Promise<{
    data: PlatformTenantSummary[];
    total: number;
    page: number;
    limit: number;
  }> {
    const offset = (page - 1) * limit;
    const statusClause = status ? 'WHERE t.status = $1' : '';
    const countParams = status ? [status] : [];
    const dataParams = status ? [status, limit, offset] : [limit, offset];

    const [countRows, rows] = await Promise.all([
      this.dataSource.query(
        `SELECT COUNT(*)::int AS total FROM tenants t ${statusClause}`,
        countParams,
      ),
      this.dataSource.query(
        `WITH user_counts AS (
           SELECT tenant_id, COUNT(*)::int AS users
           FROM usuarios
           GROUP BY tenant_id
         ),
         project_counts AS (
           SELECT tenant_id, COUNT(*)::int AS projects
           FROM proyectos
           GROUP BY tenant_id
         ),
         resident_counts AS (
           SELECT tenant_id, COUNT(*)::int AS residents
           FROM residentes
           GROUP BY tenant_id
         ),
         house_counts AS (
           SELECT p.tenant_id, COUNT(c.id)::int AS houses
           FROM proyectos p
           JOIN etapas e ON e.proyecto_id = p.id
           JOIN manzanas m ON m.etapa_id = e.id
           JOIN casas c ON c.manzana_id = m.id
           GROUP BY p.tenant_id
         )
         SELECT
           t.id,
           t.name,
           t.status,
           t.created_at AS "createdAt",
           t.updated_at AS "updatedAt",
           COALESCE(uc.users, 0)::int AS users,
           COALESCE(pc.projects, 0)::int AS projects,
           COALESCE(rc.residents, 0)::int AS residents,
           COALESCE(hc.houses, 0)::int AS houses
         FROM tenants t
         LEFT JOIN user_counts uc ON uc.tenant_id = t.id
         LEFT JOIN project_counts pc ON pc.tenant_id = t.id
         LEFT JOIN resident_counts rc ON rc.tenant_id = t.id
         LEFT JOIN house_counts hc ON hc.tenant_id = t.id
         ${statusClause}
         ORDER BY t.created_at DESC
         LIMIT $${status ? 2 : 1} OFFSET $${status ? 3 : 2}`,
        dataParams,
      ),
    ]);

    return {
      data: rows as PlatformTenantSummary[],
      total: Number(countRows[0]?.total ?? 0),
      page,
      limit,
    };
  }

  async overview() {
    const [tenantRows, userRows, projectRows, residentRows] = await Promise.all(
      [
        this.dataSource.query(
          `SELECT status, COUNT(*)::int AS count
           FROM tenants
           GROUP BY status
           ORDER BY status`,
        ),
        this.dataSource.query(
          `SELECT COUNT(*)::int AS count FROM usuarios WHERE activo = true`,
        ),
        this.dataSource.query(`SELECT COUNT(*)::int AS count FROM proyectos`),
        this.dataSource.query(`SELECT COUNT(*)::int AS count FROM residentes`),
      ],
    );

    return {
      tenants: {
        total: tenantRows.reduce(
          (total: number, row: { count: number }) => total + Number(row.count),
          0,
        ),
        byStatus: tenantRows,
      },
      activeUsers: Number(userRows[0]?.count ?? 0),
      projects: Number(projectRows[0]?.count ?? 0),
      residents: Number(residentRows[0]?.count ?? 0),
    };
  }

  async createTenant(
    name: string,
    status: TenantStatus = TenantStatus.ACTIVE,
  ): Promise<PlatformTenantSummary> {
    const id = randomUUID();
    const rows = await this.dataSource.query(
      `INSERT INTO tenants (id, name, status, created_at, updated_at)
       VALUES ($1, $2, $3, now(), now())
       RETURNING id, name, status, created_at AS "createdAt", updated_at AS "updatedAt"`,
      [id, name, status],
    );
    const created = rows[0];
    return {
      ...created,
      users: 0,
      projects: 0,
      residents: 0,
      houses: 0,
    };
  }

  async getTenantDetail(tenantId: string) {
    const tenantRows = await this.dataSource.query(
      `SELECT id, name, status, created_at AS "createdAt", updated_at AS "updatedAt"
       FROM tenants WHERE id = $1`,
      [tenantId],
    );
    if (tenantRows.length === 0) {
      throw new NotFoundException(`Tenant con ID ${tenantId} no encontrado`);
    }
    const tenant = tenantRows[0];

    const [projects, admins, stats] = await Promise.all([
      this.dataSource.query(
        `SELECT p.id, p.nombre, p.created_at AS "createdAt",
                COUNT(DISTINCT e.id)::int AS etapas,
                COUNT(DISTINCT c.id)::int AS casas
         FROM proyectos p
         LEFT JOIN etapas e ON e.proyecto_id = p.id
         LEFT JOIN manzanas m ON m.etapa_id = e.id
         LEFT JOIN casas c ON c.manzana_id = m.id
         WHERE p.tenant_id = $1
         GROUP BY p.id, p.nombre, p.created_at
         ORDER BY p.created_at DESC`,
        [tenantId],
      ),
      this.dataSource.query(
        `SELECT id, email, nombre, activo, created_at AS "createdAt"
         FROM usuarios
         WHERE tenant_id = $1 AND rol = 'ADMIN'
         ORDER BY created_at DESC`,
        [tenantId],
      ),
      this.dataSource.query(
        `SELECT
           (SELECT COUNT(*)::int FROM usuarios WHERE tenant_id = $1) AS users,
           (SELECT COUNT(*)::int FROM residentes WHERE tenant_id = $1) AS residents,
           (SELECT COUNT(*)::int FROM proyectos WHERE tenant_id = $1) AS projects`,
        [tenantId],
      ),
    ]);

    return {
      tenant,
      projects,
      administrators: admins,
      summary: {
        users: stats[0]?.users ?? 0,
        residents: stats[0]?.residents ?? 0,
        projects: stats[0]?.projects ?? 0,
      },
    };
  }

  async updateTenantStatus(tenantId: string, status: TenantStatus) {
    const result = await this.dataSource.query(
      `UPDATE tenants
       SET status = $1, updated_at = now()
       WHERE id = $2
       RETURNING id, name, status, created_at AS "createdAt", updated_at AS "updatedAt"`,
      [status, tenantId],
    );
    const updatedRows = Array.isArray(result[0]) ? result[0] : result;
    if (!updatedRows || updatedRows.length === 0) {
      throw new NotFoundException(`Tenant con ID ${tenantId} no encontrado`);
    }
    return updatedRows[0];
  }
}

