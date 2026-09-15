import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';

export interface PlatformAuditEvent {
  actorId: string;
  action: string;
  resource: string;
  resourceId?: string;
  result?: 'SUCCESS' | 'FAILURE';
  requestId?: string;
  ipAddress?: string;
  metadata?: Record<string, unknown>;
}

export interface PlatformAuditQuery {
  page: number;
  limit: number;
  action?: string;
  resource?: string;
}

@Injectable()
export class PlatformAuditService {
  constructor(private readonly dataSource: DataSource) {}

  async record(event: PlatformAuditEvent): Promise<void> {
    await this.dataSource.query(
      `INSERT INTO platform_audit_events
        (actor_id, action, resource, resource_id, result, request_id, ip_address, metadata)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8::jsonb)`,
      [
        event.actorId,
        event.action,
        event.resource,
        event.resourceId ?? null,
        event.result ?? 'SUCCESS',
        event.requestId ?? null,
        event.ipAddress ?? null,
        JSON.stringify(event.metadata ?? {}),
      ],
    );
  }

  async list(query: PlatformAuditQuery) {
    const offset = (query.page - 1) * query.limit;
    const filters: string[] = [];
    const countParams: string[] = [];
    const dataParams: Array<string | number> = [];

    if (query.action) {
      countParams.push(query.action);
      dataParams.push(query.action);
      filters.push(`action = $${countParams.length}`);
    }
    if (query.resource) {
      countParams.push(query.resource);
      dataParams.push(query.resource);
      filters.push(`resource = $${countParams.length}`);
    }

    const where = filters.length > 0 ? `WHERE ${filters.join(' AND ')}` : '';
    const limitPosition = dataParams.length + 1;
    const offsetPosition = dataParams.length + 2;
    dataParams.push(query.limit, offset);

    const [countRows, rows] = await Promise.all([
      this.dataSource.query(
        `SELECT COUNT(*)::int AS total
         FROM platform_audit_events
         ${where}`,
        countParams,
      ),
      this.dataSource.query(
        `SELECT
           id,
           actor_id AS "actorId",
           action,
           resource,
           resource_id AS "resourceId",
           result,
           request_id AS "requestId",
           ip_address AS "ipAddress",
           metadata,
           created_at AS "createdAt"
         FROM platform_audit_events
         ${where}
         ORDER BY created_at DESC
         LIMIT $${limitPosition} OFFSET $${offsetPosition}`,
        dataParams,
      ),
    ]);

    return {
      data: rows,
      total: Number(countRows[0]?.total ?? 0),
      page: query.page,
      limit: query.limit,
    };
  }
}
