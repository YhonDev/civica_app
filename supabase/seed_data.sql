-- Seed data para pruebas manuales
-- Admin user: admin@civica.test / admin123

DO $$
DECLARE
  v_tenant_id UUID := gen_random_uuid();
  v_conjunto_id UUID;
  v_etapa_id1 UUID;
  v_etapa_id2 UUID;
  v_casa_id1 UUID;
  v_casa_id2 UUID;
  v_propietario_id1 UUID;
  v_propietario_id2 UUID;
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
  VALUES (gen_random_uuid(), 'Etapa 1 - Manzana A', v_conjunto_id)
  RETURNING id INTO v_etapa_id1;

  -- Crear etapa 2
  INSERT INTO etapas (id, nombre, conjunto_id)
  VALUES (gen_random_uuid(), 'Etapa 2 - Manzana B', v_conjunto_id)
  RETURNING id INTO v_etapa_id2;

  -- Crear casas en etapa 1
  INSERT INTO casas (id, direccion_interna, etapa_id)
  VALUES (gen_random_uuid(), 'Casa 101', v_etapa_id1)
  RETURNING id INTO v_casa_id1;

  INSERT INTO casas (id, direccion_interna, etapa_id)
  VALUES (gen_random_uuid(), 'Casa 102', v_etapa_id1)
  RETURNING id INTO v_casa_id2;

  INSERT INTO casas (id, direccion_interna, etapa_id)
  VALUES (gen_random_uuid(), 'Casa 103', v_etapa_id1);

  -- Crear casas en etapa 2
  INSERT INTO casas (id, direccion_interna, etapa_id)
  VALUES (gen_random_uuid(), 'Casa 201', v_etapa_id2);

  INSERT INTO casas (id, direccion_interna, etapa_id)
  VALUES (gen_random_uuid(), 'Casa 202', v_etapa_id2);

  -- Crear propietario 1: Juan Pérez
  INSERT INTO propietarios (id, nombre, telefono, email, tenant_id)
  VALUES (gen_random_uuid(), 'Juan Pérez', '3001234567', 'juan@email.com', v_tenant_id)
  RETURNING id INTO v_propietario_id1;

  -- Tenencia: Juan -> Casa 101
  INSERT INTO tenencias (id, propietario_id, casa_id, fecha_inicio)
  VALUES (gen_random_uuid(), v_propietario_id1, v_casa_id1, '2026-01-01');

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

  -- Mostrar resultados
  RAISE NOTICE '=== DATOS DE PRUEBA CREADOS ===';
  RAISE NOTICE 'Admin: admin@civica.test / admin123';
  RAISE NOTICE 'Conjunto ID: % (Portal del Prado)', v_conjunto_id;
  RAISE NOTICE 'Etapa 1 ID: %', v_etapa_id1;
  RAISE NOTICE 'Etapa 2 ID: %', v_etapa_id2;
  RAISE NOTICE 'Propietario 1 ID: % (Juan Pérez - Casa 101)', v_propietario_id1;
  RAISE NOTICE 'Propietario 2 ID: % (María García - Casa 102)', v_propietario_id2;
  RAISE NOTICE '================================';
END $$;
