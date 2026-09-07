import { DataSource } from 'typeorm';

/**
 * Limpieza en orden de dependencias FK de todas las filas de un tenant.
 * Segura para llamar en afterAll y de forma defensiva en beforeAll
 * (datos huérfanos de corridas previas que fallaron a mitad del seed).
 *
 * Nota: `tenencias` no tiene tenant_id; se alcanza vía residentes.
 */
export async function limpiarTenant(
  dataSource: DataSource,
  tenantId: string,
): Promise<void> {
  await dataSource.query(
    `DELETE FROM pago_cobros WHERE pago_id IN (SELECT id FROM pagos WHERE tenant_id = $1)`,
    [tenantId],
  );
  await dataSource.query(`DELETE FROM tickets WHERE tenant_id = $1`, [
    tenantId,
  ]);
  await dataSource.query(`DELETE FROM pagos WHERE tenant_id = $1`, [tenantId]);
  await dataSource.query(`DELETE FROM cobros WHERE tenant_id = $1`, [tenantId]);
  await dataSource.query(`DELETE FROM periodos_cobro WHERE tenant_id = $1`, [
    tenantId,
  ]);
  await dataSource.query(`DELETE FROM planes_de_cobro WHERE tenant_id = $1`, [
    tenantId,
  ]);
  await dataSource.query(`DELETE FROM tarifas WHERE tenant_id = $1`, [
    tenantId,
  ]);
  await dataSource.query(
    `DELETE FROM montos_predefinidos WHERE tenant_id = $1`,
    [tenantId],
  );
  await dataSource.query(`DELETE FROM solicitudes WHERE tenant_id = $1`, [
    tenantId,
  ]);
  await dataSource.query(`DELETE FROM actividad WHERE tenant_id = $1`, [
    tenantId,
  ]);
  await dataSource.query(
    `DELETE FROM asignaciones_etapa WHERE tenant_id = $1`,
    [tenantId],
  );
  await dataSource.query(`DELETE FROM notificaciones WHERE tenant_id = $1`, [
    tenantId,
  ]);
  await dataSource.query(`DELETE FROM usuarios WHERE tenant_id = $1`, [
    tenantId,
  ]);
  await dataSource.query(
    `DELETE FROM tenencias WHERE residente_id IN (SELECT id FROM residentes WHERE tenant_id = $1)`,
    [tenantId],
  );
  await dataSource.query(`DELETE FROM residentes WHERE tenant_id = $1`, [
    tenantId,
  ]);
  await dataSource.query(
    `DELETE FROM casas WHERE manzana_id IN (SELECT id FROM manzanas WHERE etapa_id IN (SELECT id FROM etapas WHERE proyecto_id IN (SELECT id FROM proyectos WHERE tenant_id = $1)))`,
    [tenantId],
  );
  await dataSource.query(
    `DELETE FROM manzanas WHERE etapa_id IN (SELECT id FROM etapas WHERE proyecto_id IN (SELECT id FROM proyectos WHERE tenant_id = $1))`,
    [tenantId],
  );
  await dataSource.query(
    `DELETE FROM etapas WHERE proyecto_id IN (SELECT id FROM proyectos WHERE tenant_id = $1)`,
    [tenantId],
  );
  await dataSource.query(`DELETE FROM proyectos WHERE tenant_id = $1`, [
    tenantId,
  ]);
}

/**
 * Elimina usuarios huérfanos por email (de corridas previas cuyo afterAll
 * falló antes de limpiar) junto con TODO su tenant asociado, y devuelve
 * los tenants purgados.
 */
export async function purgarEmails(
  dataSource: DataSource,
  emails: string[],
): Promise<void> {
  if (emails.length === 0) return;

  const rows: { tenant_id: string }[] = await dataSource.query(
    `SELECT DISTINCT tenant_id FROM usuarios WHERE email = ANY($1)`,
    [emails],
  );

  for (const row of rows) {
    if (row?.tenant_id) {
      await limpiarTenant(dataSource, row.tenant_id);
    }
  }

  // Por si quedara algún usuario suelto sin tenant eliminable
  await dataSource.query(`DELETE FROM usuarios WHERE email = ANY($1)`, [
    emails,
  ]);
}
