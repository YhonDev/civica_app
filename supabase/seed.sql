-- Seed data para pruebas manuales
-- Admin user: admin@civica.test / admin123

DO $$
DECLARE
  v_tenant_id UUID := 'aeb25e74-8b70-43c8-9789-48b337fd6093';
  v_conjunto_id UUID;
  v_etapa_id1 UUID;
  v_etapa_id2 UUID;
  v_manzana_id1 UUID;
  v_manzana_id2 UUID;
  v_casa_id1 UUID;
  v_casa_id2 UUID;
  v_propietario_id1 UUID;
  v_propietario_id2 UUID;
  v_cuota_id1 UUID;
  v_cuota_id2 UUID;
  v_cuota_id3 UUID;
BEGIN
  -- Crear admin user
  INSERT INTO usuarios (id, email, password_hash, nombre, rol, tenant_id, activo)
  VALUES (gen_random_uuid(), 'admin@civica.test', '$2b$10$Z1SgEDoYhxPYoTw2/fEuuee7QbNikPTfX2McOB02WUefpRfhBsoUu', 'Admin Test', 'ADMIN', v_tenant_id, true);

  -- Crear conjunto
  INSERT INTO conjuntos (id, nombre, tenant_id)
  VALUES (gen_random_uuid(), 'Portal del Prado', v_tenant_id)
  RETURNING id INTO v_conjunto_id;

  -- Crear etapa 1
  INSERT INTO etapas (id, nombre, conjunto_id)
  VALUES (gen_random_uuid(), 'Etapa 1', v_conjunto_id)
  RETURNING id INTO v_etapa_id1;

  -- Crear etapa 2
  INSERT INTO etapas (id, nombre, conjunto_id)
  VALUES (gen_random_uuid(), 'Etapa 2', v_conjunto_id)
  RETURNING id INTO v_etapa_id2;

  -- Crear manzana 1 en etapa 1
  INSERT INTO manzanas (id, nombre, etapa_id)
  VALUES (gen_random_uuid(), 'Manzana A', v_etapa_id1)
  RETURNING id INTO v_manzana_id1;

  -- Crear manzana 2 en etapa 2
  INSERT INTO manzanas (id, nombre, etapa_id)
  VALUES (gen_random_uuid(), 'Manzana B', v_etapa_id2)
  RETURNING id INTO v_manzana_id2;

  -- Crear casas en manzana 1
  INSERT INTO casas (id, direccion_interna, manzana_id)
  VALUES (gen_random_uuid(), 'Casa 101', v_manzana_id1)
  RETURNING id INTO v_casa_id1;

  INSERT INTO casas (id, direccion_interna, manzana_id)
  VALUES (gen_random_uuid(), 'Casa 102', v_manzana_id1)
  RETURNING id INTO v_casa_id2;

  INSERT INTO casas (id, direccion_interna, manzana_id)
  VALUES (gen_random_uuid(), 'Casa 103', v_manzana_id1);

  -- Crear casas en manzana 2
  INSERT INTO casas (id, direccion_interna, manzana_id)
  VALUES (gen_random_uuid(), 'Casa 201', v_manzana_id2);

  INSERT INTO casas (id, direccion_interna, manzana_id)
  VALUES (gen_random_uuid(), 'Casa 202', v_manzana_id2);

  -- Crear propietario 1: Juan Pérez
  INSERT INTO propietarios (id, nombre, telefono, email, tenant_id)
  VALUES (gen_random_uuid(), 'Juan Pérez', '3001234567', 'juan@email.com', v_tenant_id)
  RETURNING id INTO v_propietario_id1;

  -- Tenencia: Juan -> Casa 101
  INSERT INTO tenencias (id, propietario_id, casa_id, fecha_inicio)
  VALUES (gen_random_uuid(), v_propietario_id1, v_casa_id1, '2026-01-01');

  -- Crear cuenta de usuario (login) para Juan
  INSERT INTO usuarios (id, email, password_hash, nombre, rol, propietario_id, tenant_id, activo)
  VALUES (gen_random_uuid(), 'juan@email.com', '$2b$10$Z1SgEDoYhxPYoTw2/fEuuee7QbNikPTfX2McOB02WUefpRfhBsoUu', 'Juan Pérez', 'PROPIETARIO', v_propietario_id1, v_tenant_id, true);

  -- Crear propietario 2: María García
  INSERT INTO propietarios (id, nombre, telefono, email, tenant_id)
  VALUES (gen_random_uuid(), 'María García', '3007654321', 'maria@email.com', v_tenant_id)
  RETURNING id INTO v_propietario_id2;

  -- Tenencia: María -> Casa 102
  INSERT INTO tenencias (id, propietario_id, casa_id, fecha_inicio)
  VALUES (gen_random_uuid(), v_propietario_id2, v_casa_id2, '2026-03-01');

  -- Tarifas vigentes: $40.000/mes por casa
  INSERT INTO tarifas (tenant_id, conjunto_id, frecuencia, monto, fecha_vigencia, activa) VALUES
  (v_tenant_id, v_conjunto_id, 'MENSUAL',   4000000, '2026-01-01', true),
  (v_tenant_id, v_conjunto_id, 'QUINCENAL', 2000000, '2026-01-01', true),
  (v_tenant_id, v_conjunto_id, 'SEMANAL',   1000000, '2026-01-01', true);

  -- Montos predefinidos para cobrador
  INSERT INTO montos_predefinidos (tenant_id, conjunto_id, monto, descripcion, activo, orden) VALUES
  (v_tenant_id, v_conjunto_id, 1000000, 'Cuota semanal',   true, 1),
  (v_tenant_id, v_conjunto_id, 2000000, 'Cuota quincenal', true, 2),
  (v_tenant_id, v_conjunto_id, 4000000, 'Cuota mensual',   true, 3);

  -- =====================================
  -- FINANZAS: CUOTAS Y PAGOS (TESTING)
  -- =====================================
  -- Juan Pérez: 
  -- Mayo: Pagada
  INSERT INTO cuotas (id, propietario_id, tenant_id, tarifa_id, concepto, monto, monto_pagado, periodo_inicio, periodo_fin, fecha_vencimiento, estado)
  VALUES (gen_random_uuid(), v_propietario_id1, v_tenant_id, null, 'Cuota de Administración - Mayo 2026', 4000000, 4000000, '2026-05-01', '2026-05-31', '2026-05-15', 'PAGADA')
  RETURNING id INTO v_cuota_id1;

  INSERT INTO pagos (id, client_payment_id, tenant_id, cuota_id, monto, fecha_pago, cobrador_id, propietario_id)
  VALUES (gen_random_uuid(), 'PAGO-TEST-001', v_tenant_id, v_cuota_id1, 4000000, '2026-05-10', v_propietario_id1, v_propietario_id1);

  -- Junio: Pagada
  INSERT INTO cuotas (id, propietario_id, tenant_id, tarifa_id, concepto, monto, monto_pagado, periodo_inicio, periodo_fin, fecha_vencimiento, estado)
  VALUES (gen_random_uuid(), v_propietario_id1, v_tenant_id, null, 'Cuota de Administración - Junio 2026', 4000000, 4000000, '2026-06-01', '2026-06-30', '2026-06-15', 'PAGADA')
  RETURNING id INTO v_cuota_id2;

  INSERT INTO pagos (id, client_payment_id, tenant_id, cuota_id, monto, fecha_pago, cobrador_id, propietario_id)
  VALUES (gen_random_uuid(), 'PAGO-TEST-002', v_tenant_id, v_cuota_id2, 4000000, '2026-06-12', v_propietario_id1, v_propietario_id1);

  -- Julio: Pendiente 
  INSERT INTO cuotas (id, propietario_id, tenant_id, tarifa_id, concepto, monto, monto_pagado, periodo_inicio, periodo_fin, fecha_vencimiento, estado)
  VALUES (gen_random_uuid(), v_propietario_id1, v_tenant_id, null, 'Cuota de Administración - Julio 2026', 4000000, 0, '2026-07-01', '2026-07-31', '2026-07-15', 'PENDIENTE');

  -- María García:
  -- Mayo: Pagada
  INSERT INTO cuotas (id, propietario_id, tenant_id, tarifa_id, concepto, monto, monto_pagado, periodo_inicio, periodo_fin, fecha_vencimiento, estado)
  VALUES (gen_random_uuid(), v_propietario_id2, v_tenant_id, null, 'Cuota de Administración - Mayo 2026', 4000000, 4000000, '2026-05-01', '2026-05-31', '2026-05-15', 'PAGADA')
  RETURNING id INTO v_cuota_id3;

  INSERT INTO pagos (id, client_payment_id, tenant_id, cuota_id, monto, fecha_pago, cobrador_id, propietario_id)
  VALUES (gen_random_uuid(), 'PAGO-TEST-003', v_tenant_id, v_cuota_id3, 4000000, '2026-05-14', v_propietario_id2, v_propietario_id2);

  -- Junio: Vencida (Mora)
  INSERT INTO cuotas (id, propietario_id, tenant_id, tarifa_id, concepto, monto, monto_pagado, periodo_inicio, periodo_fin, fecha_vencimiento, estado)
  VALUES (gen_random_uuid(), v_propietario_id2, v_tenant_id, null, 'Cuota de Administración - Junio 2026', 4000000, 0, '2026-06-01', '2026-06-30', '2026-06-15', 'VENCIDA');

  -- Julio: Pendiente
  INSERT INTO cuotas (id, propietario_id, tenant_id, tarifa_id, concepto, monto, monto_pagado, periodo_inicio, periodo_fin, fecha_vencimiento, estado)
  VALUES (gen_random_uuid(), v_propietario_id2, v_tenant_id, null, 'Cuota de Administración - Julio 2026', 4000000, 0, '2026-07-01', '2026-07-31', '2026-07-15', 'PENDIENTE');

  -- Mostrar resultados
  RAISE NOTICE '=== DATOS DE PRUEBA CREADOS ===';
  RAISE NOTICE 'Admin: admin@civica.test / admin123';
  RAISE NOTICE 'Propietario Juan: juan@email.com / admin123';
  RAISE NOTICE 'Conjunto ID: % (Portal del Prado)', v_conjunto_id;
  RAISE NOTICE 'Etapa 1 ID: %', v_etapa_id1;
  RAISE NOTICE 'Etapa 2 ID: %', v_etapa_id2;
  RAISE NOTICE 'Propietario 1 ID: % (Juan Pérez - Casa 101)', v_propietario_id1;
  RAISE NOTICE 'Propietario 2 ID: % (María García - Casa 102)', v_propietario_id2;
  RAISE NOTICE '================================';
END $$;
