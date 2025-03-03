;; ToneHaven - Music Platform Smart Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-invalid-royalty (err u104))
(define-constant err-invalid-price (err u105))
(define-constant err-empty-collaborators (err u106))
(define-constant err-duplicate-collaborator (err u107))
(define-constant err-zero-address (err u108))
(define-constant err-transfer-failed (err u109))
(define-constant minimum-price u1)

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
        price: uint,
        collaborators: (list 5 {address: principal, share: uint})
    }
)

(define-map piece-stats
    uint
    {
        plays: uint,
        likes: uint,
        revenue: uint,
        distributed-royalties: uint
    }
)

(define-map user-licenses
    {piece-id: uint, user: principal}
    {licensed: bool, timestamp: uint}
)

;; Private Functions
(define-private (distribute-royalties (collaborator {address: principal, share: uint}) (amount uint))
    (let
        (
            (royalty-amount (/ (* amount (get share collaborator)) u100))
            (recipient (get address collaborator))
        )
        (asserts! (not (is-eq recipient 'SP000000000000000000002Q6VF78)) err-zero-address)
        (if (> royalty-amount u0)
            (match (stx-transfer? royalty-amount tx-sender recipient)
                success (ok royalty-amount)
                error err-transfer-failed
            )
            (ok u0)
        )
    )
)

(define-private (validate-collaborators (collaborators (list 5 {address: principal, share: uint})))
    (let
        (
            (total-shares (fold + u0 (map get-share collaborators)))
            (unique-addresses (len (fold remove-duplicates (list) (map get-address collaborators))))
        )
        (asserts! (> (len collaborators) u0) err-empty-collaborators)
        (asserts! (is-eq (len collaborators) unique-addresses) err-duplicate-collaborator)
        (asserts! (<= total-shares u100) err-invalid-royalty)
        (ok true)
    )
)

;; Public Functions
(define-public (register-piece (title (string-utf8 100)) (ipfs-hash (string-ascii 64)) 
                             (license-type (string-ascii 20)) (price uint)
                             (collaborators (list 5 {address: principal, share: uint})))
    (let
        (
            (piece-id (var-get piece-counter))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (>= price minimum-price) err-invalid-price)
        (asserts! (is-none (map-get? pieces piece-id)) err-already-exists)
        (try! (validate-collaborators collaborators))
        
        (map-set pieces piece-id
            {
                title: title,
                artist: tx-sender,
                ipfs-hash: ipfs-hash,
                timestamp: block-height,
                license-type: license-type,
                price: price,
                collaborators: collaborators
            }
        )
        (map-set piece-stats piece-id
            {
                plays: u0,
                likes: u0,
                revenue: u0,
                distributed-royalties: u0
            }
        )
        (var-set piece-counter (+ piece-id u1))
        (ok piece-id)
    )
)

[... rest of the contract remains unchanged ...]
