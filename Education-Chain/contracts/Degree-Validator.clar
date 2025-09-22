;; Academic Credential Verification Smart Contract
;; Enables transparent tracking of educational achievements and institutional validations

(define-trait academic-credential-verification-trait
  (
    (issue-credential (uint uint) (response bool uint))
    (update-credential-status (uint uint) (response bool uint))
    (get-credential-progress (uint) (response (list 10 {status: uint, timestamp: uint}) uint))
    (add-validation (uint uint principal) (response bool uint))
    (verify-credential-legitimacy (uint uint) (response bool uint))
  )
)

;; Define credential status constants
(define-constant STATUS_ENROLLED u1)
(define-constant STATUS_VALIDATED u2)
(define-constant STATUS_AWARDED u3)
(define-constant STATUS_CERTIFIED u4)

;; Define validation type constants
(define-constant VALIDATION_UNIVERSITY u1)
(define-constant VALIDATION_ACCREDITOR u2)
(define-constant VALIDATION_MINISTRY u3)
(define-constant VALIDATION_BOARD u4)

;; Error constants
(define-constant ERR_UNAUTHORIZED (err u1))
(define-constant ERR_INVALID_CREDENTIAL (err u2))
(define-constant ERR_STATUS_UPDATE_FAILED (err u3))
(define-constant ERR_INVALID_STATUS (err u4))
(define-constant ERR_INVALID_VALIDATION (err u5))
(define-constant ERR_VALIDATION_EXISTS (err u6))

;; Contract registrar
(define-data-var contract-registrar principal tx-sender)

;; Current sequence counter
(define-data-var sequence-counter uint u0)

;; Academic credential tracking map
(define-map credential-ledger 
  {credential-id: uint} 
  {
    student: principal,
    current-status: uint,
    progress: (list 10 {status: uint, timestamp: uint})
  }
)

;; Validation tracking map
(define-map credential-validations
  {credential-id: uint, validation-type: uint}
  {
    validator: principal,
    timestamp: uint,
    confirmed: bool
  }
)

;; Approved educational institutions
(define-map educational-institutions
  {validator: principal, validation-type: uint}
  {accredited: bool}
)

;; Get current sequence timestamp and increment counter
(define-private (get-current-sequence-time)
  (begin
    (var-set sequence-counter (+ (var-get sequence-counter) u1))
    (var-get sequence-counter)
  )
)

;; Only contract registrar can perform certain actions
(define-read-only (is-contract-registrar (sender principal))
  (is-eq sender (var-get contract-registrar))
)

;; Validate status
(define-private (is-valid-status (status uint))
  (or 
    (is-eq status STATUS_ENROLLED)
    (is-eq status STATUS_VALIDATED)
    (is-eq status STATUS_AWARDED)
    (is-eq status STATUS_CERTIFIED)
  )
)

;; Validate validation type
(define-private (is-valid-validation-type (validation-type uint))
  (or
    (is-eq validation-type VALIDATION_UNIVERSITY)
    (is-eq validation-type VALIDATION_ACCREDITOR)
    (is-eq validation-type VALIDATION_MINISTRY)
    (is-eq validation-type VALIDATION_BOARD)
  )
)

;; Validate credential ID
(define-private (is-valid-credential-id (credential-id uint))
  (and (> credential-id u0) (<= credential-id u1000000))
)

;; Check if sender is approved educational institution
(define-private (is-educational-institution (validator principal) (validation-type uint))
  (default-to 
    false
    (get accredited (map-get? educational-institutions {validator: validator, validation-type: validation-type}))
  )
)

;; Issue a new academic credential
(define-public (issue-credential (credential-id uint) (initial-status uint))
  (begin
    (asserts! (is-valid-credential-id credential-id) ERR_INVALID_CREDENTIAL)
    (asserts! (is-valid-status initial-status) ERR_INVALID_STATUS)
    (asserts! (or (is-contract-registrar tx-sender) (is-eq initial-status STATUS_ENROLLED)) ERR_UNAUTHORIZED)
    
    (map-set credential-ledger 
      {credential-id: credential-id}
      {
        student: tx-sender,
        current-status: initial-status,
        progress: (list {status: initial-status, timestamp: (get-current-sequence-time)})
      }
    )
    (ok true)
  )
)

