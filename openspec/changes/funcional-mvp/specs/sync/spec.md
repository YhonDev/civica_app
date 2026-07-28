# Spec: Sync

## Requirements

### Sync Conflict Detection
HTTP 409 during sync SHALL call `PagoDao.marcarConflicto()` and set `syncStatus` to `CONFLICTO`.
A 409 status SHALL NOT be treated as success.
Network errors SHALL NOT stop processing remaining payments in the queue.

### Conflict Alert and Retry
A conflict alert SHALL display count and a retry button.
Retry SHALL use exponential backoff: 1s, 2s, 4s, 8s, 16s, with a maximum of 5 attempts.

## Scenarios

### Scenario: Detect HTTP 409 Conflict
Given a pending local payment
When the sync process receives HTTP 409 response
Then the payment's local `syncStatus` SHALL be set to `CONFLICTO`.

### Scenario: Continue sync after network error
Given multiple pending local payments
When payment #1 fails due to a network error
Then the sync process SHALL proceed to attempt payment #2 and #3.

### Scenario: Retry with exponential backoff
Given payments in CONFLICTO status
When the user clicks the retry button
Then the retry attempts SHALL execute at 1s, 2s, 4s, 8s, and 16s intervals.
