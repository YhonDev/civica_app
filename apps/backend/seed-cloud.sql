-- ═══════════════════════════════════════════════════════════════
-- SEED: Base de datos cloud — Cívica Pago
-- Preserva autenticación existente. Solo inserta/upsert data de negocio.
-- Modalidades: QUINCENAL (Juan Pérez), SEMANAL (María García), MENSUAL (Carlos López)
-- ═══════════════════════════════════════════════════════════════

-- ── 0. Tenant fijo ──────────────────────────────────────────
DO $$
DECLARE
  v_tenant_id UUID := '00000000-0000-0000-0000-000000000001';
  v_conjunto_id UUID;
  v_etapa_id UUID;
  v_manzana_id UUID;

  -- Casas
  v_casa1_id UUID := gen_random_uuid();
  v_casa2_id UUID := gen_random_uuid();
  v_casa3_id UUID := gen_random_uuid();

  -- Propietarios
  v_juan_id UUID := gen_random_uuid();
  v_maria_id UUID := gen_random_uuid();
  v_carlos_id UUID := gen_random_uuid();

  -- Usuarios (auth)
  v_user_juan_id UUID;
  v_user_maria_id UUID;
  v_user_carlos_id UUID;
  v_user_cobrador_id UUID;
  v_user_admin_id UUID;

  -- Tenencias
  v_tenencia1_id UUID := gen_random_uuid();
  v_tenencia2_id UUID := gen_random_uuid();
  v_tenencia3_id UUID := gen_random_uuid();

  -- Cuentas cartera
  v_cuenta1_id UUID := gen_random_uuid();
  v_cuenta2_id UUID := gen_random_uuid();
  v_cuenta3_id UUID := gen_random_uuid();

  -- Tarifas (una por frecuencia)
  v_tarifa_quincenal_id UUID := gen_random_uuid();
  v_tarifa_semanal_id UUID := gen_random_uuid();
  v_tarifa_mensual_id UUID := gen_random_uuid();

  -- Monto mensual en centavos: $40,000 COP = 4,000,000 centavos
  v_monto_mensual INT := 4000000;
  -- Montos parciales
  v_monto_quincenal INT := 2000000;  -- $20,000
  v_monto_semanal INT := 1000000;    -- $10,000
  v_monto_mensual_cuota INT := 4000000; -- $40,000

  -- Cobrador
  v_cobrador_id UUID;

  -- Timestamps
  v_now TIMESTAMPTZ := NOW();
  v_created_junio TIMESTAMPTZ := '2026-06-01T10:00:00Z';
  v_created_julio TIMESTAMPTZ := '2026-07-01T10:00:00Z';
