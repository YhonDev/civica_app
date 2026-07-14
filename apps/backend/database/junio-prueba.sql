-- ═══════════════════════════════════════════════════════════════
-- junio-prueba.sql — Datos de prueba para Junio 2026
-- Solo para entornos de desarrollo/prueba.
-- Se puede eliminar en cualquier momento.
--
-- Inserta cobros + pagos del mes de Junio 2026 para los 3
-- residentes demo, reflejando pagos completados (estado PAGADA).
-- Ejecutar DESPUÉS de seed-cloud.sql.
--
-- Modalidades:
--   Juan Pérez   → QUINCENAL (2 cobros de $20,000)
--   María García → SEMANAL   (4 cobros de $10,000)
--   Carlos López → MENSUAL   (1 cobro  de $40,000)
-- ═══════════════════════════════════════════════════════════════

DO $$
DECLARE
  v_tenant_id UUID := '00000000-0000-0000-0000-000000000001';
  v_cobrador_id UUID := 'f6000000-0000-0000-0000-000000000002';

  -- Tarifas (IDs fijos del seed-cloud)
  v_tarifa_quincenal UUID := 'e5000000-0000-0000-0000-000000000001';
  v_tarifa_semanal   UUID := 'e5000000-0000-0000-0000-000000000002';
  v_tarifa_mensual   UUID := 'e5000000-0000-0000-0000-000000000003';

  -- Montos en centavos
  v_monto_quincenal INT := 2000000;  -- $20,000
  v_monto_semanal   INT := 1000000;  -- $10,000
  v_monto_mensual   INT := 4000000;  -- $40,000

  v_now TIMESTAMPTZ := NOW();

  -- Contadores
  v_cobros_creados INT := 0;
  v_pagos_creados  INT := 0;
  v_errores        INT := 0;
  v_row_count      INT := 0;
  v_pagos_este_res INT := 0;

  -- Variables por residente
  v_juan_id   UUID := 'b2000000-0000-0000-0000-000000000001';
  v_maria_id  UUID := 'b2000000-0000-0000-0000-000000000002';
  v_carlos_id UUID := 'b2000000-0000-0000-0000-000000000003';

