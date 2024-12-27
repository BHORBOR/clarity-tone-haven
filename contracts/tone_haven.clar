;; ToneHaven - Music Platform Smart Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))

;; Data Variables
(define-data-var piece-counter uint u0)

;; Data Maps
(define-map pieces
    uint 
    {
        title: (string-utf8 100),
        artist: principal,
        ipfs-hash: (string-ascii 64),
        timestamp: uint,
        license-type: (string-ascii 20),
        price: uint
    }
)

(define-map piece-stats
    uint
    {
        plays: uint,
        likes: uint,
        revenue: uint
    }
)

(define-map user-licenses
    {piece-id: uint, user: principal}
    {licensed: bool, timestamp: uint}
)

;; Public Functions
(define-public (register-piece (title (string-utf8 100)) (ipfs-hash (string-ascii 64)) (license-type (string-ascii 20)) (price uint))
    (let
        (
            (piece-id (var-get piece-counter))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set pieces piece-id
            {
                title: title,
                artist: tx-sender,
                ipfs-hash: ipfs-hash,
                timestamp: block-height,
                license-type: license-type,
                price: price
            }
        )
        (map-set piece-stats piece-id
            {
                plays: u0,
                likes: u0,
                revenue: u0
            }
        )
        (var-set piece-counter (+ piece-id u1))
        (ok piece-id)
    )
)

(define-public (purchase-license (piece-id uint))
    (let
        (
            (piece (unwrap! (map-get? pieces piece-id) err-not-found))
            (stats (unwrap! (map-get? piece-stats piece-id) err-not-found))
        )
        (asserts! (is-some (map-get? pieces piece-id)) err-not-found)
        (try! (stx-transfer? (get price piece) tx-sender (get artist piece)))
        (map-set piece-stats piece-id
            (merge stats {revenue: (+ (get revenue stats) (get price piece))})
        )
        (map-set user-licenses {piece-id: piece-id, user: tx-sender}
            {licensed: true, timestamp: block-height}
        )
        (ok true)
    )
)

(define-public (like-piece (piece-id uint))
    (let
        (
            (stats (unwrap! (map-get? piece-stats piece-id) err-not-found))
        )
        (map-set piece-stats piece-id
            (merge stats {likes: (+ (get likes stats) u1)})
        )
        (ok true)
    )
)

;; Read-only functions
(define-read-only (get-piece-details (piece-id uint))
    (ok (map-get? pieces piece-id))
)

(define-read-only (get-piece-stats (piece-id uint))
    (ok (map-get? piece-stats piece-id))
)

(define-read-only (check-license (piece-id uint) (user principal))
    (ok (map-get? user-licenses {piece-id: piece-id, user: user}))
)