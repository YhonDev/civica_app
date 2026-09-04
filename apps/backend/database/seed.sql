-- ═══════════════════════════════════════════════════════════════
-- SEED OFICIAL: Cívica Pago — Base de Datos Actual
-- Proyecto: Urb San Sebastian (Lenguaje Ubicuo y Dominio Real)
-- Modalidades: SEMANAL (Camilo Silva), QUINCENAL (Carmen Cabarca), MENSUAL (Yhon Barrios)
-- Cobrador: Ricardo Arrieta (ricardoarrietacobrador)
-- Admin: Admin Cívica (admin)
--
-- Idempotente: puede ejecutarse múltiples veces sin errores de clave única.
-- ═══════════════════════════════════════════════════════════════

DO $$
DECLARE
  v_tenant_id UUID := '00000000-0000-0000-0000-000000000001';

  -- Proyecto
  v_proyecto_id UUID := '2b1ddabe-440c-47ef-8f6f-436b27676f37';

  -- Etapas
  v_etapa1_id UUID := '597abe7a-49fa-4f17-8531-97325cc59c77';
  v_etapa2_id UUID := '41b524dc-952e-4f16-9af7-c67cb6b7f342';

  -- Manzanas
  v_manzana_a_e1_id UUID := 'a5c4735b-d76d-42f4-8e80-0e41a2732089';
  v_manzana_b_e1_id UUID := '68eb7775-0f9a-48a3-b929-aac24772dd57';
  v_manzana_a_e2_id UUID := '73baf14a-c9a3-4964-b7fb-e27bfe80f361';

  -- Casas
  v_casa1_e1_ma_id UUID := '5764ebec-f07a-4dec-99d4-7ea4f181da21';
  v_casa1_e1_mb_id UUID := 'f5902fd5-86c8-4175-bea1-528e49a0132d';
  v_casa1_e2_ma_id UUID := 'c74872d6-4c39-4c90-b20f-da6994cc52ac';

  -- Residentes
  v_camilo_id UUID := '371ca659-3d76-4c50-835e-52e382169b2e';
  v_carmen_id UUID := '793747e5-d84e-432d-b261-b66cb6cc2e49';
  v_yhon_id   UUID := 'd6c823aa-5679-40bb-9fce-660ba74a836a';

  -- Tenencias
  v_tenencia1_id UUID := '7ed0930b-f6fb-4265-abb6-fe67f812e15c';
  v_tenencia2_id UUID := '91d5c62c-0391-4ebc-a20a-f895904d099e';
  v_tenencia3_id UUID := '9a017167-ed97-412a-888a-f76eb7292e18';

  -- Planes de Cobro
  v_plan1_id UUID := 'f3b3ab1e-2352-43c7-86ce-b875ffc10827';
  v_plan2_id UUID := '48b3556d-dfe9-415a-a7ac-400203ad7cdb';
  v_plan3_id UUID := 'acc0c02d-0b27-4dec-96ec-161b472198bb';

  -- Tarifas
  v_tarifa_semanal_id   UUID := 'a34eedbf-eb7f-4f74-8666-4660c0d3971e';
  v_tarifa_quincenal_id UUID := '2b22ed99-88b6-42c3-8517-8b670640052a';
  v_tarifa_mensual_id   UUID := '686fd94b-dbd3-455b-880d-39db574f5693';

  -- Montos en centavos: $10,000, $20,000, $40,000 COP
  v_monto_semanal   INT := 1000000;
  v_monto_quincenal INT := 2000000;
  v_monto_mensual   INT := 4000000;

  -- Usuarios
  v_user_admin_id     UUID := 'f6000000-0000-0000-0000-000000000001';
  v_user_cobrador_id  UUID := '0c46d156-b0d2-4832-aac6-ab69f4e6c055';
  v_user_camilo_id    UUID := '325f6e59-9189-40d5-8566-5ac8b0c9f544';
  v_user_carmen_id    UUID := '19a4af69-8cbf-4f14-95e2-ff808f8cc3a1';
  v_user_yhon_id      UUID := '8a01eb4d-ecfe-4145-9776-e7756d94e9f1';

  -- Hashes bcrypt reales verificados
  -- Admin2026!           → $2b$10$xT9obvJfjrh3W/9VMO88q.oJR.alFFm0fZ2.ifv2Q47pKiWJAPYie
  -- ricardoArrieta2026.  → $2b$10$XOH0eQEC27mDNzj6oRqISOrQoc46miRS8vE6pBppXpQrEWozRMnrm
  -- Casa1ManzanaA..      → $2b$10$N4RcWQIVr0rqcVj0Pfpqm.9v/F1JGZp92DsbjPNggH.sTL9tnjJOS
  -- Casa1ManzanaB        → $2b$10$zGYi4NDo/Q838iJTuw4W7OiShQYk4pRFYqr7.48OVbRq8GH.sq.CO
  -- Casa1ManzanaA.. (E2) → $2b$10$WJm1f3hzE1QZhfyl9gXBlOT7XNNP80EFksz7WjyAECwj666jiFkK2
  v_hash_admin     VARCHAR(255) := '$2b$10$xT9obvJfjrh3W/9VMO88q.oJR.alFFm0fZ2.ifv2Q47pKiWJAPYie';
  v_hash_cobrador  VARCHAR(255) := '$2b$10$XOH0eQEC27mDNzj6oRqISOrQoc46miRS8vE6pBppXpQrEWozRMnrm';
  v_hash_camilo    VARCHAR(255) := '$2b$10$N4RcWQIVr0rqcVj0Pfpqm.9v/F1JGZp92DsbjPNggH.sTL9tnjJOS';
  v_hash_carmen    VARCHAR(255) := '$2b$10$zGYi4NDo/Q838iJTuw4W7OiShQYk4pRFYqr7.48OVbRq8GH.sq.CO';
  v_hash_yhon      VARCHAR(255) := '$2b$10$WJm1f3hzE1QZhfyl9gXBlOT7XNNP80EFksz7WjyAECwj666jiFkK2';

  v_now TIMESTAMPTZ := NOW();
