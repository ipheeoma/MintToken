# MintToken NFT Marketplace Smart Contract

A decentralized NFT marketplace smart contract built on Stacks blockchain using Clarity programming language. MintToken allows users to mint, list, buy, and sell NFT collectibles in a secure and decentralized manner.

## Features

- **NFT Minting**: Create unique digital collectibles
- **Marketplace Trading**: List and purchase NFTs with STX tokens
- **Owner Controls**: Administrative functions for marketplace management
- **Sale Management**: Create, modify, and terminate sales
- **Vendor Tracking**: Monitor sales activity per vendor

## Smart Contract Overview

The MintToken smart contract implements a complete NFT marketplace with the following core functionalities:

### NFT Management
- Mint new collectibles (owner only)
- Track ownership and transfers
- Unique asset identification system

### Marketplace Operations
- List NFTs for sale with custom pricing
- Purchase listed NFTs with STX transfers
- Modify sale prices
- Cancel active sales
- Marketplace suspension/reactivation controls

### Security Features
- Owner-only administrative functions
- Ownership verification for all operations
- Forbidden address restrictions
- Zero-amount protection
- Marketplace state management

## Contract Functions

### Public Functions

#### NFT Creation
```clarity
(create-collectible (beneficiary principal))
```
Creates a new NFT and assigns it to the specified beneficiary. Only the contract owner can mint new collectibles.

#### Sale Management
```clarity
(establish-sale (asset-id uint) (cost uint))
```
Creates a new sale listing for an owned NFT at the specified price.

```clarity
(terminate-sale (sale-id uint))
```
Cancels an active sale listing. Only the NFT owner can terminate their sales.

```clarity
(modify-sale-cost (sale-id uint) (updated-cost uint))
```
Updates the price of an existing sale listing.

#### Purchasing
```clarity
(purchase-collectible (sale-id uint))
```
Purchases an NFT from an active sale listing. Transfers STX to the seller and NFT to the buyer.

#### Administrative Controls
```clarity
(suspend-marketplace)
(reactivate-marketplace)
```
Owner-only functions to suspend or reactivate the entire marketplace.

### Read-Only Functions

```clarity
(fetch-next-sale-id)           ; Get next available sale ID
(fetch-next-asset-id)          ; Get next available asset ID
(fetch-sale-info (sale-id))    ; Get sale details
(fetch-total-sales)            ; Get total number of sales
(fetch-vendor-sales-count (vendor)) ; Get vendor's active sales count
(fetch-collectible-holder (asset-id)) ; Get NFT owner
(count-available-sales)        ; Count available sales
```

## Error Codes

| Code | Description |
|------|-------------|
| u100 | Unauthorized access |
| u101 | Invalid ownership |
| u102 | Sale not found |
| u103 | Zero amount error |
| u104 | Nonexistent asset |
| u105 | Forbidden address |
| u106 | Invalid user |
| u107 | Marketplace inactive |

## Data Structures

### Sale Record
```clarity
{
  asset-id: uint,
  cost: uint,
  vendor: principal,
  state: (string-ascii 20)  ; "available", "completed", "terminated"
}
```

## Usage Examples

### Deploying the Contract
Deploy the contract to Stacks blockchain using Clarinet or other Stacks development tools.

### Minting an NFT
```clarity
(contract-call? .minttoken create-collectible 'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KX975CN7QKC0)
```

### Creating a Sale
```clarity
(contract-call? .minttoken establish-sale u1 u1000000) ; Sell asset #1 for 1 STX
```

### Purchasing an NFT
```clarity
(contract-call? .minttoken purchase-collectible u0) ; Buy sale #0
```

### Checking Sale Information
```clarity
(contract-call? .minttoken fetch-sale-info u0)
```

## Development Setup

### Testing
Create comprehensive tests covering:
- NFT minting functionality
- Sale creation and management
- Purchase transactions
- Error conditions
- Administrative functions

### Deployment
1. Configure your deployment settings in `Clarinet.toml`
2. Deploy to testnet for testing
3. Deploy to mainnet for production use

## Security Considerations

- **Owner Privileges**: The contract owner has significant control over marketplace operations
- **Address Validation**: Forbidden addresses are blocked from receiving NFTs
- **State Management**: Proper checks ensure marketplace integrity
- **Transfer Security**: STX and NFT transfers are atomic and secure

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add comprehensive tests for new functionality
4. Submit a pull request
