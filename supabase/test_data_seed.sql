-- =====================================================
-- Seed de datos reales para pruebas del Propietario (Juan Pérez)
-- Propietario ID: 76dd035c-f081-475b-8859-4415f533bb2f
-- Tenant ID: aeb25e74-8b70-43c8-9789-48b337fd6093
-- Cobrador ID: 6631075b-7ef8-4549-b931-4ffb05376aef (Carlos Gómez)
-- Propietario Usuario ID: 55e7fe52-00c3-42d0-ba16-15952dc6e9e4
--
-- Hoy: 10 julio 2026
-- Frecuencia: MENSUAL ($40.000/mes = 4.000.000 centavos)
-- Historia: 5 meses pagados (Feb-Jun) + Julio PAGADO + Agosto PENDIENTE
-- =====================================================

-- ═══════════════════════════════════════════════════════
-- LIMPIEZA AGRESIVA — Borra TODO lo del propietario
-- ═══════════════════════════════════════════════════════
DELETE FROM solicitudes WHERE usuario_id = '55e7fe52-00c3-42d0-ba16-15952dc6e9e4';
DELETE FROM pagos WHERE propietario_id = '76dd035c-f081-475b-8859-4415f533bb2f';
DELETE FROM cuotas WHERE propietario_id = '76dd035c-f081-475b-8859-4415f533bb2f';

-- ═══════════════════════════════════════════════════════
-- 0. Tarifas vigentes ($40.000/mes por casa)
-- ═══════════════════════════════════════════════════════
INSERT INTO tarifas (id, tenant_id, conjunto_id, frecuencia, monto, fecha_vigencia, activa) VALUES
('b0a28f80-77a8-422f-bd1a-ea045c7ebc01', 'aeb25e74-8b70-43c8-9789-48b337fd6093',
  (SELECT id FROM conjuntos WHERE tenant_id = 'aeb25e74-8b70-43c8-9789-48b337fd6093' LIMIT 1),
  'MENSUAL', 4000000, '2026-01-01', true),
('b0a28f80-77a8-422f-bd1a-ea045c7ebc02', 'aeb25e74-8b70-43c8-9789-48b337fd6093',
  (SELECT id FROM conjuntos WHERE tenant_id = 'aeb25e74-8b70-43c8-9789-48b337fd6093' LIMIT 1),
  'QUINCENAL', 2000000, '2026-01-01', true),
('b0a28f80-77a8-422f-bd1a-ea045c7ebc03', 'aeb25e74-8b70-43c8-9789-48b337fd6093',
  (SELECT id FROM conjuntos WHERE tenant_id = 'aeb25e74-8b70-43c8-9789-48b337fd6093' LIMIT 1),
  'SEMANAL', 1000000, '2026-01-01', true)
ON CONFLICT (id) DO UPDATE SET
  monto = EXCLUDED.monto,
  activa = EXCLUDED.activa;

-- ═══════════════════════════════════════════════════════
-- 0b. Montos predefinidos para cobrador
-- ═══════════════════════════════════════════════════════
INSERT INTO montos_predefinidos (id, tenant_id, conjunto_id, monto, descripcion, activo, orden) VALUES
('b0a28f80-77a8-422f-bd1a-ea045c7ebc04', 'aeb25e74-8b70-43c8-9789-48b337fd6093',
  (SELECT id FROM conjuntos WHERE tenant_id = 'aeb25e74-8b70-43c8-9789-48b337fd6093' LIMIT 1),
  1000000, 'Cuota semanal', true, 1),
('b0a28f80-77a8-422f-bd1a-ea045c7ebc05', 'aeb25e74-8b70-43c8-9789-48b337fd6093',
  (SELECT id FROM conjuntos WHERE tenant_id = 'aeb25e74-8b70-43c8-9789-48b337fd6093' LIMIT 1),
  2000000, 'Cuota quincenal', true, 2),
('b0a28f80-77a8-422f-bd1a-ea045c7ebc06', 'aeb25e74-8b70-43c8-9789-48b337fd6093',
  (SELECT id FROM conjuntos WHERE tenant_id = 'aeb25e74-8b70-43c8-9789-48b337fd6093' LIMIT 1),
  4000000, 'Cuota mensual', true, 3)
ON CONFLICT (id) DO UPDATE SET
  monto = EXCLUDED.monto,
  activo = EXCLUDED.activo;

