-- Migración DOWN: Reversión del constraint uq_periodos_plan_mes_anio
-- Ciclo 5: Calidad Operativa y Migraciones Reversibles

DROP INDEX IF EXISTS uq_periodos_plan_mes_anio;
