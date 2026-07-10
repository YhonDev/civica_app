# Principios de Diseño y UX (Civica Pago App)

Estas son las reglas fundamentales dictadas por el diseñador del producto para la construcción de interfaces, especialmente dashboards:

## El Dashboard no es una colección de tarjetas, es una HISTORIA.
El Dashboard nunca debe ser un listado de tarjetas. Debe ser un centro de decisiones.
Cada sección responde una única pregunta y prepara al usuario para la siguiente.

### Orden de Lectura Estricto:
Toda pantalla (y en especial el Dashboard) debe seguir esta jerarquía invariable:
1. **Estado General (Hero Card)**: ¿Cómo estamos? (Ej: Recaudo del mes, Meta mensual). Nunca colocar otras tarjetas antes. [Peso: ★★★★★]
2. **Qué necesita atención (KPIs y Alertas)**: ¿Qué requiere atención? Indicadores accionables (Pagaron, Mora). Alertas solo si existen. [Peso: ★★★★☆]
3. **Qué ocurrió recientemente (Actividad)**: ¿Qué pasó hoy? Eventos relevantes, no un historial completo. [Peso: ★★★☆☆]
4. **Qué puedo hacer ahora (Acciones Rápidas)**: Acciones. NUNCA antes del contexto. [Peso: ★★★☆☆]
5. **Información de Apoyo (Gráficos, Distribución)**: ¿Cómo se comportan los datos? (Ej: Modalidades, Estado de Cobros). Siempre aparecen después porque apoyan, no deciden. [Peso: ★★☆☆☆]
6. **Información secundaria**: Resumen anual, estadísticas generales. Nunca arriba. [Peso: ★☆☆☆☆]

### Regla de Oro:
El Dashboard no reemplaza los módulos. Solo resume.
Cada tarjeta debe terminar con una posibilidad: Ver más, Abrir, Consultar, Gestionar.
El Dashboard es una puerta de entrada, no el destino final.

### Preguntas antes que Datos:
Las tarjetas deben responder preguntas, no mostrar datos sueltos.
- ❌ `184` (Mal)
- ✅ `¿Cuántos propietarios ya pagaron? 184` (Bien, o su equivalente con diseño contextualizado).