;; Update credential status
(define-public (update-credential-status (credential-id uint) (new-status uint))
  (let 
    (
      (credential (unwrap! (map-get? credential-ledger {credential-id: credential-id}) ERR_INVALID_CREDENTIAL))
    )
    (asserts! (is-valid-credential-id credential-id) ERR_INVALID_CREDENTIAL)
    (asserts! (is-valid-status new-status) ERR_INVALID_STATUS)
    (asserts! 
      (or 
        (is-contract-registrar tx-sender)
        (is-eq (get student credential) tx-sender)
      ) 
      ERR_UNAUTHORIZED
    )
    
    (map-set credential-ledger 
      {credential-id: credential-id}
      (merge credential 
        {
          current-status: new-status,
          progress: (unwrap-panic 
            (as-max-len? 
              (append (get progress credential) {status: new-status, timestamp: (get-current-sequence-time)}) 
              u10
            )
          )
        }
      )
    )
    (ok true)
  )
)

;; Validate validator principal
(define-private (is-valid-validator (validator principal))
  (and 
    (not (is-eq validator (var-get contract-registrar)))
    (not (is-eq validator tx-sender))
    (not (is-eq validator 'SP000000000000000000002Q6VF78))
  )
)

;; Add educational institution with additional validation
(define-public (add-educational-institution (validator principal) (validation-type uint))
  (begin
    (asserts! (is-contract-registrar tx-sender) ERR_UNAUTHORIZED)
    (asserts! (is-valid-validation-type validation-type) ERR_INVALID_VALIDATION)
    (asserts! (is-valid-validator validator) ERR_UNAUTHORIZED)
    
    (map-set educational-institutions
      {validator: validator, validation-type: validation-type}
      {accredited: true}
    )
    (ok true)
  )
)

;; Add validation to credential
(define-public (add-validation (credential-id uint) (validation-type uint))
  (begin
    (asserts! (is-valid-credential-id credential-id) ERR_INVALID_CREDENTIAL)
    (asserts! (is-valid-validation-type validation-type) ERR_INVALID_VALIDATION)
    (asserts! (is-educational-institution tx-sender validation-type) ERR_UNAUTHORIZED)
    
    (asserts! 
      (is-none 
        (map-get? credential-validations {credential-id: credential-id, validation-type: validation-type})
      )
      ERR_VALIDATION_EXISTS
    )
    
    (let
      ((validated-credential-id credential-id)
       (validated-validation-type validation-type))
      (map-set credential-validations
        {credential-id: validated-credential-id, validation-type: validated-validation-type}
        {
          validator: tx-sender,
          timestamp: (get-current-sequence-time),
          confirmed: true
        }
      )
      (ok true)
    )
  )
)

;; Verify credential legitimacy
(define-read-only (verify-credential-legitimacy (credential-id uint) (validation-type uint))
  (let
    (
      (validation (unwrap! 
        (map-get? credential-validations {credential-id: credential-id, validation-type: validation-type})
        ERR_INVALID_VALIDATION
      ))
    )
    (ok (get confirmed validation))
  )
)

;; Revoke validation
(define-public (revoke-validation (credential-id uint) (validation-type uint))
  (begin
    (asserts! (is-valid-credential-id credential-id) ERR_INVALID_CREDENTIAL)
    (asserts! (is-valid-validation-type validation-type) ERR_INVALID_VALIDATION)
    
    (let
      (
        (validation (unwrap! 
          (map-get? credential-validations {credential-id: credential-id, validation-type: validation-type})
          ERR_INVALID_VALIDATION
        ))
        (validated-credential-id credential-id)
        (validated-validation-type validation-type)
      )
      (asserts! 
        (or
          (is-contract-registrar tx-sender)
          (is-eq (get validator validation) tx-sender)
        )
        ERR_UNAUTHORIZED
      )
      
      (map-set credential-validations
        {credential-id: validated-credential-id, validation-type: validated-validation-type}
        (merge validation {confirmed: false})
      )
      (ok true)
    )
  )
)

;; Get credential progress
(define-read-only (get-credential-progress (credential-id uint))
  (let 
    (
      (credential (unwrap! (map-get? credential-ledger {credential-id: credential-id}) ERR_INVALID_CREDENTIAL))
    )
    (ok (get progress credential))
  )
)

;; Get current credential status
(define-read-only (get-credential-status (credential-id uint))
  (let 
    (
      (credential (unwrap! (map-get? credential-ledger {credential-id: credential-id}) ERR_INVALID_CREDENTIAL))
    )
    (ok (get current-status credential))
  )
)

;; Get validation details
(define-read-only (get-validation-details (credential-id uint) (validation-type uint))
  (ok (map-get? credential-validations {credential-id: credential-id, validation-type: validation-type}))
)