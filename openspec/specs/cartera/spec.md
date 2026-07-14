# Cartera Specification

## Purpose

Manage cuota visibility for all user roles. ADMIN and COBRADOR see all cuotas; PROPIETARIO sees only their own cuotas.

## Requirements

### Requirement: Role-Based Cuota Access

The system SHALL gate access to cuota endpoints based on user role: ADMIN, COBRADOR, or PROPIETARIO.

#### Scenario: Admin accesses all cuotas

- GIVEN an ADMIN is authenticated
- WHEN the admin calls `GET /cuotas`
- THEN the response contains all cuotas across all propietarios

#### Scenario: Cobrador accesses all cuotas

- GIVEN a COBRADOR is authenticated
- WHEN the cobrador calls `GET /cuotas`
- THEN the response contains all cuotas (same as ADMIN)

#### Scenario: Propietario accesses own cuotas

- GIVEN a PROPIETARIO is authenticated
- WHEN the propietario calls `GET /cuotas/propietario/:propietarioId`
- THEN the response contains only cuotas belonging to that propietario

#### Scenario: Propietario cannot access admin cuota endpoint

- GIVEN a PROPIETARIO is authenticated
- WHEN the propietario calls `GET /cuotas`
- THEN the request is rejected with a 403 Forbidden response

### Requirement: Role-Aware Frontend Routing

The mobile app router SHALL map the `/cartera` route to `CarteraScreen` for COBRADOR and PROPIETARIO roles.

#### Scenario: Cobrador navigates to cartera

- GIVEN a user with COBRADOR role navigates to `/cartera`
- WHEN the route is resolved
- THEN the `CarteraScreen` widget is displayed

#### Scenario: Propietario navigates to cartera

- GIVEN a user with PROPIETARIO role navigates to `/cartera`
- WHEN the route is resolved
- THEN the `CarteraScreen` widget is displayed

### Requirement: Role-Aware Repository

The `CarteraRepository` SHALL select the correct API endpoint based on the authenticated user's role.

#### Scenario: Repository calls correct endpoint for Propietario

- GIVEN the authenticated user has role PROPIETARIO
- WHEN `CarteraRepository` fetches cuotas
- THEN it calls `GET /cuotas/propietario/{propietarioId}` with the user's propietario ID

#### Scenario: Repository calls correct endpoint for Cobrador

- GIVEN the authenticated user has role COBRADOR
- WHEN `CarteraRepository` fetches cuotas
- THEN it calls `GET /cuotas`
