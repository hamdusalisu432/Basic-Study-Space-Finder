;; Study Space Finder Contract
;; Basic location sharing system for students during exam periods

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_SPACE_NOT_FOUND (err u101))
(define-constant ERR_INVALID_NOISE_LEVEL (err u102))

(define-data-var space-id-nonce uint u0)

(define-map study-spaces
  uint
  {
    owner: principal,
    location: (string-ascii 100),
    amenities: (string-ascii 200),
    noise-level: uint,
    available: bool,
    created-at: uint
  }
)

(define-map space-by-owner
  principal
  (list 10 uint)
)

(define-public (add-study-space (location (string-ascii 100)) (amenities (string-ascii 200)) (noise-level uint))
  (let ((new-id (+ (var-get space-id-nonce) u1)))
    (asserts! (<= noise-level u5) ERR_INVALID_NOISE_LEVEL)
    (map-set study-spaces new-id
      {
        owner: tx-sender,
        location: location,
        amenities: amenities,
        noise-level: noise-level,
        available: true,
        created-at: stacks-block-height
      })
    (map-set space-by-owner tx-sender
      (unwrap-panic (as-max-len?
        (append (default-to (list) (map-get? space-by-owner tx-sender)) new-id)
        u10)))
    (var-set space-id-nonce new-id)
    (ok new-id)))

(define-public (update-availability (space-id uint) (available bool))
  (let ((space (unwrap! (map-get? study-spaces space-id) ERR_SPACE_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get owner space)) ERR_UNAUTHORIZED)
    (map-set study-spaces space-id (merge space {available: available}))
    (ok true)))

(define-public (update-noise-level (space-id uint) (new-noise-level uint))
  (let ((space (unwrap! (map-get? study-spaces space-id) ERR_SPACE_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get owner space)) ERR_UNAUTHORIZED)
    (asserts! (<= new-noise-level u5) ERR_INVALID_NOISE_LEVEL)
    (map-set study-spaces space-id (merge space {noise-level: new-noise-level}))
    (ok true)))

(define-read-only (get-study-space (space-id uint))
  (map-get? study-spaces space-id))

(define-read-only (get-spaces-by-owner (owner principal))
  (map-get? space-by-owner owner))

(define-read-only (get-total-spaces)
  (var-get space-id-nonce))
