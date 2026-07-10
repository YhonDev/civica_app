# Admin Dashboard — Spec

## Change
Implementar el Dashboard del Administrador con endpoint de agregaciones y UI moderna según DESIGN_SYSTEM.md y ROLE_DASHBOARDS.md.

---

## Scope

### Backend
- Nuevo endpoint `GET /dashboard/administrador?mes=8&anio=2026`
- DashboardQuery — use case que agrega datos de pagos, cuotas y cuentas
- DTO de respuesta con todas las métricas
- Tabla `actividad` para el feed de eventos recientes
- Decorador/evento para registrar actividad automáticamente en use cases clave

### Flutter
- Sistema de diseño: tema personalizado (colores, tipografía, componentes según DESIGN_SYSTEM.md)
- DashboardScreen con:
  - Selector de mes tipo Apple Calendar (◄ ► chips + bottom sheet)
  - Tarjeta principal: Recaudo del Mes con barra de progreso
  - Mini indicadores: Pagaron, Pendientes, Mora
  - Gráfico de línea: Evolución del recaudo
  - Estado por modalidad (Mensual/Quincenal/Semanal)
  - Gráfico donut: Estado de cobros
  - Timeline: Actividad reciente
  - Acciones rápidas
- DashboardCubit para manejo de estado
- DashboardRepository para llamadas al API
- Componentes reutilizables: KpiCard, MiniStatCard, TimelineWidget, DonutChart, LineChart, MonthSelector, ActionCard

---

## Out of Scope
- Dashboard del Cobrador (próximo cambio)
- Dashboard del Propietario (próximo cambio)
- Módulo de Reportes (separado del dashboard)
- Edición en línea o CRUD desde el dashboard

---

## Endpoint Response Schema

```typescript
interface DashboardResponse {
  mes: number;           // 1-12
  anio: number;          // 2026
  resumen: {
    recaudoTotal: number;      // centavos
    metaMensual: number;       // centavos (suma de cuotas del período)
    porcentajeMeta: number;    // 0-100
    pagaron: number;           // cantidad propietarios
    pendientes: number;        // cantidad propietarios
    moraTotal: number;         // centavos
  };
  evolucion: Array<{
    dia: number;               // 1-31
    monto: number;             // centavos recaudados ese día
  }>;
  modalidades: Array<{
    frecuencia: string;        // MENSUAL | QUINCENAL | SEMANAL
    totalCuotas: number;
    pagadas: number;
    porcentaje: number;
  }>;
  estadoCobros: {
    pagados: number;           // porcentaje
    pendientes: number;
    revision: number;
  };
  actividad: Array<{
    id: string;
    tipo: string;              // PAGO | PROPIETARIO | REVISION | COBRADOR
    descripcion: string;
    usuario: string;
    timestamp: string;         // ISO
    hace: string;              // "hace 5 min"
  }>;
}
```

---

## Data Model — Actividad Table

```sql
CREATE TABLE actividad (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES conjuntos(id),
  tipo VARCHAR(50) NOT NULL,         -- PAGO, PROPIETARIO, REVISION, COBRADOR
  descripcion TEXT NOT NULL,
  usuario_nombre VARCHAR(255) NOT NULL,
  usuario_id UUID NOT NULL,
  metadata JSONB,                     -- datos adicionales según tipo
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_actividad_tenant_created 
  ON actividad(tenant_id, created_at DESC);
```