-- ═══════════════════════════════════════════════════════
-- 0c. Cuenta de cartera del propietario (MENSUAL)
-- ═══════════════════════════════════════════════════════
INSERT INTO cuentas_cartera (id, propietario_id, tenant_id, conjunto_id, frecuencia, fecha_activacion, activa) VALUES
('b0a28f80-77a8-422f-bd1a-ea045c7ebc07', '76dd035c-f081-475b-8859-4415f533bb2f', 'aeb25e74-8b70-43c8-9789-48b337fd6093',
  (SELECT id FROM conjuntos WHERE tenant_id = 'aeb25e74-8b70-43c8-9789-48b337fd6093' LIMIT 1),
  'MENSUAL', '2026-01-01', true)
ON CONFLICT (propietario_id) DO UPDATE SET
  frecuencia = EXCLUDED.frecuencia,
  activa = EXCLUDED.activa;

-- ═══════════════════════════════════════════════════════
-- 1. CUOTAS (Feb 2026 – Ago 2026)
--    Feb-Jul: PAGADAS ($40.000 pagado)
--    Ago: PENDIENTE (saldo $40.000)
--    Vencimientos calculados con sábado cercano al fin de mes
-- ═══════════════════════════════════════════════════════
INSERT INTO cuotas (id, propietario_id, tenant_id, concepto, monto, monto_pagado, periodo_inicio, periodo_fin, fecha_vencimiento, estado, notificacion_enviada, tarifa_id) VALUES
-- Febrero 2026 — Pagada
('f0a28f80-77a8-422f-bd1a-ea045c7ebc02', '76dd035c-f081-475b-8859-4415f533bb2f', 'aeb25e74-8b70-43c8-9789-48b337fd6093',
 'Administración Febrero 2026', 4000000, 4000000, '2026-02-01', '2026-03-01', '2026-02-28', 'PAGADA', true, 'b0a28f80-77a8-422f-bd1a-ea045c7ebc01'),
-- Marzo 2026 — Pagada
('f0a28f80-77a8-422f-bd1a-ea045c7ebc03', '76dd035c-f081-475b-8859-4415f533bb2f', 'aeb25e74-8b70-43c8-9789-48b337fd6093',
 'Administración Marzo 2026', 4000000, 4000000, '2026-03-01', '2026-04-01', '2026-03-28', 'PAGADA', true, 'b0a28f80-77a8-422f-bd1a-ea045c7ebc01'),
-- Abril 2026 — Pagada
('f0a28f80-77a8-422f-bd1a-ea045c7ebc04', '76dd035c-f081-475b-8859-4415f533bb2f', 'aeb25e74-8b70-43c8-9789-48b337fd6093',
 'Administración Abril 2026', 4000000, 4000000, '2026-04-01', '2026-05-01', '2026-04-25', 'PAGADA', true, 'b0a28f80-77a8-422f-bd1a-ea045c7ebc01'),
-- Mayo 2026 — Pagada
('f0a28f80-77a8-422f-bd1a-ea045c7ebc05', '76dd035c-f081-475b-8859-4415f533bb2f', 'aeb25e74-8b70-43c8-9789-48b337fd6093',
 'Administración Mayo 2026', 4000000, 4000000, '2026-05-01', '2026-06-01', '2026-05-30', 'PAGADA', true, 'b0a28f80-77a8-422f-bd1a-ea045c7ebc01'),
-- Junio 2026 — Pagada
('f0a28f80-77a8-422f-bd1a-ea045c7ebc06', '76dd035c-f081-475b-8859-4415f533bb2f', 'aeb25e74-8b70-43c8-9789-48b337fd6093',
 'Administración Junio 2026', 4000000, 4000000, '2026-06-01', '2026-07-01', '2026-06-27', 'PAGADA', true, 'b0a28f80-77a8-422f-bd1a-ea045c7ebc01'),
-- Julio 2026 — Pagada (mes actual, ya pagó)
('f0a28f80-77a8-422f-bd1a-ea045c7ebc07', '76dd035c-f081-475b-8859-4415f533bb2f', 'aeb25e74-8b70-43c8-9789-48b337fd6093',
 'Administración Julio 2026', 4000000, 4000000, '2026-07-01', '2026-08-01', '2026-07-25', 'PAGADA', true, 'b0a28f80-77a8-422f-bd1a-ea045c7ebc01'),
