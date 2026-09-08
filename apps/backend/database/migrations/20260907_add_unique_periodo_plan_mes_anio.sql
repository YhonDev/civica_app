-- Migración: idempotencia fuerte en generación de cobros
-- Evita que dos ejecuciones concurrentes de GenerarCobrosUseCase
-- creen PeriodoCobro duplicados para el mismo (plan, mes, año).
--
-- Ejecutar ANTES de desplegar la versión transaccional del use-case.
-- Si existen duplicados previos, la creación del índice fallará:
-- deduplicar primero con el script de abajo (conserva el más antiguo).

-- 1) Detectar duplicados existentes (solo diagnóstico, no borra nada):
--    SELECT plan_id, mes, anio, count(*)
--    FROM periodos_cobro
--    GROUP BY plan_id, mes, anio
--    HAVING count(*) > 1;

-- 2) Eliminar duplicados conservando el más antiguo de cada grupo:
--    DELETE FROM periodos_cobro a
--    USING periodos_cobro b
--    WHERE a.plan_id = b.plan_id
--      AND a.mes = b.mes
--      AND a.anio = b.anio
--      AND a.created_at > b.created_at;

-- 3) Crear el constraint:
CREATE UNIQUE INDEX IF NOT EXISTS uq_periodos_plan_mes_anio
  ON periodos_cobro (plan_id, mes, anio);
