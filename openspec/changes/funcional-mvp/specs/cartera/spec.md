# Spec: Cartera

## Requirements

### Role-Based Cuota Access
`GET /cuotas` SHALL accept optional `etapaId`, `manzana`, `status` query parameters.
COBRADOR results SHALL be scoped to assigned etapas.

### Role-Aware Frontend Routing
`CarteraScreen` SHALL offer calendar/list toggle.
Calendar MUST use `table_calendar` with green/yellow/red status badges.
List SHALL sort by `fechaVencimiento`.
Toggling views SHALL NOT trigger extra API calls.

### Cartera Consolidated View
Unified view SHALL show all residents and their payment status.
Admin SHALL see all residents.
Cobrador SHALL only see residents in assigned etapas.

## Scenarios

### Scenario: Admin filters cuotas
Given an authenticated Admin
When requesting `GET /cuotas?etapaId=1&status=vencido`
Then the response SHALL contain only cuotas belonging to Etapa 1 with status VENCIDA.

### Scenario: Cobrador accesses cuotas
Given an authenticated Cobrador assigned to Etapa 1 and Etapa 2
When requesting `GET /cuotas`
Then the response SHALL contain only cuotas belonging to Etapa 1 and Etapa 2.

### Scenario: Toggle view does not call API
Given a resident on `CarteraScreen` with cached cuota data
When the resident toggles between calendar and list view
Then the application SHALL NOT make any network request.
