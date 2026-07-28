# Spec: Residente Inline Registration

## Requirements

### Residente Inline Registration
A bottom sheet SHALL display during the payment flow when a casa has no residente.
The sheet SHALL require `nombre`, `telefono`, and `modalidadPago`, with `email` being optional.
After successful creation, the payment flow SHALL automatically resume with the new residente.

## Scenarios

### Scenario: Missing required fields
Given the Residente Inline bottom sheet is open
When the user submits the form with empty `nombre`
Then the form SHALL show a validation error and prevent the API call.

### Scenario: Successful inline registration resumes flow
Given a payment flow for a casa with no resident
When the user fills and submits the inline registration form
Then the residente SHALL be created and the payment confirmation flow SHALL resume.
