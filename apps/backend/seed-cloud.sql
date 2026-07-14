-- ═══════════════════════════════════════════════════════════════
-- SEED: Base de datos cloud — Cívica Pago
-- Modalidades: QUINCENAL (Juan Pérez), SEMANAL (María García), MENSUAL (Carlos López)
--
-- LOGIN: username + password (no email).
-- Patternos de username:
--   Admin:     "admin"                          (caso especial)
--   Cobrador:  "{nombre}{primerApellido}cobrador"  → "juanperezcobrador"
--   Residente: "{manzana}_{casa}_residente"        → "manzanaA_casa101_residente"
--
-- Passwords (prueba):
--   Admin:     "Admin2026!"
--   Cobrador:  "{nombre}{primerApellido}{año}"  → "juanperez2026"
--   Residente: Aleatoria                        → "A3bK7xP9mN"
-- ═══════════════════════════════════════════════════════════════

DO $$
DECLARE
  v_tenant_id UUID := '00000000-0000-0000-0000-000000000001';
  v_proyecto_id UUID;
  v_etapa_id UUID;
  v_manzana_id UUID;

  -- Casas (IDs fijos para referencias)
  v_casa1_id UUID := 'a1000000-0000-0000-0000-000000000001';
  v_casa2_id UUID := 'a1000000-0000-0000-0000-000000000002';
  v_casa3_id UUID := 'a1000000-0000-0000-0000-000000000003';

  -- Residentes
  v_juan_id UUID := 'b2000000-0000-0000-0000-000000000001';
  v_maria_id UUID := 'b2000000-0000-0000-0000-000000000002';
  v_carlos_id UUID := 'b2000000-0000-0000-0000-000000000003';

  -- Tenencias
  v_tenencia1_id UUID := 'c3000000-0000-0000-0000-000000000001';
  v_tenencia2_id UUID := 'c3000000-0000-0000-0000-000000000002';
  v_tenencia3_id UUID := 'c3000000-0000-0000-0000-000000000003';

  -- Planes de Cobro
  v_plan1_id UUID := 'd4000000-0000-0000-0000-000000000001';
  v_plan2_id UUID := 'd4000000-0000-0000-0000-000000000002';
  v_plan3_id UUID := 'd4000000-0000-0000-0000-000000000003';

  -- Tarifas
  v_tarifa_quincenal_id UUID := 'e5000000-0000-0000-0000-000000000001';
  v_tarifa_semanal_id   UUID := 'e5000000-0000-0000-0000-000000000002';
  v_tarifa_mensual_id   UUID := 'e5000000-0000-0000-0000-000000000003';

  -- Montos en centavos: $40,000 COP = 4,000,000 centavos
  v_monto_mensual     INT := 4000000;
  v_monto_quincenal   INT := 2000000;  -- $20,000
  v_monto_semanal     INT := 1000000;  -- $10,000

  -- Timestamps
  v_now           TIMESTAMPTZ := NOW();
  v_created_junio TIMESTAMPTZ := '2026-06-01T10:00:00Z';
  v_created_julio TIMESTAMPTZ := '2026-07-01T10:00:00Z';

  -- Hashes bcrypt reales (generados con bcrypt@10 rounds)
  -- Admin2026!      → $2b$10$xT9obvJfjrh3W/9VMO88q.oJR.alFFm0fZ2.ifv2Q47pKiWJAPYie
  -- juanperez2026   → $2b$10$oCiqav8sfAeFDdjVg6/P9.XeQWGKetNi6jQWXvjy/eRFHGZH.Nt9G
  -- A3bK7xP9mN      → $2b$10$CtDT.hFk6TfwkNihX/NpSOD9FdFf8W0AoEj2ftvpWJEW30Qe5YrtC
  v_hash_admin     VARCHAR(255) := '$2b$10$xT9obvJfjrh3W/9VMO88q.oJR.alFFm0fZ2.ifv2Q47pKiWJAPYie';
  v_hash_cobrador  VARCHAR(255) := '$2b$10$oCiqav8sfAeFDdjVg6/P9.XeQWGKetNi6jQWXvjy/eRFHGZH.Nt9G';
  v_hash_residente VARCHAR(255) := '$2b$10$CtDT.hFk6TfwkNihX/NpSOD9FdFf8W0AoEj2ftvpWJEW30Qe5YrtC';

  -- Usuarios
  v_user_admin_id     UUID := 'f6000000-0000-0000-0000-000000000001';
  v_user_cobrador_id  UUID := 'f6000000-0000-0000-0000-000000000002';
  v_user_juan_id      UUID := 'f6000000-0000-0000-0000-000000000003';
  v_user_maria_id     UUID := 'f6000000-0000-0000-0000-000000000004';
  v_user_carlos_id    UUID := 'f6000000-0000-0000-0000-000000000005';
