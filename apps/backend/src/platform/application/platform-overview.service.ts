import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
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
}
