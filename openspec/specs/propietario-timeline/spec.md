# Propietario Timeline Specification

## Purpose

Provide propietarios with a chronological timeline of their pagos and solicitudes, mirroring the AMI admin dashboard's activity feed but scoped to a single propietario's data. This replaces the minimal 2-movement view with a rich, paginated activity timeline.

## Requirements

### Requirement: Timeline Endpoint Returns Combined Pagos + Solicitudes

The backend SHALL expose a `GET /dashboard/propietario/timeline` endpoint that returns pagos and solicitudes for the authenticated propietario, ordered by date descending.

The endpoint MUST require authentication and MUST verify the caller is a propietario.

#### Scenario: Authenticated propietario fetches timeline

- GIVEN a propietario is authenticated
- WHEN they request `GET /dashboard/propietario/timeline`
- THEN the response contains a merged list of pago and solicitud items
- AND items are ordered by date descending (most recent first)
- AND each item includes: `type` (PAGO | SOLICITUD), `date`, `monto` (only for PAGO), `description`, `estado`

#### Scenario: Propietario with no records gets empty timeline

- GIVEN an authenticated propietario with no pagos or solicitudes
- WHEN they request the timeline endpoint
- THEN the response returns an empty array with HTTP 200

#### Scenario: Unauthenticated request is rejected

- GIVEN no authentication token
- WHEN the timeline endpoint is requested
- THEN the response returns HTTP 401

### Requirement: Timeline Pagination

The backend MUST support offset-based pagination with a `limit` parameter (default 20) and an `offset` parameter (default 0).

The response MUST include a `hasMore` boolean indicating additional pages exist.

#### Scenario: First page returns default page size

- GIVEN a propietario with 50 total records
- WHEN they request the timeline without offset/limit
- THEN the response contains 20 items
- AND `hasMore` is `true`

#### Scenario: Next page fetches subsequent records

- GIVEN a propietario with 50 total records
- WHEN they request the timeline with `offset=20&limit=20`
- THEN the response contains 20 items (items 21-40)
- AND `hasMore` is `true`

#### Scenario: Last page returns remaining records

- GIVEN a propietario with 25 total records
- WHEN they request the timeline with `offset=20`
- THEN the response contains 5 items
- AND `hasMore` is `false`

### Requirement: TimelineItemDto Shape

Each timeline entry MUST conform to the `TimelineItemDto`:

| Field | Type | Notes |
|-------|------|-------|
| `id` | string | Unique identifier (UUID) |
| `type` | enum | `PAGO` or `SOLICITUD` |
| `date` | ISO 8601 string | When the event occurred |
| `monto` | number \| null | Amount in COP, only present when `type` is `PAGO` |
| `description` | string | Human-readable description |
| `estado` | string | Current status of the item |

#### Scenario: Pago item has monto

- GIVEN a pago record with monto 150000
- WHEN it appears in the timeline
- THEN the item has `type: "PAGO"`, `monto: 150000`, and a description like "Pago de cuota"

#### Scenario: Solicitud item omits monto

- GIVEN a solicitud record
- WHEN it appears in the timeline
- THEN the item has `type: "SOLICITUD"`, `monto: null`

### Requirement: PropietarioDashboardScreen Displays Timeline

The frontend SHALL display a `PropietarioDashboardScreen` at route `/dashboard-propietario` showing the timeline as a scrollable list.

Pagos SHALL render with label format: "Pagaste ${monto} COP". Solicitudes SHALL render with label format: "Solicitaste cobro".

The screen MUST NOT display the "Hoy" summary block, cobrador names, or actividad data.

#### Scenario: Propietario sees populated timeline

- GIVEN a propietario with pagos and solicitudes
- WHEN they navigate to `/dashboard-propietario`
- THEN a scrollable timeline displays all items newest-first
- AND pago items show "Pagaste $X COP" with date
- AND solicitud items show "Solicitaste cobro" with date

#### Scenario: Screen loads from route

- GIVEN the app router
- WHEN navigating to `/dashboard-propietario`
- THEN `PropietarioDashboardScreen` renders with timeline data

#### Scenario: Loading state during fetch

- GIVEN the timeline is being fetched
- WHEN the screen is visible
- THEN a loading indicator is shown until data arrives

### Requirement: Timeline Supports Infinite Scroll Pagination

The frontend SHALL load more timeline items when the user scrolls to the bottom of the list (infinite scroll pattern).

#### Scenario: User scrolls to bottom triggers next page

- GIVEN 40 total timeline items, first 20 loaded
- WHEN the user scrolls to the bottom of the list
- THEN the next 20 items are fetched and appended
- AND `hasMore` becomes `false` after the last page

#### Scenario: No more items to load

- GIVEN all timeline items are loaded
- WHEN the user scrolls to the bottom
- THEN no additional network request is made
