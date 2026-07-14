-- ═══════════════════════════════════════════════════════════════
-- FIX: Corregir María a SEMANAL, recrear cuotas/pagos faltantes
-- ═══════════════════════════════════════════════════════════════

DO $$
DECLARE
  v_tenant_id UUID := '00000000-0000-0000-0000-000000000001';
  v_juan_id UUID;
  v_maria_id UUID;
  v_carlos_id UUID;
  v_cobrador_id UUID;
  v_conjunto_id UUID;
  v_monto_quincenal INT := 2000000;
  v_monto_semanal INT := 1000000;
  v_monto_mensual INT := 4000000;
  v_now TIMESTAMPTZ := NOW();
BEGIN
  SELECT id INTO v_juan_id FROM propietarios WHERE email = 'juan@email.com';
  SELECT id INTO v_maria_id FROM propietarios WHERE email = 'maria@email.com';
  SELECT id INTO v_carlos_id FROM propietarios WHERE email = 'carlos@email.com';
  SELECT id INTO v_cobrador_id FROM usuarios WHERE email = 'cobrador@civica.com';
  SELECT id INTO v_conjunto_id FROM conjuntos WHERE tenant_id = v_tenant_id LIMIT 1;

  -- FIX 1: María debe ser SEMANAL
  UPDATE propietarios SET modalidad_pago = 'SEMANAL', updated_at = v_now WHERE id = v_maria_id;
  UPDATE cuentas_cartera SET frecuencia = 'SEMANAL', updated_at = v_now WHERE propietario_id = v_maria_id;
  RAISE NOTICE 'María corregida a SEMANAL';

  -- FIX 2: Eliminar cuotas/pagos incorrectos de Juan y María (los que sobraron de datos viejos)
  DELETE FROM pagos WHERE propietario_id IN (v_juan_id, v_maria_id);
  DELETE FROM cuotas WHERE propietario_id IN (v_juan_id, v_maria_id);
  RAISE NOTICE 'Cuotas/pagos viejos de Juan y María eliminados';

  -- FIX 3: Recrear CuentaCartera para María si falta
  IF NOT EXISTS (SELECT 1 FROM cuentas_cartera WHERE propietario_id = v_maria_id) THEN
    INSERT INTO cuentas_cartera (id, propietario_id, tenant_id, conjunto_id, frecuencia, fecha_activacion, activa, created_at, updated_at)
    VALUES (gen_random_uuid(), v_maria_id, v_tenant_id, v_conjunto_id, 'SEMANAL', '2026-01-01', true, v_now, v_now);
    RAISE NOTICE 'CuentaCartera creada para María';
  END IF;

  -- ════════════════════════════════════════════════════════════
  -- JUAN PÉREZ — QUINCENAL — JUNIO 2026
  -- ════════════════════════════════════════════════════════════
  -- 1ra quincena: 2026-06-01 → 2026-06-16, vence 2026-06-13
  -- 2da quincena: 2026-06-16 → 2026-07-01, vence 2026-06-27

  INSERT INTO cuotas (id, propietario_id, tenant_id, tarifa_id, concepto, monto, monto_pagado, periodo_inicio, periodo_fin, fecha_vencimiento, estado, notificacion_enviada, created_at, updated_at)
  VALUES
    (gen_random_uuid(), v_juan_id, v_tenant_id,
     (SELECT id FROM tarifas WHERE frecuencia = 'QUINCENAL' AND activa = true LIMIT 1),
     'Cuota de Vigilancia - 1ra Quincena Junio 2026',
     v_monto_quincenal, v_monto_quincenal,
     '2026-06-01', '2026-06-16', '2026-06-13',
     'PAGADA', false, v_now, v_now),
    (gen_random_uuid(), v_juan_id, v_tenant_id,
     (SELECT id FROM tarifas WHERE frecuencia = 'QUINCENAL' AND activa = true LIMIT 1),
     'Cuota de Vigilancia - 2da Quincena Junio 2026',
     v_monto_quincenal, v_monto_quincenal,
     '2026-06-16', '2026-07-01', '2026-06-27',
     'PAGADA', false, v_now, v_now);

  -- Pagos Juan junio
  INSERT INTO pagos (id, client_payment_id, tenant_id, cuota_id, monto, fecha_pago, cobrador_id, propietario_id, sync_status, created_at, updated_at)
  SELECT gen_random_uuid(), 'PAY-JUAN-JUN-Q1', v_tenant_id,
    (SELECT id FROM cuotas WHERE propietario_id = v_juan_id AND fecha_vencimiento = '2026-06-13' LIMIT 1),
    v_monto_quincenal, '2026-06-13', v_cobrador_id, v_juan_id, 'SYNC_OK', v_now, v_now;

  INSERT INTO pagos (id, client_payment_id, tenant_id, cuota_id, monto, fecha_pago, cobrador_id, propietario_id, sync_status, created_at, updated_at)
  SELECT gen_random_uuid(), 'PAY-JUAN-JUN-Q2', v_tenant_id,
    (SELECT id FROM cuotas WHERE propietario_id = v_juan_id AND fecha_vencimiento = '2026-06-27' LIMIT 1),
    v_monto_quincenal, '2026-06-27', v_cobrador_id, v_juan_id, 'SYNC_OK', v_now, v_now;

  RAISE NOTICE 'Juan junio: 2 cuotas + 2 pagos QUINCENAL ✅';

  -- JUAN — JULIO 2026 (pendientes)
  INSERT INTO cuotas (id, propietario_id, tenant_id, tarifa_id, concepto, monto, monto_pagado, periodo_inicio, periodo_fin, fecha_vencimiento, estado, notificacion_enviada, created_at, updated_at)
  VALUES
    (gen_random_uuid(), v_juan_id, v_tenant_id,
     (SELECT id FROM tarifas WHERE frecuencia = 'QUINCENAL' AND activa = true LIMIT 1),
     'Cuota de Vigilancia - 1ra Quincena Julio 2026',
     v_monto_quincenal, 0,
     '2026-07-01', '2026-07-16', '2026-07-11',
     'PENDIENTE', false, v_now, v_now),
    (gen_random_uuid(), v_juan_id, v_tenant_id,
     (SELECT id FROM tarifas WHERE frecuencia = 'QUINCENAL' AND activa = true LIMIT 1),
     'Cuota de Vigilancia - 2da Quincena Julio 2026',
     v_monto_quincenal, 0,
     '2026-07-16', '2026-08-01', '2026-07-25',
     'PENDIENTE', false, v_now, v_now);

  RAISE NOTICE 'Juan julio: 2 cuotas QUINCENAL pendientes ✅';

  -- ════════════════════════════════════════════════════════════
  -- MARÍA GARCÍA — SEMANAL — JUNIO 2026
  -- ════════════════════════════════════════════════════════════
  -- Sábados junio: 6, 13, 20, 27

  INSERT INTO cuotas (id, propietario_id, tenant_id, tarifa_id, concepto, monto, monto_pagado, periodo_inicio, periodo_fin, fecha_vencimiento, estado, notificacion_enviada, created_at, updated_at)
  VALUES
    (gen_random_uuid(), v_maria_id, v_tenant_id,
     (SELECT id FROM tarifas WHERE frecuencia = 'SEMANAL' AND activa = true LIMIT 1),
     'Cuota de Vigilancia - Semana 1 Junio 2026',
     v_monto_semanal, v_monto_semanal,
     '2026-06-01', '2026-06-08', '2026-06-06',
     'PAGADA', false, v_now, v_now),
    (gen_random_uuid(), v_maria_id, v_tenant_id,
     (SELECT id FROM tarifas WHERE frecuencia = 'SEMANAL' AND activa = true LIMIT 1),
     'Cuota de Vigilancia - Semana 2 Junio 2026',
     v_monto_semanal, v_monto_semanal,
     '2026-06-08', '2026-06-15', '2026-06-13',
     'PAGADA', false, v_now, v_now),
    (gen_random_uuid(), v_maria_id, v_tenant_id,
     (SELECT id FROM tarifas WHERE frecuencia = 'SEMANAL' AND activa = true LIMIT 1),
     'Cuota de Vigilancia - Semana 3 Junio 2026',
     v_monto_semanal, v_monto_semanal,
     '2026-06-15', '2026-06-22', '2026-06-20',
     'PAGADA', false, v_now, v_now),
    (gen_random_uuid(), v_maria_id, v_tenant_id,
     (SELECT id FROM tarifas WHERE frecuencia = 'SEMANAL' AND activa = true LIMIT 1),
     'Cuota de Vigilancia - Semana 4 Junio 2026',
     v_monto_semanal, v_monto_semanal,
     '2026-06-22', '2026-06-29', '2026-06-27',
     'PAGADA', false, v_now, v_now);

  -- Pagos María junio
  INSERT INTO pagos (id, client_payment_id, tenant_id, cuota_id, monto, fecha_pago, cobrador_id, propietario_id, sync_status, created_at, updated_at)
  SELECT gen_random_uuid(), 'PAY-MARIA-JUN-S1', v_tenant_id,
    (SELECT id FROM cuotas WHERE propietario_id = v_maria_id AND fecha_vencimiento = '2026-06-06' LIMIT 1),
    v_monto_semanal, '2026-06-06', v_cobrador_id, v_maria_id, 'SYNC_OK', v_now, v_now;

  INSERT INTO pagos (id, client_payment_id, tenant_id, cuota_id, monto, fecha_pago, cobrador_id, propietario_id, sync_status, created_at, updated_at)
  SELECT gen_random_uuid(), 'PAY-MARIA-JUN-S2', v_tenant_id,
    (SELECT id FROM cuotas WHERE propietario_id = v_maria_id AND fecha_vencimiento = '2026-06-13' LIMIT 1),
    v_monto_semanal, '2026-06-13', v_cobrador_id, v_maria_id, 'SYNC_OK', v_now, v_now;

  INSERT INTO pagos (id, client_payment_id, tenant_id, cuota_id, monto, fecha_pago, cobrador_id, propietario_id, sync_status, created_at, updated_at)
  SELECT gen_random_uuid(), 'PAY-MARIA-JUN-S3', v_tenant_id,
    (SELECT id FROM cuotas WHERE propietario_id = v_maria_id AND fecha_vencimiento = '2026-06-20' LIMIT 1),
    v_monto_semanal, '2026-06-20', v_cobrador_id, v_maria_id, 'SYNC_OK', v_now, v_now;

  INSERT INTO pagos (id, client_payment_id, tenant_id, cuota_id, monto, fecha_pago, cobrador_id, propietario_id, sync_status, created_at, updated_at)
  SELECT gen_random_uuid(), 'PAY-MARIA-JUN-S4', v_tenant_id,
    (SELECT id FROM cuotas WHERE propietario_id = v_maria_id AND fecha_vencimiento = '2026-06-27' LIMIT 1),
    v_monto_semanal, '2026-06-27', v_cobrador_id, v_maria_id, 'SYNC_OK', v_now, v_now;

  RAISE NOTICE 'María junio: 4 cuotas + 4 pagos SEMANAL ✅';

  -- MARÍA — JULIO 2026 (pendientes)
  INSERT INTO cuotas (id, propietario_id, tenant_id, tarifa_id, concepto, monto, monto_pagado, periodo_inicio, periodo_fin, fecha_vencimiento, estado, notificacion_enviada, created_at, updated_at)
  VALUES
    (gen_random_uuid(), v_maria_id, v_tenant_id,
     (SELECT id FROM tarifas WHERE frecuencia = 'SEMANAL' AND activa = true LIMIT 1),
     'Cuota de Vigilancia - Semana 1 Julio 2026',
     v_monto_semanal, 0, '2026-07-01', '2026-07-08', '2026-07-04',
     'PENDIENTE', false, v_now, v_now),
    (gen_random_uuid(), v_maria_id, v_tenant_id,
     (SELECT id FROM tarifas WHERE frecuencia = 'SEMANAL' AND activa = true LIMIT 1),
     'Cuota de Vigilancia - Semana 2 Julio 2026',
     v_monto_semanal, 0, '2026-07-08', '2026-07-15', '2026-07-11',
     'PENDIENTE', false, v_now, v_now),
    (gen_random_uuid(), v_maria_id, v_tenant_id,
     (SELECT id FROM tarifas WHERE frecuencia = 'SEMANAL' AND activa = true LIMIT 1),
     'Cuota de Vigilancia - Semana 3 Julio 2026',
     v_monto_semanal, 0, '2026-07-15', '2026-07-22', '2026-07-18',
     'PENDIENTE', false, v_now, v_now),
    (gen_random_uuid(), v_maria_id, v_tenant_id,
     (SELECT id FROM tarifas WHERE frecuencia = 'SEMANAL' AND activa = true LIMIT 1),
     'Cuota de Vigilancia - Semana 4 Julio 2026',
     v_monto_semanal, 0, '2026-07-22', '2026-07-29', '2026-07-25',
     'PENDIENTE', false, v_now, v_now);

  RAISE NOTICE 'María julio: 4 cuotas SEMANAL pendientes ✅';

  -- FIX 4: Limpiar tarifas duplicadas — dejar solo 1 por frecuencia
  DELETE FROM tarifas WHERE id NOT IN (
    SELECT DISTINCT ON (frecuencia) id FROM tarifas WHERE tenant_id = v_tenant_id ORDER BY frecuencia, created_at ASC
  ) AND tenant_id = v_tenant_id;
  RAISE NOTICE 'Tarifas duplicadas limpiadas ✅';

  RAISE NOTICE '═══════════════════════════════════════════════════════════';
  RAISE NOTICE 'TODOS LOS FIXES APLICADOS';
  RAISE NOTICE '═══════════════════════════════════════════════════════════';

END $$;
