;; MintToken NFT Marketplace Smart Contract

;; Constants
(define-constant minttoken-owner tx-sender)
(define-constant error-unauthorized-access (err u100))
(define-constant error-invalid-ownership (err u101))
(define-constant error-sale-not-found (err u102))
(define-constant error-zero-amount (err u103))
(define-constant error-nonexistent-asset (err u104))
(define-constant error-forbidden-address (err u105))
(define-constant error-invalid-user (err u106))
(define-constant error-marketplace-inactive (err u107))

;; Data variables
(define-data-var minttoken-next-sale-id uint u0)
(define-data-var minttoken-next-asset-id uint u0)
(define-data-var minttoken-suspended bool false)

;; Define the NFT
(define-non-fungible-token minttoken-collectible uint)

;; Define sale status enum
(define-data-var minttoken-state (string-ascii 20) "available")

;; Data structure for sales
(define-map minttoken-marketplace
  uint
  {
    asset-id: uint,
    cost: uint,
    vendor: principal,
    state: (string-ascii 20)
  }
)

;; Read-only function to get the next sale ID
(define-read-only (fetch-next-sale-id)
  (var-get minttoken-next-sale-id)
)

;; Read-only function to get the next asset ID
(define-read-only (fetch-next-asset-id)
  (var-get minttoken-next-asset-id)
)

;; Function to create a new sale
(define-public (establish-sale (asset-id uint) (cost uint))
  (let
    (
      (holder (unwrap! (nft-get-owner? minttoken-collectible asset-id) error-nonexistent-asset))
      (sale-id (var-get minttoken-next-sale-id))
    )
    (asserts! (is-eq tx-sender holder) error-invalid-ownership)
    (asserts! (> cost u0) error-zero-amount)
    (asserts! (not (var-get minttoken-suspended)) error-marketplace-inactive)
    (map-set minttoken-marketplace sale-id {asset-id: asset-id, cost: cost, vendor: tx-sender, state: "available"})
    (var-set minttoken-next-sale-id (+ sale-id u1))
    (ok sale-id)
  )
)

;; Function to terminate a sale
(define-public (terminate-sale (sale-id uint))
  (let
    (
      (sale-record (unwrap! (map-get? minttoken-marketplace sale-id) error-sale-not-found))
      (holder (unwrap! (nft-get-owner? minttoken-collectible (get asset-id sale-record)) error-nonexistent-asset))
    )
    (asserts! (is-eq tx-sender holder) error-invalid-ownership)
    (asserts! (is-eq (get state sale-record) "available") error-marketplace-inactive)
    (ok (map-set minttoken-marketplace sale-id 
      (merge sale-record {state: "terminated"})))
  )
)

;; Function to suspend all sales (only owner)
(define-public (suspend-marketplace)
  (begin
    (asserts! (is-eq tx-sender minttoken-owner) error-unauthorized-access)
    (var-set minttoken-suspended true)
    (ok true)
  )
)

;; Function to reactivate all sales (only owner)
(define-public (reactivate-marketplace)
  (begin
    (asserts! (is-eq tx-sender minttoken-owner) error-unauthorized-access)
    (var-set minttoken-suspended false)
    (ok true)
  )
)

;; Function to modify the cost of a sale
(define-public (modify-sale-cost (sale-id uint) (updated-cost uint))
  (let
    (
      (sale-record (unwrap! (map-get? minttoken-marketplace sale-id) error-sale-not-found))
      (holder (unwrap! (nft-get-owner? minttoken-collectible (get asset-id sale-record)) error-nonexistent-asset))
    )
    (asserts! (is-eq tx-sender holder) error-invalid-ownership)
    (asserts! (> updated-cost u0) error-zero-amount)
    (asserts! (is-eq (get state sale-record) "available") error-marketplace-inactive)
    (ok (map-set minttoken-marketplace sale-id 
      (merge sale-record {cost: updated-cost})))
  )
)

;; Read-only function to get sale details
(define-read-only (fetch-sale-info (sale-id uint))
  (map-get? minttoken-marketplace sale-id)
)

;; Function to purchase an NFT
(define-public (purchase-collectible (sale-id uint))
  (let
    (
      (sale-record (unwrap! (map-get? minttoken-marketplace sale-id) error-sale-not-found))
      (purchaser tx-sender)
      (vendor (get vendor sale-record))
      (cost (get cost sale-record))
      (asset-id (get asset-id sale-record))
    )
    (asserts! (is-some (nft-get-owner? minttoken-collectible asset-id)) error-nonexistent-asset)
    (asserts! (is-eq (unwrap! (nft-get-owner? minttoken-collectible asset-id) error-nonexistent-asset) vendor) error-invalid-ownership)
    (asserts! (is-eq (get state sale-record) "available") error-marketplace-inactive)
    (try! (stx-transfer? cost purchaser vendor))
    (try! (nft-transfer? minttoken-collectible asset-id vendor purchaser))
    (map-set minttoken-marketplace sale-id (merge sale-record {state: "completed"}))
    (ok true)
  )
)

;; Read-only function to get the total number of sales
(define-read-only (fetch-total-sales)
  (var-get minttoken-next-sale-id)
)

;; Create a new NFT (only owner can do this)
(define-public (create-collectible (beneficiary principal))
  (let
    (
      (asset-id (var-get minttoken-next-asset-id))
    )
    (asserts! (is-eq tx-sender minttoken-owner) error-unauthorized-access)
    (asserts! (not (is-eq beneficiary 'SP000000000000000000002Q6VF78)) error-forbidden-address)
    (try! (nft-mint? minttoken-collectible asset-id beneficiary))
    (var-set minttoken-next-asset-id (+ asset-id u1))
    (ok asset-id)
  )
)

;; Count available sales manually (fallback version)
(define-read-only (count-available-sales)
  (let
    (
      (maximum-id (var-get minttoken-next-sale-id))
      (total-count u0)
    )
    (ok total-count) ;; Placeholder logic
  )
)

;; Track available sales per vendor
(define-map minttoken-vendor-count principal uint)

;; Private increment
(define-private (increase-vendor-sales (vendor principal))
  (let ((current-tally (default-to u0 (map-get? minttoken-vendor-count vendor))))
    (map-set minttoken-vendor-count vendor (+ current-tally u1))
  )
)

;; Private decrement
(define-private (decrease-vendor-sales (vendor principal))
  (let ((current-tally (default-to u0 (map-get? minttoken-vendor-count vendor))))
    (map-set minttoken-vendor-count vendor (- current-tally u1))
  )
)

;; Read-only available sale count per vendor
(define-read-only (fetch-vendor-sales-count (vendor principal))
  (default-to u0 (map-get? minttoken-vendor-count vendor))
)

;; Get holder of a given NFT asset
(define-read-only (fetch-collectible-holder (asset-id uint))
  (nft-get-owner? minttoken-collectible asset-id)
)