BEGIN
  -- ═══════════════════════════════════════════════════════════════
  -- Validar que los residentes existen
  -- ═══════════════════════════════════════════════════════════════
  IF NOT EXISTS (SELECT 1 FROM residentes WHERE id = v_juan_id) THEN
    RAISE WARNING 'Juan Pérez (ID %) no existe. Ejecuta seed-cloud.sql primero.', v_juan_id;
    v_errores := v_errores + 1;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM residentes WHERE id = v_maria_id) THEN
    RAISE WARNING 'María García (ID %) no existe. Ejecuta seed-cloud.sql primero.', v_maria_id;
    v_errores := v_errores + 1;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM residentes WHERE id = v_carlos_id) THEN
    RAISE WARNING 'Carlos López (ID %) no existe. Ejecuta seed-cloud.sql primero.', v_carlos_id;
    v_errores := v_errores + 1;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM usuarios WHERE id = v_cobrador_id) THEN
    RAISE WARNING 'Cobrador (ID %) no existe. Ejecuta seed-cloud.sql primero.', v_cobrador_id;
    v_errores := v_errores + 1;
  END IF;

  IF v_errores > 0 THEN
    RAISE EXCEPTION 'No se pueden insertar datos de prueba — faltan % registro(s) requerido(s).', v_errores;
  END IF;

  RAISE NOTICE 'Validación OK — todos los residentes y cobrador existen. Insertando datos...';
  RAISE NOTICE '';

  -- ═══════════════════════════════════════════════════════════════
  -- JUAN PÉREZ — QUINCENAL
  -- 1ra quincena: 01-jun → 15-jun, vence 13-jun (sábado)
  -- 2da quincena: 16-jun → 30-jun, vence 27-jun (sábado)
  -- ═══════════════════════════════════════════════════════════════
  RAISE NOTICE '── Juan Pérez (QUINCENAL) ──';

  v_pagos_este_res := 0;

  IF NOT EXISTS (SELECT 1 FROM cobros WHERE residente_id = v_juan_id AND periodo_inicio >= '2026-06-01' AND periodo_fin <= '2026-06-30') THEN

    -- 1ra quincena
    INSERT INTO cobros (id, residente_id, tenant_id, casa_id, tarifa_id, concepto, monto, monto_pagado, periodo_inicio, periodo_fin, fecha_vencimiento, estado, notificacion_enviada, created_at, updated_at)
    VALUES (gen_random_uuid(), v_juan_id, v_tenant_id,
            'a1000000-0000-0000-0000-000000000001', v_tarifa_quincenal,
            'Cuota de Vigilancia - 1ra Quincena Junio 2026',
            v_monto_quincenal, v_monto_quincenal,
            '2026-06-01', '2026-06-15', '2026-06-13',
            'PAGADA', false,
            '2026-06-01T10:00:00Z', v_now);
    v_cobros_creados := v_cobros_creados + 1;

    -- 2da quincena
    INSERT INTO cobros (id, residente_id, tenant_id, casa_id, tarifa_id, concepto, monto, monto_pagado, periodo_inicio, periodo_fin, fecha_vencimiento, estado, notificacion_enviada, created_at, updated_at)
    VALUES (gen_random_uuid(), v_juan_id, v_tenant_id,
            'a1000000-0000-0000-0000-000000000001', v_tarifa_quincenal,
            'Cuota de Vigilancia - 2da Quincena Junio 2026',
            v_monto_quincenal, v_monto_quincenal,
            '2026-06-16', '2026-06-30', '2026-06-27',
            'PAGADA', false,
            '2026-06-16T10:00:00Z', v_now);
    v_cobros_creados := v_cobros_creados + 1;

    -- Pagos de Juan (uno por cada cobro)
    INSERT INTO pagos (id, client_payment_id, tenant_id, cobro_id, monto, fecha_pago, cobrador_id, residente_id, fecha_sync, sync_status, created_at, updated_at)
    SELECT gen_random_uuid(), 'PAY-JUNIO-JUAN-Q1-' || gen_random_uuid()::text, v_tenant_id, c.id, v_monto_quincenal, '2026-06-13', v_cobrador_id, v_juan_id, v_now, 'SYNC_OK', v_now, v_now
    FROM cobros c
    WHERE c.residente_id = v_juan_id AND c.fecha_vencimiento = '2026-06-13' AND c.estado = 'PAGADA'
    AND NOT EXISTS (SELECT 1 FROM pagos p WHERE p.cobro_id = c.id);
    GET DIAGNOSTICS v_row_count = ROW_COUNT;
    v_pagos_creados := v_pagos_creados + v_row_count;
    v_pagos_este_res := v_pagos_este_res + v_row_count;

    INSERT INTO pagos (id, client_payment_id, tenant_id, cobro_id, monto, fecha_pago, cobrador_id, residente_id, fecha_sync, sync_status, created_at, updated_at)
    SELECT gen_random_uuid(), 'PAY-JUNIO-JUAN-Q2-' || gen_random_uuid()::text, v_tenant_id, c.id, v_monto_quincenal, '2026-06-27', v_cobrador_id, v_juan_id, v_now, 'SYNC_OK', v_now, v_now
    FROM cobros c
    WHERE c.residente_id = v_juan_id AND c.fecha_vencimiento = '2026-06-27' AND c.estado = 'PAGADA'
    AND NOT EXISTS (SELECT 1 FROM pagos p WHERE p.cobro_id = c.id);
    GET DIAGNOSTICS v_row_count = ROW_COUNT;
    v_pagos_creados := v_pagos_creados + v_row_count;
    v_pagos_este_res := v_pagos_este_res + v_row_count;

    RAISE NOTICE '  Cobros: 2 | Pagos: % | Total: $40,000 ✅', v_pagos_este_res;
  ELSE
    RAISE NOTICE '  Ya existen cobros de Junio 2026 — saltando (idempotente)';
  END IF;

  -- ═══════════════════════════════════════════════════════════════
  -- MARÍA GARCÍA — SEMANAL
  -- Semana 1: 01-jun → 07-jun, vence 06-jun (sábado)
  -- Semana 2: 08-jun → 14-jun, vence 13-jun (sábado)
  -- Semana 3: 15-jun → 21-jun, vence 20-jun (sábado)
  -- Semana 4: 22-jun → 28-jun, vence 27-jun (sábado)
  -- ═══════════════════════════════════════════════════════════════
  RAISE NOTICE '── María García (SEMANAL) ──';

  v_pagos_este_res := 0;

  IF NOT EXISTS (SELECT 1 FROM cobros WHERE residente_id = v_maria_id AND periodo_inicio >= '2026-06-01' AND periodo_fin <= '2026-06-30') THEN

    INSERT INTO cobros (id, residente_id, tenant_id, casa_id, tarifa_id, concepto, monto, monto_pagado, periodo_inicio, periodo_fin, fecha_vencimiento, estado, notificacion_enviada, created_at, updated_at)
    VALUES
      (gen_random_uuid(), v_maria_id, v_tenant_id, 'a1000000-0000-0000-0000-000000000002', v_tarifa_semanal,
       'Cuota de Vigilancia - Semana 1 Junio 2026',     v_monto_semanal, v_monto_semanal, '2026-06-01', '2026-06-07', '2026-06-06', 'PAGADA', false, '2026-06-01T10:00:00Z', v_now),
      (gen_random_uuid(), v_maria_id, v_tenant_id, 'a1000000-0000-0000-0000-000000000002', v_tarifa_semanal,
       'Cuota de Vigilancia - Semana 2 Junio 2026',     v_monto_semanal, v_monto_semanal, '2026-06-08', '2026-06-14', '2026-06-13', 'PAGADA', false, '2026-06-08T10:00:00Z', v_now),
      (gen_random_uuid(), v_maria_id, v_tenant_id, 'a1000000-0000-0000-0000-000000000002', v_tarifa_semanal,
       'Cuota de Vigilancia - Semana 3 Junio 2026',     v_monto_semanal, v_monto_semanal, '2026-06-15', '2026-06-21', '2026-06-20', 'PAGADA', false, '2026-06-15T10:00:00Z', v_now),
      (gen_random_uuid(), v_maria_id, v_tenant_id, 'a1000000-0000-0000-0000-000000000002', v_tarifa_semanal,
       'Cuota de Vigilancia - Semana 4 Junio 2026',     v_monto_semanal, v_monto_semanal, '2026-06-22', '2026-06-28', '2026-06-27', 'PAGADA', false, '2026-06-22T10:00:00Z', v_now);
    v_cobros_creados := v_cobros_creados + 4;

    -- Pagos de María (1 por semana, cada sábado)
    INSERT INTO pagos (id, client_payment_id, tenant_id, cobro_id, monto, fecha_pago, cobrador_id, residente_id, fecha_sync, sync_status, created_at, updated_at)
    SELECT gen_random_uuid(), 'PAY-JUNIO-MARIA-S1-' || gen_random_uuid()::text, v_tenant_id, c.id, v_monto_semanal, '2026-06-06', v_cobrador_id, v_maria_id, v_now, 'SYNC_OK', v_now, v_now
    FROM cobros c WHERE c.residente_id = v_maria_id AND c.fecha_vencimiento = '2026-06-06' AND c.estado = 'PAGADA'
    AND NOT EXISTS (SELECT 1 FROM pagos p WHERE p.cobro_id = c.id);
    GET DIAGNOSTICS v_row_count = ROW_COUNT;
    v_pagos_creados := v_pagos_creados + v_row_count;
    v_pagos_este_res := v_pagos_este_res + v_row_count;

    INSERT INTO pagos (id, client_payment_id, tenant_id, cobro_id, monto, fecha_pago, cobrador_id, residente_id, fecha_sync, sync_status, created_at, updated_at)
    SELECT gen_random_uuid(), 'PAY-JUNIO-MARIA-S2-' || gen_random_uuid()::text, v_tenant_id, c.id, v_monto_semanal, '2026-06-13', v_cobrador_id, v_maria_id, v_now, 'SYNC_OK', v_now, v_now
    FROM cobros c WHERE c.residente_id = v_maria_id AND c.fecha_vencimiento = '2026-06-13' AND c.estado = 'PAGADA'
    AND NOT EXISTS (SELECT 1 FROM pagos p WHERE p.cobro_id = c.id);
    GET DIAGNOSTICS v_row_count = ROW_COUNT;
    v_pagos_creados := v_pagos_creados + v_row_count;
    v_pagos_este_res := v_pagos_este_res + v_row_count;

    INSERT INTO pagos (id, client_payment_id, tenant_id, cobro_id, monto, fecha_pago, cobrador_id, residente_id, fecha_sync, sync_status, created_at, updated_at)
    SELECT gen_random_uuid(), 'PAY-JUNIO-MARIA-S3-' || gen_random_uuid()::text, v_tenant_id, c.id, v_monto_semanal, '2026-06-20', v_cobrador_id, v_maria_id, v_now, 'SYNC_OK', v_now, v_now
    FROM cobros c WHERE c.residente_id = v_maria_id AND c.fecha_vencimiento = '2026-06-20' AND c.estado = 'PAGADA'
    AND NOT EXISTS (SELECT 1 FROM pagos p WHERE p.cobro_id = c.id);
    GET DIAGNOSTICS v_row_count = ROW_COUNT;
    v_pagos_creados := v_pagos_creados + v_row_count;
    v_pagos_este_res := v_pagos_este_res + v_row_count;

    INSERT INTO pagos (id, client_payment_id, tenant_id, cobro_id, monto, fecha_pago, cobrador_id, residente_id, fecha_sync, sync_status, created_at, updated_at)
    SELECT gen_random_uuid(), 'PAY-JUNIO-MARIA-S4-' || gen_random_uuid()::text, v_tenant_id, c.id, v_monto_semanal, '2026-06-27', v_cobrador_id, v_maria_id, v_now, 'SYNC_OK', v_now, v_now
    FROM cobros c WHERE c.residente_id = v_maria_id AND c.fecha_vencimiento = '2026-06-27' AND c.estado = 'PAGADA'
    AND NOT EXISTS (SELECT 1 FROM pagos p WHERE p.cobro_id = c.id);
    GET DIAGNOSTICS v_row_count = ROW_COUNT;
    v_pagos_creados := v_pagos_creados + v_row_count;
    v_pagos_este_res := v_pagos_este_res + v_row_count;

    RAISE NOTICE '  Cobros: 4 | Pagos: % | Total: $40,000 ✅', v_pagos_este_res;
  ELSE
    RAISE NOTICE '  Ya existen cobros de Junio 2026 — saltando (idempotente)';
  END IF;

  -- ═══════════════════════════════════════════════════════════════
  -- CARLOS LÓPEZ — MENSUAL
  -- Periodo: 01-jun → 30-jun, vence 27-jun (sábado)
  -- ═══════════════════════════════════════════════════════════════
  RAISE NOTICE '── Carlos López (MENSUAL) ──';

  v_pagos_este_res := 0;

  IF NOT EXISTS (SELECT 1 FROM cobros WHERE residente_id = v_carlos_id AND periodo_inicio >= '2026-06-01' AND periodo_fin <= '2026-06-30') THEN

    INSERT INTO cobros (id, residente_id, tenant_id, casa_id, tarifa_id, concepto, monto, monto_pagado, periodo_inicio, periodo_fin, fecha_vencimiento, estado, notificacion_enviada, created_at, updated_at)
    VALUES (gen_random_uuid(), v_carlos_id, v_tenant_id,
            'a1000000-0000-0000-0000-000000000003', v_tarifa_mensual,
            'Cuota de Vigilancia - Junio 2026',
            v_monto_mensual, v_monto_mensual,
            '2026-06-01', '2026-06-30', '2026-06-27',
            'PAGADA', false,
            '2026-06-01T10:00:00Z', v_now);
    v_cobros_creados := v_cobros_creados + 1;

    INSERT INTO pagos (id, client_payment_id, tenant_id, cobro_id, monto, fecha_pago, cobrador_id, residente_id, fecha_sync, sync_status, created_at, updated_at)
    SELECT gen_random_uuid(), 'PAY-JUNIO-CARLOS-M1-' || gen_random_uuid()::text, v_tenant_id, c.id, v_monto_mensual, '2026-06-27', v_cobrador_id, v_carlos_id, v_now, 'SYNC_OK', v_now, v_now
    FROM cobros c
    WHERE c.residente_id = v_carlos_id AND c.fecha_vencimiento = '2026-06-27' AND c.estado = 'PAGADA'
    AND NOT EXISTS (SELECT 1 FROM pagos p WHERE p.cobro_id = c.id);
    GET DIAGNOSTICS v_row_count = ROW_COUNT;
    v_pagos_creados := v_pagos_creados + v_row_count;
    v_pagos_este_res := v_pagos_este_res + v_row_count;

    RAISE NOTICE '  Cobros: 1 | Pagos: % | Total: $40,000 ✅', v_pagos_este_res;
  ELSE
    RAISE NOTICE '  Ya existen cobros de Junio 2026 — saltando (idempotente)';
  END IF;

  -- ═══════════════════════════════════════════════════════════════
  -- RESUMEN
  -- ═══════════════════════════════════════════════════════════════
  RAISE NOTICE '';
  RAISE NOTICE '═══════════════════════════════════════════════════════════';
  RAISE NOTICE '  DATOS DE JUNIO 2026 INSERTADOS EXITOSAMENTE';
  RAISE NOTICE '═══════════════════════════════════════════════════════════';
  RAISE NOTICE '  Total cobros creados: %', v_cobros_creados;
  RAISE NOTICE '  Total pagos  creados: %', v_pagos_creados;
  RAISE NOTICE '';
  RAISE NOTICE '  ── Resumen financiero ──';
  RAISE NOTICE '  Juan Pérez:   2 cobros × $20.000 = $40.000  (QUINCENAL)';
  RAISE NOTICE '  María García: 4 cobros × $10.000 = $40.000  (SEMANAL)';
  RAISE NOTICE '  Carlos López: 1 cobro  × $40.000 = $40.000  (MENSUAL)';
  RAISE NOTICE '  ──────────────────────────────';
  RAISE NOTICE '  TOTAL RECAUDO JUNIO: $120.000 ✅';
  RAISE NOTICE '═══════════════════════════════════════════════════════════';

END $$;
