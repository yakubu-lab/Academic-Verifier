# Academic Credential Verification Smart Contract

## Overview

The Academic Credential Verification Smart Contract is a blockchain-based solution designed to enable transparent tracking of educational achievements and institutional validations. This contract provides a secure, immutable system for managing academic credentials from enrollment through certification.

## Features

- **Credential Issuance**: Issue new academic credentials with initial status tracking
- **Status Management**: Update credential status throughout the academic journey
- **Progress Tracking**: Maintain a complete history of credential status changes
- **Institutional Validation**: Allow approved educational institutions to validate credentials
- **Verification System**: Verify the legitimacy of academic credentials
- **Access Control**: Role-based permissions for different operations

## Contract Architecture

### Core Components

#### Data Structures

- **credential-ledger**: Maps credential IDs to student information, current status, and progress history
- **credential-validations**: Tracks validations from educational institutions
- **educational-institutions**: Registry of approved educational institutions

#### Status Constants

- `STATUS_ENROLLED` (1): Student is enrolled in the program
- `STATUS_VALIDATED` (2): Credential has been validated by institution
- `STATUS_AWARDED` (3): Academic achievement has been awarded
- `STATUS_CERTIFIED` (4): Final certification has been granted

#### Validation Type Constants

- `VALIDATION_UNIVERSITY` (1): University-level validation
- `VALIDATION_ACCREDITOR` (2): Accreditation body validation
- `VALIDATION_MINISTRY` (3): Ministry of Education validation
- `VALIDATION_BOARD` (4): Professional board validation

## Public Functions

### Credential Management

#### `issue-credential`
```clarity
(issue-credential (credential-id uint) (initial-status uint)) -> (response bool uint)
```
Issues a new academic credential with specified ID and initial status.

**Parameters:**
- `credential-id`: Unique identifier for the credential (1-1000000)
- `initial-status`: Initial status of the credential

**Authorization:** Contract registrar or student (for STATUS_ENROLLED only)

#### `update-credential-status`
```clarity
(update-credential-status (credential-id uint) (new-status uint)) -> (response bool uint)
```
Updates the status of an existing credential and adds entry to progress history.

**Parameters:**
- `credential-id`: Credential identifier
- `new-status`: New status to be assigned

**Authorization:** Contract registrar or credential owner

### Validation Management

#### `add-validation`
```clarity
(add-validation (credential-id uint) (validation-type uint)) -> (response bool uint)
```
Adds institutional validation to a credential.

**Parameters:**
- `credential-id`: Credential identifier
- `validation-type`: Type of validation being added

**Authorization:** Approved educational institutions only

#### `revoke-validation`
```clarity
(revoke-validation (credential-id uint) (validation-type uint)) -> (response bool uint)
```
Revokes an existing validation for a credential.

**Parameters:**
- `credential-id`: Credential identifier
- `validation-type`: Type of validation to revoke

**Authorization:** Contract registrar or original validator

### Administrative Functions

#### `add-educational-institution`
```clarity
(add-educational-institution (validator principal) (validation-type uint)) -> (response bool uint)
```
Registers an educational institution as an approved validator.

**Parameters:**
- `validator`: Principal address of the institution
- `validation-type`: Type of validation the institution can perform

**Authorization:** Contract registrar only

## Read-Only Functions

### Query Functions

#### `get-credential-progress`
```clarity
(get-credential-progress (credential-id uint)) -> (response (list 10 {status: uint, timestamp: uint}) uint)
```
Returns the complete progress history of a credential.

#### `get-credential-status`
```clarity
(get-credential-status (credential-id uint)) -> (response uint uint)
```
Returns the current status of a credential.

#### `verify-credential-legitimacy`
```clarity
(verify-credential-legitimacy (credential-id uint) (validation-type uint)) -> (response bool uint)
```
Verifies if a credential has been legitimately validated by an approved institution.

#### `get-validation-details`
```clarity
(get-validation-details (credential-id uint) (validation-type uint)) -> (response (optional {validator: principal, timestamp: uint, confirmed: bool}) uint)
```
Returns detailed information about a specific validation.

## Error Codes

- `ERR_UNAUTHORIZED` (1): Caller lacks required permissions
- `ERR_INVALID_CREDENTIAL` (2): Invalid credential ID or credential not found
- `ERR_STATUS_UPDATE_FAILED` (3): Status update operation failed
- `ERR_INVALID_STATUS` (4): Invalid status value provided
- `ERR_INVALID_VALIDATION` (5): Invalid validation type or validation not found
- `ERR_VALIDATION_EXISTS` (6): Validation already exists for this credential

## Usage Examples

### Issuing a New Credential
```clarity
;; Student enrolls in a program
(contract-call? .academic-credential-verification issue-credential u12345 STATUS_ENROLLED)
```

### Updating Credential Status
```clarity
;; Update to validated status
(contract-call? .academic-credential-verification update-credential-status u12345 STATUS_VALIDATED)
```

### Adding Institutional Validation
```clarity
;; University validates the credential
(contract-call? .academic-credential-verification add-validation u12345 VALIDATION_UNIVERSITY)
```

### Verifying Credential Legitimacy
```clarity
;; Check if credential has university validation
(contract-call? .academic-credential-verification verify-credential-legitimacy u12345 VALIDATION_UNIVERSITY)
```

## Security Features

### Access Control
- Contract registrar has administrative privileges
- Students can only issue credentials with STATUS_ENROLLED
- Only approved educational institutions can add validations
- Validators can revoke their own validations

### Data Validation
- Credential IDs must be within valid range (1-1000000)
- Status values must be one of the predefined constants
- Validation types must be predefined constants
- Progress history is limited to 10 entries per credential

### Anti-Fraud Measures
- Duplicate validations are prevented
- Invalid validator principals are rejected
- Comprehensive input validation on all parameters

## Deployment Instructions

1. Deploy the contract to the Stacks blockchain
2. Set up the contract registrar (automatically set to deployer)
3. Register approved educational institutions using `add-educational-institution`
4. Begin issuing credentials to students

## Integration Guidelines

### For Educational Institutions
1. Register with the contract registrar to become an approved validator
2. Use `add-validation` to validate student credentials
3. Monitor validation status through read-only functions

### For Students
1. Issue credentials using `issue-credential` with STATUS_ENROLLED
2. Update status as you progress through your program
3. Track progress using `get-credential-progress`

### For Employers/Verifiers
1. Use `verify-credential-legitimacy` to check credential validity
2. Review progress history with `get-credential-progress`
3. Verify current status with `get-credential-status`

## Technical Requirements

- Stacks blockchain environment
- Clarity smart contract support
- Valid principal addresses for all participants
