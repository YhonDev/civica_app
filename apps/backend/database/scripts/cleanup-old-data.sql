-- ═══════════════════════════════════════════════════════════════
-- CLEANUP: Eliminar datos de prueba viejos, preservar seed nuevo
-- ═══════════════════════════════════════════════════════════════

DO $$
DECLARE
  v_tenant_id UUID := '00000000-0000-0000-0000-000000000001';
  v_juan_id UUID;
  v_maria_id UUID;
  v_carlos_id UUID;
BEGIN
  -- Identificar los IDs de nuestros propietarios nuevos
  SELECT id INTO v_juan_id FROM propietarios WHERE email = 'juan@email.com' AND nombre = 'Juan Pérez' LIMIT 1;
  SELECT id INTO v_maria_id FROM propietarios WHERE email = 'maria@email.com' AND nombre = 'María García' LIMIT 1;
  SELECT id INTO v_carlos_id FROM propietarios WHERE email = 'carlos@email.com' AND nombre = 'Carlos López' LIMIT 1;

  RAISE NOTICE 'IDs nuevos: Juan=%, María=%, Carlos=%', v_juan_id, v_maria_id, v_carlos_id;

  -- 1. Eliminar pagos de propietarios que NO son nuestros 3 nuevos
  DELETE FROM pagos WHERE propietario_id NOT IN (v_juan_id, v_maria_id, v_carlos_id);
  RAISE NOTICE 'Pagos de otros propietarios eliminados';

  -- 2. Eliminar cuotas de propietarios que NO son nuestros 3 nuevos
  DELETE FROM cuotas WHERE propietario_id NOT IN (v_juan_id, v_maria_id, v_carlos_id);
  RAISE NOTICE 'Cuotas de otros propietarios eliminadas';

  -- 3. Eliminar tenencias de propietarios que NO son nuestros 3 nuevos
  DELETE FROM tenencias WHERE propietario_id NOT IN (v_juan_id, v_maria_id, v_carlos_id);
  RAISE NOTICE 'Tenencias de otros propietarios eliminadas';

  -- 4. Eliminar cuentas cartera de propietarios que NO son nuestros 3 nuevos
  DELETE FROM cuentas_cartera WHERE propietario_id NOT IN (v_juan_id, v_maria_id, v_carlos_id);
  RAISE NOTICE 'Cuentas cartera de otros propietarios eliminadas';

  -- 5. Eliminar propietarios que NO son nuestros 3 nuevos
  DELETE FROM propietarios WHERE id NOT IN (v_juan_id, v_maria_id, v_carlos_id);
  RAISE NOTICE 'Otros propietarios eliminados';

  -- 6. Eliminar usuarios auth que NO son nuestros (admin, cobrador, 3 propietarios)
  DELETE FROM usuarios WHERE email NOT IN (
    'juan@email.com', 'maria@email.com', 'carlos@email.com',
    'cobrador@civica.com', 'admin@civica.com'
  );
  RAISE NOTICE 'Usuarios auth viejos eliminados';

  -- 7. Eliminar pagos duplicados de nuestros propietarios (montos incorrectos de datos viejos)
  -- keeping only the ones with correct amounts
  DELETE FROM pagos
  WHERE propietario_id IN (v_juan_id, v_maria_id, v_carlos_id)
  AND (
    (propietario_id = v_juan_id AND monto NOT IN (2000000))
    OR (propietario_id = v_maria_id AND monto NOT IN (1000000))
    OR (propietario_id = v_carlos_id AND monto NOT IN (4000000))
  );
  RAISE NOTICE 'Pagos con montos incorrectos eliminados';

  -- 8. Eliminar cuotas duplicadas con montos incorrectos
  DELETE FROM cuotas
  WHERE propietario_id IN (v_juan_id, v_maria_id, v_carlos_id)
  AND (
    (propietario_id = v_juan_id AND monto NOT IN (2000000))
    OR (propietario_id = v_maria_id AND monto NOT IN (1000000))
    OR (propietario_id = v_carlos_id AND monto NOT IN (4000000))
  );
  RAISE NOTICE 'Cuotas con montos incorrectos eliminadas';

  -- 9. Eliminar tenencias duplicadas (mantener solo 1 por propietario)
  DELETE FROM tenencias
  WHERE id NOT IN (
    SELECT DISTINCT ON (propietario_id) id
    FROM tenencias
    WHERE propietario_id IN (v_juan_id, v_maria_id, v_carlos_id)
    ORDER BY propietario_id, created_at ASC
  )
  AND propietario_id IN (v_juan_id, v_maria_id, v_carlos_id);
  RAISE NOTICE 'Tenencias duplicadas eliminadas';

  -- 10. Eliminar tarifas duplicadas o incorrectas
  -- Mantener solo las 3 tarifas correctas (una por frecuencia)
  DELETE FROM tarifas
  WHERE id NOT IN (
    SELECT DISTINCT ON (frecuencia) id
    FROM tarifas
    WHERE tenant_id = v_tenant_id
    ORDER BY frecuencia, created_at ASC
  )
  AND tenant_id = v_tenant_id;
  RAISE NOTICE 'Tarifas duplicadas eliminadas';

  -- 11. Eliminar montos predefinidos viejos
  DELETE FROM montos_predefinidos WHERE tenant_id = v_tenant_id;
  -- Re-crearrow ones correctas
  INSERT INTO montos_predefinidos (id, tenant_id, conjunto_id, monto, descripcion, activo, orden, created_at, updated_at)
  SELECT gen_random_uuid(), v_tenant_id, (SELECT id FROM conjuntos WHERE tenant_id = v_tenant_id LIMIT 1), m.monto, m.descripcion, true, m.orden, NOW(), NOW()
  FROM (VALUES
    (1000000, 'Pago semanal', 1),
    (2000000, 'Pago quincenal', 2),
    (4000000, 'Pago mensual', 3)
  ) AS m(monto, descripcion, orden);
  RAISE NOTICE 'Montos predefinidos recreados';

  RAISE NOTICE '═══════════════════════════════════════════════════════════';
  RAISE NOTICE 'LIMPIEZA COMPLETADA';
  RAISE NOTICE '═══════════════════════════════════════════════════════════';

END $$;
