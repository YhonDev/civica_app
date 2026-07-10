-- =====================================================
-- Script de limpieza COMPLETA del propietario de prueba
-- Borra TODO lo asociado a este propietario (seed + basura de testing)
-- Propietario ID: 76dd035c-f081-475b-8859-4415f533bb2f
-- Usuario ID: 55e7fe52-00c3-42d0-ba16-15952dc6e9e4
-- =====================================================

-- 1. Solicitudes (dependen de cuotas)
DELETE FROM solicitudes
WHERE usuario_id = '55e7fe52-00c3-42d0-ba16-15952dc6e9e4';

-- 2. Pagos (dependen de cuotas)
DELETE FROM pagos
WHERE propietario_id = '76dd035c-f081-475b-8859-4415f533bb2f';

-- 3. Cuotas
DELETE FROM cuotas
WHERE propietario_id = '76dd035c-f081-475b-8859-4415f533bb2f';

-- 4. Tarifas de prueba (IDs fijos del seed)
DELETE FROM tarifas WHERE id IN (
  'b0a28f80-77a8-422f-bd1a-ea045c7ebc01',
  'b0a28f80-77a8-422f-bd1a-ea045c7ebc02',
  'b0a28f80-77a8-422f-bd1a-ea045c7ebc03'
);

-- 5. Montos predefinidos de prueba
DELETE FROM montos_predefinidos WHERE id IN (
  'b0a28f80-77a8-422f-bd1a-ea045c7ebc04',
  'b0a28f80-77a8-422f-bd1a-ea045c7ebc05',
  'b0a28f80-77a8-422f-bd1a-ea045c7ebc06'
);