-- Agosto 2026 — PENDIENTE (próximo pago)
('f0a28f80-77a8-422f-bd1a-ea045c7ebc08', '76dd035c-f081-475b-8859-4415f533bb2f', 'aeb25e74-8b70-43c8-9789-48b337fd6093',
 'Administración Agosto 2026', 4000000, 0, '2026-08-01', '2026-09-01', '2026-08-29', 'PENDIENTE', false, 'b0a28f80-77a8-422f-bd1a-ea045c7ebc01');

-- ═══════════════════════════════════════════════════════
-- 2. PAGOS (uno por cada cuota pagada Feb-Jul)
-- ═══════════════════════════════════════════════════════
INSERT INTO pagos (id, client_payment_id, tenant_id, cuota_id, monto, fecha_pago, cobrador_id, propietario_id, sync_status) VALUES
('c0a28f80-77a8-422f-bd1a-ea045c7ebc02', 'cl-feb-2026', 'aeb25e74-8b70-43c8-9789-48b337fd6093',
 'f0a28f80-77a8-422f-bd1a-ea045c7ebc02', 4000000, '2026-02-10', '6631075b-7ef8-4549-b931-4ffb05376aef', '76dd035c-f081-475b-8859-4415f533bb2f', 'SYNCED'),
('c0a28f80-77a8-422f-bd1a-ea045c7ebc03', 'cl-mar-2026', 'aeb25e74-8b70-43c8-9789-48b337fd6093',
 'f0a28f80-77a8-422f-bd1a-ea045c7ebc03', 4000000, '2026-03-10', '6631075b-7ef8-4549-b931-4ffb05376aef', '76dd035c-f081-475b-8859-4415f533bb2f', 'SYNCED'),
('c0a28f80-77a8-422f-bd1a-ea045c7ebc04', 'cl-apr-2026', 'aeb25e74-8b70-43c8-9789-48b337fd6093',
 'f0a28f80-77a8-422f-bd1a-ea045c7ebc04', 4000000, '2026-04-10', '6631075b-7ef8-4549-b931-4ffb05376aef', '76dd035c-f081-475b-8859-4415f533bb2f', 'SYNCED'),
('c0a28f80-77a8-422f-bd1a-ea045c7ebc05', 'cl-may-2026', 'aeb25e74-8b70-43c8-9789-48b337fd6093',
 'f0a28f80-77a8-422f-bd1a-ea045c7ebc05', 4000000, '2026-05-10', '6631075b-7ef8-4549-b931-4ffb05376aef', '76dd035c-f081-475b-8859-4415f533bb2f', 'SYNCED'),
('c0a28f80-77a8-422f-bd1a-ea045c7ebc06', 'cl-jun-2026', 'aeb25e74-8b70-43c8-9789-48b337fd6093',
 'f0a28f80-77a8-422f-bd1a-ea045c7ebc06', 4000000, '2026-06-10', '6631075b-7ef8-4549-b931-4ffb05376aef', '76dd035c-f081-475b-8859-4415f533bb2f', 'SYNCED'),
('c0a28f80-77a8-422f-bd1a-ea045c7ebc07', 'cl-jul-2026', 'aeb25e74-8b70-43c8-9789-48b337fd6093',
 'f0a28f80-77a8-422f-bd1a-ea045c7ebc07', 4000000, '2026-07-05', '6631075b-7ef8-4549-b931-4ffb05376aef', '76dd035c-f081-475b-8859-4415f533bb2f', 'SYNCED');

-- ═══════════════════════════════════════════════════════
-- 3. SOLICITUD de revisión (vinculada a la cuota de Agosto)
--    El propietario reporta que pagó en efectivo pero no se cargó
-- ═══════════════════════════════════════════════════════
INSERT INTO solicitudes (id, tenant_id, usuario_id, cuota_id, nro_recibo, tipo, descripcion, estado, fecha) VALUES
('a0a28f80-77a8-422f-bd1a-ea045c7ebc08', 'aeb25e74-8b70-43c8-9789-48b337fd6093',
 '55e7fe52-00c3-42d0-ba16-15952dc6e9e4',
 'f0a28f80-77a8-422f-bd1a-ea045c7ebc08',
 'TK-948271',
 'Revisión pago de Agosto 2026',
 'Hice el pago en efectivo y no se cargó correctamente.',
 'EN_REVISION',
 '2026-07-08 10:00:00+00');