BEGIN

  -- ── 1. Conjunto, Etapa, Manzana ───────────────────────────
  INSERT INTO conjuntos (id, nombre, tenant_id, created_at, updated_at)
  VALUES (gen_random_uuid(), 'Conjunto Residencial Cívica', v_tenant_id, v_created_junio, v_now)
  ON CONFLICT (id) DO NOTHING
  RETURNING id INTO v_conjunto_id;

  -- Si ya existía, buscarlo
  IF v_conjunto_id IS NULL THEN
    SELECT id INTO v_conjunto_id FROM conjuntos WHERE tenant_id = v_tenant_id LIMIT 1;
  END IF;

  INSERT INTO etapas (id, nombre, conjunto_id, created_at)
  VALUES (gen_random_uuid(), 'Etapa 1', v_conjunto_id, v_created_junio)
  ON CONFLICT (id) DO NOTHING
  RETURNING id INTO v_etapa_id;

  IF v_etapa_id IS NULL THEN
    SELECT id INTO v_etapa_id FROM etapas WHERE conjunto_id = v_conjunto_id LIMIT 1;
  END IF;

  INSERT INTO manzanas (id, nombre, etapa_id, created_at)
  VALUES (gen_random_uuid(), 'Manzana A', v_etapa_id, v_created_junio)
  ON CONFLICT (id) DO NOTHING
  RETURNING id INTO v_manzana_id;

  IF v_manzana_id IS NULL THEN
    SELECT id INTO v_manzana_id FROM manzanas WHERE etapa_id = v_etapa_id LIMIT 1;
  END IF;

  RAISE NOTICE 'Conjunto: %, Etapa: %, Manzana: %', v_conjunto_id, v_etapa_id, v_manzana_id;

  -- ── 2. Casas (enfocado en la vivienda) ────────────────────
  INSERT INTO casas (id, direccion_interna, manzana_id, created_at)
  VALUES
    (v_casa1_id, 'Casa 101', v_manzana_id, v_created_junio),
    (v_casa2_id, 'Casa 102', v_manzana_id, v_created_junio),
    (v_casa3_id, 'Casa 103', v_manzana_id, v_created_junio)
  ON CONFLICT (id) DO NOTHING;

  RAISE NOTICE 'Casas creadas: 101, 102, 103';

  -- ── 3. Propietarios (con modalidad de pago) ───────────────
  -- Juan Pérez: QUINCENAL
  INSERT INTO propietarios (id, nombre, telefono, email, tenant_id, modalidad_pago, created_at, updated_at)
  VALUES (v_juan_id, 'Juan Pérez', '3001234567', 'juan@email.com', v_tenant_id, 'QUINCENAL', v_created_junio, v_now)
  ON CONFLICT (id) DO NOTHING;

  -- María García: SEMANAL
  INSERT INTO propietarios (id, nombre, telefono, email, tenant_id, modalidad_pago, created_at, updated_at)
  VALUES (v_maria_id, 'María García', '3009876543', 'maria@email.com', v_tenant_id, 'SEMANAL', v_created_junio, v_now)
  ON CONFLICT (id) DO NOTHING;

  -- Carlos López: MENSUAL
  INSERT INTO propietarios (id, nombre, telefono, email, tenant_id, modalidad_pago, created_at, updated_at)
  VALUES (v_carlos_id, 'Carlos López', '3005551234', 'carlos@email.com', v_tenant_id, 'MENSUAL', v_created_junio, v_now)
  ON CONFLICT (id) DO NOTHING;

  RAISE NOTICE 'Propietarios: Juan(QUINCENAL), María(SEMANAL), Carlos(MENSUAL)';

  -- ── 4. Usuarios (auth) — preservar existentes ─────────────
  -- Solo insertar si no existen (ON CONFLICT en email)

  -- Juan Pérez como PROPIETARIO
  INSERT INTO usuarios (id, email, password_hash, nombre, rol, propietario_id, tenant_id, activo, created_at, updated_at)
  VALUES (
    gen_random_uuid(),
    'juan@email.com',
    '$2b$10$abcdefghijklmnopqrstuuABCDEFGHIJKLMNOPQRSTUVWXYZ012345', -- hash placeholder
    'Juan Pérez',
    'PROPIETARIO',
    v_juan_id,
    v_tenant_id,
    true,
    v_created_junio,
    v_now
  )
  ON CONFLICT (email) DO UPDATE SET propietario_id = v_juan_id, nombre = 'Juan Pérez'
  RETURNING id INTO v_user_juan_id;

  IF v_user_juan_id IS NULL THEN
    SELECT id INTO v_user_juan_id FROM usuarios WHERE email = 'juan@email.com';
  END IF;

  -- María García como PROPIETARIO
  INSERT INTO usuarios (id, email, password_hash, nombre, rol, propietario_id, tenant_id, activo, created_at, updated_at)
  VALUES (
    gen_random_uuid(),
    'maria@email.com',
    '$2b$10$abcdefghijklmnopqrstuuABCDEFGHIJKLMNOPQRSTUVWXYZ012345',
    'María García',
    'PROPIETARIO',
    v_maria_id,
    v_tenant_id,
    true,
    v_created_junio,
    v_now
  )
  ON CONFLICT (email) DO UPDATE SET propietario_id = v_maria_id, nombre = 'María García'
  RETURNING id INTO v_user_maria_id;

  IF v_user_maria_id IS NULL THEN
    SELECT id INTO v_user_maria_id FROM usuarios WHERE email = 'maria@email.com';
  END IF;

  -- Carlos López como PROPIETARIO
  INSERT INTO usuarios (id, email, password_hash, nombre, rol, propietario_id, tenant_id, activo, created_at, updated_at)
  VALUES (
    gen_random_uuid(),
    'carlos@email.com',
    '$2b$10$abcdefghijklmnopqrstuuABCDEFGHIJKLMNOPQRSTUVWXYZ012345',
    'Carlos López',
    'PROPIETARIO',
    v_carlos_id,
    v_tenant_id,
    true,
    v_created_junio,
    v_now
  )
  ON CONFLICT (email) DO UPDATE SET propietario_id = v_carlos_id, nombre = 'Carlos López'
  RETURNING id INTO v_user_carlos_id;

  IF v_user_carlos_id IS NULL THEN
    SELECT id INTO v_user_carlos_id FROM usuarios WHERE email = 'carlos@email.com';
  END IF;

  -- Cobrador Juan (el cobrador real)
  INSERT INTO usuarios (id, email, password_hash, nombre, rol, propietario_id, tenant_id, activo, created_at, updated_at)
  VALUES (
    gen_random_uuid(),
    'cobrador@civica.com',
    '$2b$10$abcdefghijklmnopqrstuuABCDEFGHIJKLMNOPQRSTUVWXYZ012345',
    'Juan Cobrador',
    'COBRADOR',
    NULL,
    v_tenant_id,
    true,
    v_created_junio,
    v_now
  )
  ON CONFLICT (email) DO UPDATE SET nombre = 'Juan Cobrador'
  RETURNING id INTO v_user_cobrador_id;

  IF v_user_cobrador_id IS NULL THEN
    SELECT id INTO v_user_cobrador_id FROM usuarios WHERE email = 'cobrador@civica.com';
  END IF;

  -- Admin
  INSERT INTO usuarios (id, email, password_hash, nombre, rol, propietario_id, tenant_id, activo, created_at, updated_at)
  VALUES (
    gen_random_uuid(),
    'admin@civica.com',
    '$2b$10$abcdefghijklmnopqrstuuABCDEFGHIJKLMNOPQRSTUVWXYZ012345',
    'Admin Cívica',
    'ADMIN',
    NULL,
    v_tenant_id,
    true,
    v_created_junio,
    v_now
  )
  ON CONFLICT (email) DO UPDATE SET nombre = 'Admin Cívica'
  RETURNING id INTO v_user_admin_id;

  IF v_user_admin_id IS NULL THEN
    SELECT id INTO v_user_admin_id FROM usuarios WHERE email = 'admin@civica.com';
  END IF;

  -- Usar el cobrador existente si ya había uno
  IF v_user_cobrador_id IS NULL THEN
    SELECT id INTO v_user_cobrador_id FROM usuarios WHERE rol = 'COBRADOR' AND tenant_id = v_tenant_id LIMIT 1;
  END IF;

  v_cobrador_id := v_user_cobrador_id;

  RAISE NOTICE 'Usuarios auth creados. Cobrador ID: %', v_cobrador_id;

  -- ── 5. Tenencias (propietario ↔ casa) ─────────────────────
  INSERT INTO tenencias (id, propietario_id, casa_id, fecha_inicio, fecha_fin, created_at)
  VALUES
    (v_tenencia1_id, v_juan_id, v_casa1_id, '2026-01-01', NULL, v_created_junio),
    (v_tenencia2_id, v_maria_id, v_casa2_id, '2026-01-01', NULL, v_created_junio),
    (v_tenencia3_id, v_carlos_id, v_casa3_id, '2026-01-01', NULL, v_created_junio)
  ON CONFLICT (id) DO NOTHING;

  RAISE NOTICE 'Tenencias creadas';

  -- ── 6. Cuentas cartera (vincula propietario + frecuencia) ─
  INSERT INTO cuentas_cartera (id, propietario_id, tenant_id, conjunto_id, frecuencia, fecha_activacion, activa, created_at, updated_at)
  VALUES
    (v_cuenta1_id, v_juan_id, v_tenant_id, v_conjunto_id, 'QUINCENAL', '2026-01-01', true, v_created_junio, v_now),
    (v_cuenta2_id, v_maria_id, v_tenant_id, v_conjunto_id, 'SEMANAL', '2026-01-01', true, v_created_junio, v_now),
    (v_cuenta3_id, v_carlos_id, v_tenant_id, v_conjunto_id, 'MENSUAL', '2026-01-01', true, v_created_junio, v_now)
  ON CONFLICT (id) DO NOTHING;

  RAISE NOTICE 'Cuentas cartera creadas';

  -- ── 7. Tarifas (una por frecuencia, monto mensual = $40,000) ──
  -- La tarifa se almacena en la BD y es consultada en runtime
  INSERT INTO tarifas (id, tenant_id, conjunto_id, frecuencia, monto, fecha_vigencia, activa, created_at, updated_at)
  VALUES
    (v_tarifa_quincenal_id, v_tenant_id, v_conjunto_id, 'QUINCENAL', v_monto_quincenal, '2026-01-01', true, v_created_junio, v_now),
    (v_tarifa_semanal_id, v_tenant_id, v_conjunto_id, 'SEMANAL', v_monto_semanal, '2026-01-01', true, v_created_junio, v_now),
    (v_tarifa_mensual_id, v_tenant_id, v_conjunto_id, 'MENSUAL', v_monto_mensual_cuota, '2026-01-01', true, v_created_junio, v_now)
  ON CONFLICT (id) DO NOTHING;

  RAISE NOTICE 'Tarifas creadas: QUINCENAL=$%  SEMANAL=$%  MENSUAL=$%', v_monto_quincenal/100, v_monto_semanal/100, v_monto_mensual_cuota/100;

  -- ── 8. Montos predefinidos (para la UI de selección rápida) ──
  INSERT INTO montos_predefinidos (id, tenant_id, conjunto_id, monto, descripcion, activo, orden, created_at, updated_at)
  VALUES
    (gen_random_uuid(), v_tenant_id, v_conjunto_id, v_monto_semanal, 'Pago semanal', true, 1, v_created_junio, v_now),
    (gen_random_uuid(), v_tenant_id, v_conjunto_id, v_monto_quincenal, 'Pago quincenal', true, 2, v_created_junio, v_now),
    (gen_random_uuid(), v_tenant_id, v_conjunto_id, v_monto_mensual_cuota, 'Pago mensual', true, 3, v_created_junio, v_now)
  ON CONFLICT DO NOTHING;

  RAISE NOTICE 'Montos predefinidos creados';

  -- ════════════════════════════════════════════════════════════
  -- CUOTAS Y PAGOS — JUNIO 2026
  -- ════════════════════════════════════════════════════════════

  -- ── JUAN PÉREZ (QUINCENAL) ───────────────────────────────
  -- Junio: 2 cuotas (1ra quincena: 2026-06-01 → 2026-06-16, 2da: 2026-06-16 → 2026-07-01)
  -- Pago 1: 2026-06-13 (sábado más cercano al 15)
  -- Pago 2: 2026-06-27 (sábado más cercano al 30)

  -- Cuota 1ra quincena junio
  INSERT INTO cuotas (id, propietario_id, tenant_id, tarifa_id, concepto, monto, monto_pagado, periodo_inicio, periodo_fin, fecha_vencimiento, estado, notificacion_enviada, created_at, updated_at)
  VALUES (
    gen_random_uuid(), v_juan_id, v_tenant_id, v_tarifa_quincenal_id,
    'Cuota de Vigilancia - 1ra Quincena Junio 2026',
    v_monto_quincenal, v_monto_quincenal,  -- PAGADA
    '2026-06-01', '2026-06-16', '2026-06-13',
    'PAGADA', false, v_created_junio, v_now
  );

  -- Cuota 2da quincena junio
  INSERT INTO cuotas (id, propietario_id, tenant_id, tarifa_id, concepto, monto, monto_pagado, periodo_inicio, periodo_fin, fecha_vencimiento, estado, notificacion_enviada, created_at, updated_at)
  VALUES (
    gen_random_uuid(), v_juan_id, v_tenant_id, v_tarifa_quincenal_id,
    'Cuota de Vigilancia - 2da Quincena Junio 2026',
    v_monto_quincenal, v_monto_quincenal,  -- PAGADA
    '2026-06-16', '2026-07-01', '2026-06-27',
    'PAGADA', false, v_created_junio, v_now
  );

  -- Pagos de Juan en junio
  INSERT INTO pagos (id, client_payment_id, tenant_id, cuota_id, monto, fecha_pago, cobrador_id, propietario_id, sync_status, created_at, updated_at)
  SELECT
    gen_random_uuid(),
    'PAY-JUAN-JUN-Q1-' || v_juan_id,
    v_tenant_id,
    (SELECT id FROM cuotas WHERE propietario_id = v_juan_id AND periodo_inicio = '2026-06-01' AND periodo_fin = '2026-06-16' LIMIT 1),
    v_monto_quincenal,
    '2026-06-13',
    v_cobrador_id,
    v_juan_id,
    'SYNC_OK',
    v_created_junio,
    v_now;

  INSERT INTO pagos (id, client_payment_id, tenant_id, cuota_id, monto, fecha_pago, cobrador_id, propietario_id, sync_status, created_at, updated_at)
  SELECT
    gen_random_uuid(),
    'PAY-JUAN-JUN-Q2-' || v_juan_id,
    v_tenant_id,
    (SELECT id FROM cuotas WHERE propietario_id = v_juan_id AND periodo_inicio = '2026-06-16' AND periodo_fin = '2026-07-01' LIMIT 1),
    v_monto_quincenal,
    '2026-06-27',
    v_cobrador_id,
    v_juan_id,
    'SYNC_OK',
    v_created_junio,
    v_now;

  RAISE NOTICE 'Juan Pérez: 2 cuotas + 2 pagos junio (QUINCENAL)';

  -- ── MARÍA GARCÍA (SEMANAL) ───────────────────────────────
  -- Junio 2026: sábados = 6, 13, 20, 27 → 4 pagos de $10,000
  -- Cada semana laboral (lun-vie) genera un pago el sábado siguiente

  -- Cuota semanal 1 (2026-06-01 → 2026-06-08, vence 2026-06-06)
  INSERT INTO cuotas (id, propietario_id, tenant_id, tarifa_id, concepto, monto, monto_pagado, periodo_inicio, periodo_fin, fecha_vencimiento, estado, notificacion_enviada, created_at, updated_at)
  VALUES (
    gen_random_uuid(), v_maria_id, v_tenant_id, v_tarifa_semanal_id,
    'Cuota de Vigilancia - Semana 1 Junio 2026',
    v_monto_semanal, v_monto_semanal,  -- PAGADA
    '2026-06-01', '2026-06-08', '2026-06-06',
    'PAGADA', false, v_created_junio, v_now
  );

  -- Cuota semanal 2 (2026-06-08 → 2026-06-15, vence 2026-06-13)
  INSERT INTO cuotas (id, propietario_id, tenant_id, tarifa_id, concepto, monto, monto_pagado, periodo_inicio, periodo_fin, fecha_vencimiento, estado, notificacion_enviada, created_at, updated_at)
  VALUES (
    gen_random_uuid(), v_maria_id, v_tenant_id, v_tarifa_semanal_id,
    'Cuota de Vigilancia - Semana 2 Junio 2026',
    v_monto_semanal, v_monto_semanal,  -- PAGADA
    '2026-06-08', '2026-06-15', '2026-06-13',
    'PAGADA', false, v_created_junio, v_now
  );

  -- Cuota semanal 3 (2026-06-15 → 2026-06-22, vence 2026-06-20)
  INSERT INTO cuotas (id, propietario_id, tenant_id, tarifa_id, concepto, monto, monto_pagado, periodo_inicio, periodo_fin, fecha_vencimiento, estado, notificacion_enviada, created_at, updated_at)
  VALUES (
    gen_random_uuid(), v_maria_id, v_tenant_id, v_tarifa_semanal_id,
    'Cuota de Vigilancia - Semana 3 Junio 2026',
    v_monto_semanal, v_monto_semanal,  -- PAGADA
    '2026-06-15', '2026-06-22', '2026-06-20',
    'PAGADA', false, v_created_junio, v_now
  );

  -- Cuota semanal 4 (2026-06-22 → 2026-06-29, vence 2026-06-27)
  INSERT INTO cuotas (id, propietario_id, tenant_id, tarifa_id, concepto, monto, monto_pagado, periodo_inicio, periodo_fin, fecha_vencimiento, estado, notificacion_enviada, created_at, updated_at)
  VALUES (
    gen_random_uuid(), v_maria_id, v_tenant_id, v_tarifa_semanal_id,
    'Cuota de Vigilancia - Semana 4 Junio 2026',
    v_monto_semanal, v_monto_semanal,  -- PAGADA
    '2026-06-22', '2026-06-29', '2026-06-27',
    'PAGADA', false, v_created_junio, v_now
  );

  -- Pagos de María en junio (4 pagos, cada sábado)
  INSERT INTO pagos (id, client_payment_id, tenant_id, cuota_id, monto, fecha_pago, cobrador_id, propietario_id, sync_status, created_at, updated_at)
  SELECT
    gen_random_uuid(),
    'PAY-MARIA-JUN-S1-' || v_maria_id,
    v_tenant_id,
    (SELECT id FROM cuotas WHERE propietario_id = v_maria_id AND fecha_vencimiento = '2026-06-06' LIMIT 1),
    v_monto_semanal,
    '2026-06-06',
    v_cobrador_id,
    v_maria_id,
    'SYNC_OK',
    v_created_junio,
    v_now;

  INSERT INTO pagos (id, client_payment_id, tenant_id, cuota_id, monto, fecha_pago, cobrador_id, propietario_id, sync_status, created_at, updated_at)
  SELECT
    gen_random_uuid(),
    'PAY-MARIA-JUN-S2-' || v_maria_id,
    v_tenant_id,
    (SELECT id FROM cuotas WHERE propietario_id = v_maria_id AND fecha_vencimiento = '2026-06-13' LIMIT 1),
    v_monto_semanal,
    '2026-06-13',
    v_cobrador_id,
    v_maria_id,
    'SYNC_OK',
    v_created_junio,
    v_now;

  INSERT INTO pagos (id, client_payment_id, tenant_id, cuota_id, monto, fecha_pago, cobrador_id, propietario_id, sync_status, created_at, updated_at)
  SELECT
    gen_random_uuid(),
    'PAY-MARIA-JUN-S3-' || v_maria_id,
    v_tenant_id,
    (SELECT id FROM cuotas WHERE propietario_id = v_maria_id AND fecha_vencimiento = '2026-06-20' LIMIT 1),
    v_monto_semanal,
    '2026-06-20',
    v_cobrador_id,
    v_maria_id,
    'SYNC_OK',
    v_created_junio,
    v_now;

  INSERT INTO pagos (id, client_payment_id, tenant_id, cuota_id, monto, fecha_pago, cobrador_id, propietario_id, sync_status, created_at, updated_at)
  SELECT
    gen_random_uuid(),
    'PAY-MARIA-JUN-S4-' || v_maria_id,
    v_tenant_id,
    (SELECT id FROM cuotas WHERE propietario_id = v_maria_id AND fecha_vencimiento = '2026-06-27' LIMIT 1),
    v_monto_semanal,
    '2026-06-27',
    v_cobrador_id,
    v_maria_id,
    'SYNC_OK',
    v_created_junio,
    v_now;

  RAISE NOTICE 'María García: 4 cuotas + 4 pagos junio (SEMANAL)';

  -- ── CARLOS LÓPEZ (MENSUAL) ───────────────────────────────
  -- Junio: 1 cuota mensual (2026-06-01 → 2026-07-01, vence 2026-06-27)
  -- Pago: 2026-06-27 (sábado más cercano al 30)

  INSERT INTO cuotas (id, propietario_id, tenant_id, tarifa_id, concepto, monto, monto_pagado, periodo_inicio, periodo_fin, fecha_vencimiento, estado, notificacion_enviada, created_at, updated_at)
  VALUES (
    gen_random_uuid(), v_carlos_id, v_tenant_id, v_tarifa_mensual_id,
    'Cuota de Vigilancia - Junio 2026',
    v_monto_mensual_cuota, v_monto_mensual_cuota,  -- PAGADA
    '2026-06-01', '2026-07-01', '2026-06-27',
    'PAGADA', false, v_created_junio, v_now
  );

  -- Pago de Carlos en junio
  INSERT INTO pagos (id, client_payment_id, tenant_id, cuota_id, monto, fecha_pago, cobrador_id, propietario_id, sync_status, created_at, updated_at)
  SELECT
    gen_random_uuid(),
    'PAY-CARLOS-JUN-M1-' || v_carlos_id,
    v_tenant_id,
    (SELECT id FROM cuotas WHERE propietario_id = v_carlos_id AND periodo_inicio = '2026-06-01' AND periodo_fin = '2026-07-01' LIMIT 1),
    v_monto_mensual_cuota,
    '2026-06-27',
    v_cobrador_id,
    v_carlos_id,
    'SYNC_OK',
    v_created_junio,
    v_now;

  RAISE NOTICE 'Carlos López: 1 cuota + 1 pago junio (MENSUAL)';

  -- ════════════════════════════════════════════════════════════
  -- CUOTAS — JULIO 2026 (pendientes, sin pago aún)
  -- ════════════════════════════════════════════════════════════

  -- ── JUAN PÉREZ — Julio QUINCENAL ─────────────────────────
  -- 1ra quincena: 2026-07-01 → 2026-07-16, vence 2026-07-11 (sábado más cercano al 15)
  INSERT INTO cuotas (id, propietario_id, tenant_id, tarifa_id, concepto, monto, monto_pagado, periodo_inicio, periodo_fin, fecha_vencimiento, estado, notificacion_enviada, created_at, updated_at)
  VALUES (
    gen_random_uuid(), v_juan_id, v_tenant_id, v_tarifa_quincenal_id,
    'Cuota de Vigilancia - 1ra Quincena Julio 2026',
    v_monto_quincenal, 0,
    '2026-07-01', '2026-07-16', '2026-07-11',
    'PENDIENTE', false, v_created_julio, v_now
  );

  -- 2da quincena: 2026-07-16 → 2026-08-01, vence 2026-07-25 (sábado más cercano al 31)
  INSERT INTO cuotas (id, propietario_id, tenant_id, tarifa_id, concepto, monto, monto_pagado, periodo_inicio, periodo_fin, fecha_vencimiento, estado, notificacion_enviada, created_at, updated_at)
  VALUES (
    gen_random_uuid(), v_juan_id, v_tenant_id, v_tarifa_quincenal_id,
    'Cuota de Vigilancia - 2da Quincena Julio 2026',
    v_monto_quincenal, 0,
    '2026-07-16', '2026-08-01', '2026-07-25',
    'PENDIENTE', false, v_created_julio, v_now
  );

  RAISE NOTICE 'Juan Pérez: 2 cuotas julio QUINCENAL (pendientes)';

  -- ── MARÍA GARCÍA — Julio SEMANAL ─────────────────────────
  -- Julio 2026: sábados = 4, 11, 18, 25 → 4 pagos

  INSERT INTO cuotas (id, propietario_id, tenant_id, tarifa_id, concepto, monto, monto_pagado, periodo_inicio, periodo_fin, fecha_vencimiento, estado, notificacion_enviada, created_at, updated_at)
  VALUES
    (gen_random_uuid(), v_maria_id, v_tenant_id, v_tarifa_semanal_id,
     'Cuota de Vigilancia - Semana 1 Julio 2026',
     v_monto_semanal, 0,
     '2026-07-01', '2026-07-08', '2026-07-04',
     'PENDIENTE', false, v_created_julio, v_now),
    (gen_random_uuid(), v_maria_id, v_tenant_id, v_tarifa_semanal_id,
     'Cuota de Vigilancia - Semana 2 Julio 2026',
     v_monto_semanal, 0,
     '2026-07-08', '2026-07-15', '2026-07-11',
     'PENDIENTE', false, v_created_julio, v_now),
    (gen_random_uuid(), v_maria_id, v_tenant_id, v_tarifa_semanal_id,
     'Cuota de Vigilancia - Semana 3 Julio 2026',
     v_monto_semanal, 0,
     '2026-07-15', '2026-07-22', '2026-07-18',
     'PENDIENTE', false, v_created_julio, v_now),
    (gen_random_uuid(), v_maria_id, v_tenant_id, v_tarifa_semanal_id,
     'Cuota de Vigilancia - Semana 4 Julio 2026',
     v_monto_semanal, 0,
     '2026-07-22', '2026-07-29', '2026-07-25',
     'PENDIENTE', false, v_created_julio, v_now);

  RAISE NOTICE 'María García: 4 cuotas julio SEMANAL (pendientes)';

  -- ── CARLOS LÓPEZ — Julio MENSUAL ─────────────────────────
  INSERT INTO cuotas (id, propietario_id, tenant_id, tarifa_id, concepto, monto, monto_pagado, periodo_inicio, periodo_fin, fecha_vencimiento, estado, notificacion_enviada, created_at, updated_at)
  VALUES (
    gen_random_uuid(), v_carlos_id, v_tenant_id, v_tarifa_mensual_id,
    'Cuota de Vigilancia - Julio 2026',
    v_monto_mensual_cuota, 0,
    '2026-07-01', '2026-08-01', '2026-07-25',
    'PENDIENTE', false, v_created_julio, v_now
  );

  RAISE NOTICE 'Carlos López: 1 cuota julio MENSUAL (pendiente)';

  -- ════════════════════════════════════════════════════════════
  -- ASIGNACIONES ETAPA (cobrador asignado a la etapa)
  -- ════════════════════════════════════════════════════════════
  INSERT INTO asignaciones_etapa (id, usuario_id, etapa_id, tenant_id, created_at)
  VALUES (gen_random_uuid(), v_cobrador_id, v_etapa_id, v_tenant_id, v_created_junio)
  ON CONFLICT DO NOTHING;

  RAISE NOTICE '═══════════════════════════════════════════════════════════';
  RAISE NOTICE 'SEED COMPLETADO EXITOSAMENTE';
  RAISE NOTICE '═══════════════════════════════════════════════════════════';
  RAISE NOTICE 'Juan Pérez (QUINCENAL): juan@email.com';
  RAISE NOTICE '  Junio: 2 pagos de $20,000 = $40,000 [PAGADO]';
  RAISE NOTICE '  Julio: 2 cuotas pendientes de $20,000';
  RAISE NOTICE '';
  RAISE NOTICE 'María García (SEMANAL): maria@email.com';
  RAISE NOTICE '  Junio: 4 pagos de $10,000 = $40,000 [PAGADO]';
  RAISE NOTICE '  Julio: 4 cuotas pendientes de $10,000';
  RAISE NOTICE '';
  RAISE NOTICE 'Carlos López (MENSUAL): carlos@email.com';
  RAISE NOTICE '  Junio: 1 pago de $40,000 [PAGADO]';
  RAISE NOTICE '  Julio: 1 cuota pendiente de $40,000';
  RAISE NOTICE '';
  RAISE NOTICE 'Cobrador: cobrador@civica.com';
  RAISE NOTICE 'Admin: admin@civica.com';
  RAISE NOTICE 'Tarifa actual: $40,000/mes (almacenada en BD, actualizable)';

END $$;
