# Historial Specification

## Purpose

Provide payment history access to all roles. PROPIETARIO uses the same filtered endpoint as Cartera to view their own cuotas with payment history.

## Requirements

### Requirement: Propietario Historial Access

The system SHALL allow PROPIETARIO role to access `GET /cuotas/propietario/:propietarioId` for historial views.

#### Scenario: Propietario views historial

- GIVEN a PROPIETARIO is authenticated
- WHEN the propietario navigates to Historial
- THEN the app fetches cuotas from `GET /cuotas/propietario/:propietarioId`
- AND the response contains cuotas with payment history data for that propietario only

#### Scenario: Propietario historial endpoint authorization

- GIVEN a PROPIETARIO is authenticated
- WHEN the propietario calls `GET /cuotas/propietario/:propietarioId`
- THEN the request succeeds with a 200 response
- AND only cuotas belonging to the authenticated propietario are returned
