# Propietario Info Specification

## Purpose

Provide personal information (name, address, etapa) for propietario users via the dashboard endpoint, replacing hardcoded frontend strings.

## Requirements

### Requirement: Dashboard Propietario Info

The `GET /dashboard/propietario` response SHALL include a `propietarioInfo` object containing the authenticated propietario's personal details.

#### Scenario: Propietario with linked casa and etapa

- GIVEN a propietario is authenticated and linked to a tenencia and casa
- WHEN the propietario calls `GET /dashboard/propietario`
- THEN the response includes `propietarioInfo.nombre` with the propietario's full name
- AND `propietarioInfo.casaDireccion` with the casa address
- AND `propietarioInfo.etapaNombre` with the etapa name

#### Scenario: Propietario without tenencia or casa

- GIVEN a propietario is authenticated but has no tenencia or casa linkage
- WHEN the propietario calls `GET /dashboard/propietario`
- THEN the response includes `propietarioInfo` with all fields set to empty strings or null

#### Scenario: Frontend displays dynamic propietario info

- GIVEN the user is a propietario viewing Mi Estado screen
- WHEN the dashboard response is received
- THEN the screen displays the propietario's real name, casa address, and etapa name from `propietarioInfo`
- AND no hardcoded placeholder strings are shown
