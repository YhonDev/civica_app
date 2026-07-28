# Spec: Etapa Assignment

## Requirements

### Etapa Assignment Management
`DELETE /usuarios/:id/etapas/:etapaId` SHALL remove the assignment (soft delete).
`POST /usuarios/:id/etapas` SHALL accept `{etapaIds: []}` for batch assignment.
Mobile admin interface SHALL expose a multi-select etapa screen.

## Scenarios

### Scenario: Unassign an etapa from a cobrador
Given a cobrador with assigned Etapa 1 and Etapa 2
When the admin requests `DELETE /usuarios/:id/etapas/1`
Then the cobrador's assignment to Etapa 1 SHALL be soft-deleted.

### Scenario: Batch assign etapas to a cobrador
Given a cobrador with no assigned etapas
When the admin requests `POST /usuarios/:id/etapas` with `{etapaIds: [1, 2]}`
Then the cobrador SHALL be assigned to Etapa 1 and Etapa 2.