BEGIN

  -- ── 1. Proyecto ──────────────────────────────────────────
  INSERT INTO proyectos (id, nombre, tenant_id, recordatorios_automaticos, permite_pagos_parciales, modo_mantenimiento, created_at, updated_at)
  VALUES (v_proyecto_id, 'Urb San Sebastian', v_tenant_id, true, false, false, v_now, v_now)
  ON CONFLICT (id) DO UPDATE SET nombre = EXCLUDED.nombre;

  -- ── 2. Etapas ────────────────────────────────────────────
  INSERT INTO etapas (id, nombre, proyecto_id, created_at)
  VALUES
    (v_etapa1_id, 'Etapa 1', v_proyecto_id, v_now),
    (v_etapa2_id, 'Etapa 2', v_proyecto_id, v_now)
  ON CONFLICT (id) DO UPDATE SET nombre = EXCLUDED.nombre;

  -- ── 3. Manzanas ──────────────────────────────────────────
  INSERT INTO manzanas (id, nombre, etapa_id, created_at)
  VALUES
    (v_manzana_a_e1_id, 'Manzana A', v_etapa1_id, v_now),
    (v_manzana_b_e1_id, 'Manzana B', v_etapa1_id, v_now),
    (v_manzana_a_e2_id, 'Manzana A', v_etapa2_id, v_now)
  ON CONFLICT (id) DO UPDATE SET nombre = EXCLUDED.nombre;

  -- ── 4. Casas ─────────────────────────────────────────────
  INSERT INTO casas (id, direccion_interna, manzana_id, created_at)
  VALUES
    (v_casa1_e1_ma_id, 'Casa 1', v_manzana_a_e1_id, v_now),
    (v_casa1_e1_mb_id, 'Casa 1', v_manzana_b_e1_id, v_now),
    (v_casa1_e2_ma_id, 'Casa 1', v_manzana_a_e2_id, v_now)
  ON CONFLICT (id) DO UPDATE SET direccion_interna = EXCLUDED.direccion_interna;

  -- ── 5. Residentes ────────────────────────────────────────
  INSERT INTO residentes (id, tipo, nombre, telefono, email, casa_actual_id, tenant_id, modalidad_pago, created_at, updated_at)
  VALUES
    (v_camilo_id, 'PROPIETARIO', 'Camilo Silva',  '3001234567', NULL, v_casa1_e1_ma_id, v_tenant_id, 'SEMANAL',   v_now, v_now),
    (v_carmen_id, 'PROPIETARIO', 'Carmen Cabarca', '3144851444', NULL, v_casa1_e1_mb_id, v_tenant_id, 'QUINCENAL', v_now, v_now),
    (v_yhon_id,   'PROPIETARIO', 'Yhon Barrios',   '3007172111', NULL, v_casa1_e2_ma_id, v_tenant_id, 'MENSUAL',   v_now, v_now)
  ON CONFLICT (id) DO UPDATE SET
    nombre = EXCLUDED.nombre,
    telefono = EXCLUDED.telefono,
    modalidad_pago = EXCLUDED.modalidad_pago,
    casa_actual_id = EXCLUDED.casa_actual_id;

  -- ── 6. Tenencias ─────────────────────────────────────────
  INSERT INTO tenencias (id, residente_id, casa_id, fecha_inicio, fecha_fin, created_at)
  VALUES
    (v_tenencia1_id, v_camilo_id, v_casa1_e1_ma_id, '2026-09-01', NULL, v_now),
    (v_tenencia2_id, v_carmen_id, v_casa1_e1_mb_id, '2026-09-01', NULL, v_now),
    (v_tenencia3_id, v_yhon_id,   v_casa1_e2_ma_id, '2026-09-01', NULL, v_now)
  ON CONFLICT (id) DO NOTHING;

  -- ── 7. Tarifas ───────────────────────────────────────────
  INSERT INTO tarifas (id, tenant_id, proyecto_id, modalidad, monto, fecha_vigencia, activa, created_at, updated_at)
  VALUES
    (v_tarifa_semanal_id,   v_tenant_id, v_proyecto_id, 'SEMANAL',   v_monto_semanal,   '2026-01-01', true, v_now, v_now),
    (v_tarifa_quincenal_id, v_tenant_id, v_proyecto_id, 'QUINCENAL', v_monto_quincenal, '2026-01-01', true, v_now, v_now),
    (v_tarifa_mensual_id,   v_tenant_id, v_proyecto_id, 'MENSUAL',   v_monto_mensual,   '2026-01-01', true, v_now, v_now)
  ON CONFLICT (id) DO UPDATE SET
    modalidad = EXCLUDED.modalidad,
    monto = EXCLUDED.monto,
    activa = true;

  -- ── 8. Montos Predefinidos ───────────────────────────────
  INSERT INTO montos_predefinidos (id, tenant_id, proyecto_id, monto, descripcion, activo, orden, created_at, updated_at)
  VALUES
    (gen_random_uuid(), v_tenant_id, v_proyecto_id, v_monto_semanal,   'Pago semanal',   true, 1, v_now, v_now),
    (gen_random_uuid(), v_tenant_id, v_proyecto_id, v_monto_quincenal, 'Pago quincenal', true, 2, v_now, v_now),
    (gen_random_uuid(), v_tenant_id, v_proyecto_id, v_monto_mensual,   'Pago mensual',   true, 3, v_now, v_now)
  ON CONFLICT DO NOTHING;

  -- ── 9. Planes de Cobro ───────────────────────────────────
  INSERT INTO planes_de_cobro (id, casa_id, residente_id, tenant_id, proyecto_id, modalidad, valor_mensual, fecha_activacion, activa, created_at, updated_at)
  VALUES
    (v_plan1_id, v_casa1_e1_ma_id, v_camilo_id, v_tenant_id, v_proyecto_id, 'SEMANAL',   NULL, '2026-09-01', true, v_now, v_now),
    (v_plan2_id, v_casa1_e1_mb_id, v_carmen_id, v_tenant_id, v_proyecto_id, 'QUINCENAL', NULL, '2026-09-01', true, v_now, v_now),
    (v_plan3_id, v_casa1_e2_ma_id, v_yhon_id,   v_tenant_id, v_proyecto_id, 'MENSUAL',   NULL, '2026-09-01', true, v_now, v_now)
  ON CONFLICT (id) DO UPDATE SET
    modalidad = EXCLUDED.modalidad,
    activa = true;

  -- ── 10. Usuarios ─────────────────────────────────────────
  INSERT INTO usuarios (id, email, password_hash, nombre, rol, residente_id, tenant_id, activo, created_at, updated_at)
  VALUES
    (v_user_admin_id,
     'admin',
     v_hash_admin,
     'Admin Cívica',
     'ADMIN',
     NULL,
     v_tenant_id, true, v_now, v_now)
  ON CONFLICT (email) DO UPDATE SET
    password_hash = v_hash_admin, nombre = 'Admin Cívica', rol = 'ADMIN';

  INSERT INTO usuarios (id, email, password_hash, nombre, rol, residente_id, tenant_id, activo, created_at, updated_at)
  VALUES
    (v_user_cobrador_id,
     'ricardoarrietacobrador',
     v_hash_cobrador,
     'Ricardo Arrieta',
     'COBRADOR',
     NULL,
     v_tenant_id, true, v_now, v_now)
  ON CONFLICT (email) DO UPDATE SET
    password_hash = v_hash_cobrador, nombre = 'Ricardo Arrieta', rol = 'COBRADOR';

  INSERT INTO usuarios (id, email, password_hash, nombre, rol, residente_id, tenant_id, activo, created_at, updated_at)
  VALUES
    (v_user_camilo_id,
     'manzana_a_casa_1_residente',
     v_hash_camilo,
     'Camilo Silva',
     'RESIDENTE',
     v_camilo_id,
     v_tenant_id, true, v_now, v_now)
  ON CONFLICT (email) DO UPDATE SET
    password_hash = v_hash_camilo, nombre = 'Camilo Silva', residente_id = v_camilo_id;

  INSERT INTO usuarios (id, email, password_hash, nombre, rol, residente_id, tenant_id, activo, created_at, updated_at)
  VALUES
    (v_user_carmen_id,
     'manzana_b_casa_1_residente',
     v_hash_carmen,
     'Carmen Cabarca',
     'RESIDENTE',
     v_carmen_id,
     v_tenant_id, true, v_now, v_now)
  ON CONFLICT (email) DO UPDATE SET
    password_hash = v_hash_carmen, nombre = 'Carmen Cabarca', residente_id = v_carmen_id;

  INSERT INTO usuarios (id, email, password_hash, nombre, rol, residente_id, tenant_id, activo, created_at, updated_at)
  VALUES
    (v_user_yhon_id,
     'etapa_2_manzana_a_casa_1_residente',
     v_hash_yhon,
     'Yhon Barrios',
     'RESIDENTE',
     v_yhon_id,
     v_tenant_id, true, v_now, v_now)
  ON CONFLICT (email) DO UPDATE SET
    password_hash = v_hash_yhon, nombre = 'Yhon Barrios', residente_id = v_yhon_id;

  -- ── 11. Asignaciones de Etapa al Cobrador ────────────────
  INSERT INTO asignaciones_etapa (id, usuario_id, etapa_id, tenant_id, created_at)
  VALUES
    ('c9920102-1e9f-42a2-9f24-82e48b14ee85', v_user_cobrador_id, v_etapa1_id, v_tenant_id, v_now),
    ('35843d40-11f5-4ffb-8202-69cac9ccf441', v_user_cobrador_id, v_etapa2_id, v_tenant_id, v_now)
  ON CONFLICT (usuario_id, etapa_id) DO NOTHING;

  RAISE NOTICE '═══════════════════════════════════════════════════════════';
  RAISE NOTICE '  SEED OFICIAL COMPLETADO EXITOSAMENTE';
  RAISE NOTICE '  Proyecto: Urb San Sebastian';
  RAISE NOTICE '  Admin:     admin / Admin2026!';
  RAISE NOTICE '  Cobrador:  ricardoarrietacobrador / ricardoArrieta2026.';
  RAISE NOTICE '  Residente: manzana_a_casa_1_residente / Casa1ManzanaA..';
  RAISE NOTICE '  Residente: manzana_b_casa_1_residente / Casa1ManzanaB';
  RAISE NOTICE '  Residente: etapa_2_manzana_a_casa_1_residente / Casa1ManzanaA..';
  RAISE NOTICE '═══════════════════════════════════════════════════════════';

END $$;