BEGIN

  -- ═══════════════════════════════════════════════════════════════
  -- 1. Proyecto, Etapa, Manzana
  -- ═══════════════════════════════════════════════════════════════
  INSERT INTO proyectos (id, nombre, tenant_id, created_at, updated_at)
  VALUES (gen_random_uuid(), 'Conjunto Residencial Cívica', v_tenant_id, v_created_junio, v_now)
  ON CONFLICT (id) DO NOTHING
  RETURNING id INTO v_proyecto_id;

  IF v_proyecto_id IS NULL THEN
    SELECT id INTO v_proyecto_id FROM proyectos WHERE tenant_id = v_tenant_id LIMIT 1;
  END IF;

  INSERT INTO etapas (id, nombre, proyecto_id, created_at)
  VALUES (gen_random_uuid(), 'Etapa 1', v_proyecto_id, v_created_junio)
  ON CONFLICT (id) DO NOTHING
  RETURNING id INTO v_etapa_id;

  IF v_etapa_id IS NULL THEN
    SELECT id INTO v_etapa_id FROM etapas WHERE proyecto_id = v_proyecto_id LIMIT 1;
  END IF;

  INSERT INTO manzanas (id, nombre, etapa_id, created_at)
  VALUES (gen_random_uuid(), 'Manzana A', v_etapa_id, v_created_junio)
  ON CONFLICT (id) DO NOTHING
  RETURNING id INTO v_manzana_id;

  IF v_manzana_id IS NULL THEN
    SELECT id INTO v_manzana_id FROM manzanas WHERE etapa_id = v_etapa_id LIMIT 1;
  END IF;

  RAISE NOTICE 'Proyecto: %, Etapa: %, Manzana: %', v_proyecto_id, v_etapa_id, v_manzana_id;

  -- ═══════════════════════════════════════════════════════════════
  -- 2. Casas
  -- ═══════════════════════════════════════════════════════════════
  INSERT INTO casas (id, direccion_interna, manzana_id, created_at)
  VALUES
    (v_casa1_id, 'Casa 101', v_manzana_id, v_created_junio),
    (v_casa2_id, 'Casa 102', v_manzana_id, v_created_junio),
    (v_casa3_id, 'Casa 103', v_manzana_id, v_created_junio)
  ON CONFLICT (id) DO NOTHING;

  RAISE NOTICE 'Casas creadas: 101, 102, 103';

  -- ═══════════════════════════════════════════════════════════════
  -- 3. Residentes (antes "propietarios")
  -- ═══════════════════════════════════════════════════════════════
  INSERT INTO residentes (id, tipo, nombre, telefono, email, casa_actual_id, tenant_id, modalidad_pago, created_at, updated_at)
  VALUES
    (v_juan_id,   'PROPIETARIO', 'Juan Pérez',   '3001234567', 'juan@email.com',   v_casa1_id, v_tenant_id, 'QUINCENAL', v_created_junio, v_now),
    (v_maria_id,  'PROPIETARIO', 'María García', '3009876543', 'maria@email.com',  v_casa2_id, v_tenant_id, 'SEMANAL',   v_created_junio, v_now),
    (v_carlos_id, 'PROPIETARIO', 'Carlos López', '3005551234', 'carlos@email.com', v_casa3_id, v_tenant_id, 'MENSUAL',   v_created_junio, v_now)
  ON CONFLICT (id) DO NOTHING;

  RAISE NOTICE 'Residentes: Juan(QUINCENAL), María(SEMANAL), Carlos(MENSUAL)';

  -- ═══════════════════════════════════════════════════════════════
  -- 4. Usuarios — con USERNAME en columna email
  --    Patrón: admin / juanperezcobrador / manzanaA_casa101_residente
  -- ═══════════════════════════════════════════════════════════════
  INSERT INTO usuarios (id, email, password_hash, nombre, rol, residente_id, tenant_id, activo, created_at, updated_at)
  VALUES
    (v_user_admin_id,
     'admin',
     v_hash_admin,
     'Admin Cívica',
     'ADMIN',
     NULL,
     v_tenant_id, true, v_created_junio, v_now)
  ON CONFLICT (email) DO UPDATE SET
    password_hash = v_hash_admin, nombre = 'Admin Cívica', rol = 'ADMIN';

  INSERT INTO usuarios (id, email, password_hash, nombre, rol, residente_id, tenant_id, activo, created_at, updated_at)
  VALUES
    (v_user_cobrador_id,
     'juanperezcobrador',
     v_hash_cobrador,
     'Juan Cobrador',
     'COBRADOR',
     NULL,
     v_tenant_id, true, v_created_junio, v_now)
  ON CONFLICT (email) DO UPDATE SET
    password_hash = v_hash_cobrador, nombre = 'Juan Cobrador', rol = 'COBRADOR';

  INSERT INTO usuarios (id, email, password_hash, nombre, rol, residente_id, tenant_id, activo, created_at, updated_at)
  VALUES
    (v_user_juan_id,
     'manzanaA_casa101_residente',
     v_hash_residente,
     'Juan Pérez',
     'RESIDENTE',
     v_juan_id,
     v_tenant_id, true, v_created_junio, v_now)
  ON CONFLICT (email) DO UPDATE SET
    password_hash = v_hash_residente, nombre = 'Juan Pérez', residente_id = v_juan_id;

  INSERT INTO usuarios (id, email, password_hash, nombre, rol, residente_id, tenant_id, activo, created_at, updated_at)
  VALUES
    (v_user_maria_id,
     'manzanaA_casa102_residente',
     v_hash_residente,
     'María García',
     'RESIDENTE',
     v_maria_id,
     v_tenant_id, true, v_created_junio, v_now)
  ON CONFLICT (email) DO UPDATE SET
    password_hash = v_hash_residente, nombre = 'María García', residente_id = v_maria_id;

  INSERT INTO usuarios (id, email, password_hash, nombre, rol, residente_id, tenant_id, activo, created_at, updated_at)
  VALUES
    (v_user_carlos_id,
     'manzanaA_casa103_residente',
     v_hash_residente,
     'Carlos López',
     'RESIDENTE',
     v_carlos_id,
     v_tenant_id, true, v_created_junio, v_now)
  ON CONFLICT (email) DO UPDATE SET
    password_hash = v_hash_residente, nombre = 'Carlos López', residente_id = v_carlos_id;

  RAISE NOTICE 'Usuarios creados: admin / juanperezcobrador / manzanaA_casa{101,102,103}_residente';

  -- ═══════════════════════════════════════════════════════════════
  -- 5. Tenencias (Residente ↔ Casa)
  -- ═══════════════════════════════════════════════════════════════
  INSERT INTO tenencias (id, residente_id, casa_id, fecha_inicio, fecha_fin, created_at)
  VALUES
    (v_tenencia1_id, v_juan_id,   v_casa1_id, '2026-01-01', NULL, v_created_junio),
    (v_tenencia2_id, v_maria_id,  v_casa2_id, '2026-01-01', NULL, v_created_junio),
    (v_tenencia3_id, v_carlos_id, v_casa3_id, '2026-01-01', NULL, v_created_junio)
  ON CONFLICT (id) DO NOTHING;

  RAISE NOTICE 'Tenencias creadas';

  -- ═══════════════════════════════════════════════════════════════
  -- 6. Planes de Cobro (antes "cuentas_cartera")
  -- ═══════════════════════════════════════════════════════════════
  INSERT INTO planes_de_cobro (id, casa_id, residente_id, tenant_id, proyecto_id, modalidad, valor_mensual, fecha_activacion, activa, created_at, updated_at)
  VALUES
    (v_plan1_id, v_casa1_id, v_juan_id,   v_tenant_id, v_proyecto_id, 'QUINCENAL', v_monto_mensual, '2026-01-01', true, v_created_junio, v_now),
    (v_plan2_id, v_casa2_id, v_maria_id,  v_tenant_id, v_proyecto_id, 'SEMANAL',   v_monto_mensual, '2026-01-01', true, v_created_junio, v_now),
    (v_plan3_id, v_casa3_id, v_carlos_id, v_tenant_id, v_proyecto_id, 'MENSUAL',   v_monto_mensual, '2026-01-01', true, v_created_junio, v_now)
  ON CONFLICT (id) DO NOTHING;

  RAISE NOTICE 'Planes de cobro creados';

  -- ═══════════════════════════════════════════════════════════════
  -- 7. Tarifas (modalidad en vez de frecuencia)
  -- ═══════════════════════════════════════════════════════════════
  INSERT INTO tarifas (id, tenant_id, proyecto_id, modalidad, monto, fecha_vigencia, activa, created_at, updated_at)
  VALUES
    (v_tarifa_quincenal_id, v_tenant_id, v_proyecto_id, 'QUINCENAL', v_monto_quincenal, '2026-01-01', true, v_created_junio, v_now),
    (v_tarifa_semanal_id,   v_tenant_id, v_proyecto_id, 'SEMANAL',   v_monto_semanal,   '2026-01-01', true, v_created_junio, v_now),
    (v_tarifa_mensual_id,   v_tenant_id, v_proyecto_id, 'MENSUAL',   v_monto_mensual,   '2026-01-01', true, v_created_junio, v_now)
  ON CONFLICT (id) DO NOTHING;

  RAISE NOTICE 'Tarifas: QUINCENAL=$%  SEMANAL=$%  MENSUAL=$%',
    v_monto_quincenal/100, v_monto_semanal/100, v_monto_mensual/100;

  -- ═══════════════════════════════════════════════════════════════
  -- 8. Montos predefinidos
  -- ═══════════════════════════════════════════════════════════════
  INSERT INTO montos_predefinidos (id, tenant_id, proyecto_id, monto, descripcion, activo, orden, created_at, updated_at)
  VALUES
    (gen_random_uuid(), v_tenant_id, v_proyecto_id, v_monto_semanal,   'Pago semanal',   true, 1, v_created_junio, v_now),
    (gen_random_uuid(), v_tenant_id, v_proyecto_id, v_monto_quincenal, 'Pago quincenal', true, 2, v_created_junio, v_now),
    (gen_random_uuid(), v_tenant_id, v_proyecto_id, v_monto_mensual,   'Pago mensual',   true, 3, v_created_junio, v_now)
  ON CONFLICT DO NOTHING;

  RAISE NOTICE 'Montos predefinidos creados';

  -- ═══════════════════════════════════════════════════════════════
  -- 9. Asignación de etapa al cobrador
  -- ═══════════════════════════════════════════════════════════════
  INSERT INTO asignaciones_etapa (id, usuario_id, etapa_id, tenant_id, created_at)
  VALUES (gen_random_uuid(), v_user_cobrador_id, v_etapa_id, v_tenant_id, v_created_junio)
  ON CONFLICT (usuario_id, etapa_id) DO NOTHING;

  RAISE NOTICE 'Asignación cobrador → etapa creada';

  -- ═══════════════════════════════════════════════════════════════
  -- RESUMEN DE CREDENCIALES
  -- ═══════════════════════════════════════════════════════════════
  RAISE NOTICE '';
  RAISE NOTICE '═══════════════════════════════════════════════════════════';
  RAISE NOTICE '  SEED COMPLETADO EXITOSAMENTE';
  RAISE NOTICE '═══════════════════════════════════════════════════════════';
  RAISE NOTICE '';
  RAISE NOTICE '  ── ADMIN ──';
  RAISE NOTICE '  Usuario:  admin';
  RAISE NOTICE '  Password: Admin2026!';
  RAISE NOTICE '';
  RAISE NOTICE '  ── COBRADOR ──';
  RAISE NOTICE '  Usuario:  juanperezcobrador';
  RAISE NOTICE '  Password: juanperez2026';
  RAISE NOTICE '';
  RAISE NOTICE '  ── RESIDENTES ──';
  RAISE NOTICE '  Juan Pérez   → manzanaA_casa101_residente / A3bK7xP9mN  (QUINCENAL)';
  RAISE NOTICE '  María García → manzanaA_casa102_residente / A3bK7xP9mN  (SEMANAL)';
  RAISE NOTICE '  Carlos López → manzanaA_casa103_residente / A3bK7xP9mN  (MENSUAL)';
  RAISE NOTICE '';
  RAISE NOTICE '  ── Nota: Los cobros periódicos se generan automáticamente ──';
  RAISE NOTICE '  vía GenerarCobrosUseCase al iniciar el motor de recaudo.';
  RAISE NOTICE '═══════════════════════════════════════════════════════════';

END $$;
