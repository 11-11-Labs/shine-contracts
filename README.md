# Shine Smart Contracts

![Solidity](https://img.shields.io/badge/Solidity-^0.8.20-blue)
![License](https://img.shields.io/badge/License-SHINE--PPL--1.0-red)
![Foundry](https://img.shields.io/badge/Framework-Foundry-orange)
![Version](https://img.shields.io/badge/Version-0.0.1%20"99%20Steps"-brightgreen)

> The blockchain backbone powering **Shine** a decentralized music marketplace that empowers artists and listeners through direct connections, fair compensation, and transparency. These smart contracts serve as an immutable source of truth for the entire ecosystem, ensuring permanent records, true ownership, and data resilience. Even if the Shine platform disappears, users can always recover their music purchases, artist histories, royalties, and transaction records from the blockchain.

## Overview

These smart contracts provide the decentralized foundation for the Shine music platform, featuring:

- **Permanent Records**: Immutable on-chain database of songs, albums, artists, and users
- **True Ownership**: Users genuinely own their digital music purchases
- **Artist Support**: Native royalty tracking and balance management for musicians
- **Platform Resilience**: Source of truth persists even if the main platform goes offline
- **Upgradeable Architecture**: Ability to deploy new Orchestrator versions without losing data

## Architecture

The Shine contracts follow a **Database + Orchestrator** pattern:

```
┌─────────────────────────────────────────┐
│      Orchestrator (v1, v2, v3...)       │
│  (Business Logic & User Interface)      │
└─────────────────────────────────────────┘
           │         │         │         │
           │         │         │         └─→ ISplitterDB
           │         │         └─→ ISongDB
           │         └─→ IAlbumDB
           └─→ IUserDB

    Each Database:
    • Sealed under Ownable pattern
    • Only accessible via current Orchestrator (owner)
    • Permanent, immutable records
    • Can point to new Orchestrator versions
```

### Database Contracts

#### **UserDB** - User & Artist Registry
- Stores user and artist profiles and metadata
- Tracks user balances and accumulated royalties (for artists)
- Manages user wallet addresses
- Tracks user purchase history
- Supports user/artist banning/unbanning
- Unified account system for both listeners and creators

```solidity
key features:
├── register() - Register new user/artist
├── changeBasicData() - Update profile
├── changeAddress() - Transfer account to new address
├── addBalance() / deductBalance() - Financial tracking
├── addAccumulatedRoyalties() / deductAccumulatedRoyalties() - Royalty tracking (artists)
├── addSong() / deleteSong() - Purchase history management
├── addSongs() / deleteSongs() - Batch purchase history management
└── setBannedStatus() - Moderation control
```

#### **AlbumDB** - Album Management
- Stores album metadata (title, artist, songs, pricing)
- Tracks purchases and gifts by user
- Manages special editions with limited supply
- Supports album banning (removed from platform)
- Emits events for all state changes

```solidity
key features:
├── register() - Create new album
├── purchase() - Record user purchase
├── gift() - Record gifted album
├── refund() - Handle refunds
└── ban/unban - Moderation
```

#### **SongDB** - Song Records
- Stores individual song metadata
- Tracks song ownership (purchased/gifted)
- Manages song availability and pricing
- Supports song banning
- Links to artist information

```solidity
key features:
├── register() - Create new song
├── purchase() - Record purchase
├── gift() - Record gift
├── refund() - Handle refunds
└── ban/unban - Moderation
```

#### **SplitterDB** - Revenue Splitting
- Manages revenue split configurations
- Distributes earnings among multiple artists/users
- Uses basis points for precise percentage calculations (10000 bp = 100%)
- Ensures split configurations always sum to 100%
- Supports both song-level and user-level splits

```solidity
key features:
├── set() - Configure split for song/user
├── getSplits() - Retrieve split configuration
└── calculateSplit() - Calculate distribution amounts
```

### Orchestrator Contract

**Orchestrator.sol** - Central Business Logic Hub
- Coordinates all database interactions
- Enforces business rules and access control
- Manages stablecoin payments and fees
- Handles complex multi-contract transactions
- Implements royalty distribution

```solidity
key features:
├── Registration & Profile Management
│   ├── register() - Register users/artists
│   ├── chnageBasicData() - Update profiles
│   └── changeAddress() - Transfer accounts
│
├── Fund Management
│   ├── depositFunds() - Add funds to account
│   ├── depositFundsToAnotherUser() - Gift funds
│   ├── makeDonation() - Direct artist donations
│   └── withdrawFunds() - Withdraw earnings
│
├── Song Management
│   ├── registerSong() - Register new songs
│   ├── changeSongFullData() - Update song metadata
│   ├── changeSplitOfSong() - Update song revenue split
│   ├── changeSongPurchaseability() - Toggle song availability
│   ├── changeSongPrice() - Update song price
│   ├── purchaseSong() - Buy individual songs
│   └── giftSong() - Gift music to users
│
├── Album Management
│   ├── registerAlbum() - Register new albums
│   ├── changeAlbumFullData() - Update album metadata
│   ├── changeSplitOfAlbum() - Update album revenue split
│   ├── changeAlbumPurchaseability() - Toggle album availability
│   ├── changeAlbumPrice() - Update album price
│   ├── purchaseAlbum() - Buy full albums
│   └── giftAlbum() - Gift albums
│
└── Admin Functions
    ├── setDatabaseAddresses() - Initialize DB contract addresses (one-time)
    ├── changePercentageFee() - Update platform fee
    ├── Stablecoin management (with 1-day timelock)
    │   ├── proposeStablecoinAddressChange()
    │   ├── cancelStablecoinAddressChange()
    │   └── executeStablecoinAddressChange()
    ├── migrateOrchestrator() - Transfer all DB ownership to new orchestrator
    ├── withdrawCollectedFees() - Withdraw platform fees to external address
    └── giveCollectedFeesToUser() - Credit platform fees to a user account
```

## Data Flow Example: Song Purchase

```
User calls:
  Orchestrator.purchaseSong(songId, userId)
         ↓
Orchestrator validates:
  • Song exists & not banned
  • User exists & not banned
  • User hasn't already owned
  • Sufficient stablecoin balance
         ↓
Orchestrator calls SongDB.purchase()
  → SongDB marks ownership
  → SongDB increments purchase counter
  → SongDB emits Purchased event
         ↓
Orchestrator calls UserDB.addSong()
  → UserDB adds to purchase history
  → UserDB emits SongListChangedSingle event
         ↓
Orchestrator handles payment:
  • Calculate: net price + platform fee
  • Deduct from user balance
  • Check SplitterDB for revenue splits
  • Distribute to artist(s) via UserDB.addBalance()
  • Collect platform fee
         ↓
Transaction complete
Immutable record created on blockchain
```

## Key Features

### Permanent Records
- All data stored permanently on-chain
- Immutable transaction history
- Accessible even if platform UI disappears
- True decentralized source of truth

### Access Control
- **Ownable Pattern**: Each database sealed under its Orchestrator
- **Role-Based**: Users, artists, admin all have distinct permissions
- **Upgradeable**: Point databases to new Orchestrator without data loss

### Data Integrity
- Unique ID generation via `IdUtils` (sequential, collision-proof)
- Ownership tracking (purchased vs. gifted)
- Purchase counters and timestamps
- Event logging for all state changes

### Platform Resilience
- **Immutable Databases**: Can never be destroyed
- **Migration Path**: Deploy new Orchestrator, redirect pointers
- **Proxy Alternative**: Or implement proxy pattern for direct logic updates
- **Community Recovery**: Anyone can query data even if official platform goes down

## Setup & Development

### Prerequisites
- Foundry installed: https://book.getfoundry.sh/getting-started/installation
- Solidity ^0.8.20

### Installation

```bash
# Clone repository
git clone <repository-url>
cd Shine_contracts

# Install dependencies
forge install

# Build contracts
forge build
```

### Building

```shell
$ forge build
```

### Testing

```shell
$ forge test
```

Run specific tests:
```shell
$ forge test --match-contract AlbumDB
$ forge test --match-path test/uint/correct/*.sol -v
```

### Code Quality

Format code:
```shell
$ forge fmt
```

### Gas Analysis

Generate gas snapshots:
```shell
$ forge snapshot
```

### Local Development

Start local Ethereum node:
```shell
$ anvil
```

Deploy locally:
```shell
$ forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast
```

### Deployment

Deploy to network:
```shell
$ forge script script/Deploy.s.sol:DeployScript \
  --rpc-url <your_rpc_url> \
  --private-key <your_private_key> \
  --broadcast
```

## Contract License

This project uses the **SHINE-PPL-1.0** (Shine Platform Partnership License), a custom license that:
- Allows deployment and use of Shine
- Requires partnerships for commercial use
- Protects the Shine brand and ecosystem
- Ensures fair compensation for platform development

## Project Structure

```
Shine_contracts/
├── src/
│   ├── contracts/
│   │   ├── database/
│   │   │   ├── AlbumDB.sol      # Album management
│   │   │   ├── SongDB.sol       # Song records
│   │   │   ├── SplitterDB.sol   # Revenue splitting
│   │   │   └── UserDB.sol       # User & artist profiles
│   │   └── orchestrator/
│   │       ├── Orchestrator.sol # Central logic hub
│   │       └── library/
│   │           ├── ErrorsLib.sol
│   │           ├── EventsLib.sol
│   │           └── StructsLib.sol
│   └── library/
│       ├── IdUtils.sol          # Sequential ID generation
│       └── IERC20.sol           # ERC20 interface
│
├── test/
│   ├── uint/                    # Unit tests
│   │   ├── correct/             # Happy path tests
│   │   └── revert/              # Revert condition tests
│   └── fuzz/                    # Fuzzing tests
│
├── script/
│   └── Deploy.s.sol             # Deployment scripts
│
├── lib/
│   ├── forge-std/               # Foundry standard library
│   └── solady/                  # Optimized Solady utilities
│
├── foundry.toml                 # Foundry configuration
├── Makefile                     # Convenient make commands
└── README.md                    # This file
```

## Deployment Considerations

### Orchestrator Initialization
1. Deploy Orchestrator with initial owner, stablecoin, and fee %
2. Deploy AlbumDB, SongDB, UserDB, SplitterDB with Orchestrator address as owner
3. Call `setDatabaseAddresses()` on the Orchestrator (one-time operation)

### Migration Strategy (Future)
1. Deploy new Orchestrator version with improved logic
2. Point all databases to new Orchestrator
3. OR implement proxy pattern for direct logic updates
4. Historical data remains intact and queryable

## Use Cases

### For Users
- Purchase songs and albums permanently
- Gift music to other users
- View complete purchase history
- Recover purchase records from blockchain even if platform down

### For Artists
- Register as users with artist capabilities
- Track accumulated royalties
- Configure revenue splits for collaborations
- Withdraw earnings to blockchain address
- Maintain permanent record of published works

### For Platform
- Decentralized source of truth
- Fee collection and reporting
- User/artist banning for moderation
- Graceful upgrades through new Orchestrator versions

## External Dependencies

- **Solady** (`@solady/auth/Ownable.sol`): Optimized Ownable implementation
- **Foundry Std** (`forge-std`): Testing and scripting utilities
- **ERC20 Interface**: Standard token interactions

## License

SHINE-PPL-1.0 (Shine Platform Partnership License)

## Contributing

Contributions welcome! Please ensure:
- All tests pass (`forge test`)
- Code formatted (`forge fmt`)
- Comments documented
- No unsafe patterns
- Gas-optimized where possible

## Support

For questions or issues:
- Check existing documentation
- Review contract comments and NatSpec
- Examine test files for usage examples
- Contact 11:11 Labs

---


```
   Made with ❤️ by 11:11 Labs   
⣿⡇⣿⣿⣿⠛⠁⣴⣿⡿⠿⠧⠹⠿⠘⣿⣿⣿⡇⢸⡻⣿⣿⣿⣿⣿⣿⣿
⢹⡇⣿⣿⣿⠄⣞⣯⣷⣾⣿⣿⣧⡹⡆⡀⠉⢹⡌⠐⢿⣿⣿⣿⡞⣿⣿⣿
⣾⡇⣿⣿⡇⣾⣿⣿⣿⣿⣿⣿⣿⣿⣄⢻⣦⡀⠁⢸⡌⠻⣿⣿⣿⡽⣿⣿
⡇⣿⠹⣿⡇⡟⠛⣉⠁⠉⠉⠻⡿⣿⣿⣿⣿⣿⣦⣄⡉⠂⠈⠙⢿⣿⣝⣿
⠤⢿⡄⠹⣧⣷⣸⡇⠄⠄⠲⢰⣌⣾⣿⣿⣿⣿⣿⣿⣶⣤⣤⡀⠄⠈⠻⢮
⠄⢸⣧⠄⢘⢻⣿⡇⢀⣀⠄⣸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⡀⠄⢀
⠄⠈⣿⡆⢸⣿⣿⣿⣬⣭⣴⣿⣿⣿⣿⣿⣿⣿⣯⠝⠛⠛⠙⢿⡿⠃⠄⢸
⠄⠄⢿⣿⡀⣿⣿⣿⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣿⣿⣿⣿⡾⠁⢠⡇⢀
⠄⠄⢸⣿⡇⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣏⣫⣻⡟⢀⠄⣿⣷⣾
⠄⠄⢸⣿⡇⠄⠈⠙⠿⣿⣿⣿⣮⣿⣿⣿⣿⣿⣿⣿⣿⡿⢠⠊⢀⡇⣿⣿
⠒⠤⠄⣿⡇⢀⡲⠄⠄⠈⠙⠻⢿⣿⣿⠿⠿⠟⠛⠋⠁⣰⠇⠄⢸⣿⣿⣿
```