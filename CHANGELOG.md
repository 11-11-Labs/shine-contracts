# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.0.2] - Unreleased

### Added

#### Orchestrator
- Integrated `OwnableRoles` for role-based access control.
  - Added `API_ROLE` for API address management.
  - Introduced `ORCHESTRATOR_IDENTIFIER` for unique orchestrator identification.
- added `registerAlbumAndSongs` function to allow a registrationof an album and its songs in a single transaction.

### Changed

#### Orchestrator
- Updated constructor to accept an `_apiAddress` parameter and grant `API_ROLE` to it.
- Changed terrible typo in `chnageBasicData` function name to `changeBasicData` (すみません:c).

## [0.0.1] - 2026-03-22

Initial release of the Shine smart contracts — the decentralized backbone of the Shine music marketplace.

### Added

#### Smart Contracts

- **UserDB**: User and artist registry contract with profile management, balance tracking, purchase history, and moderation controls.
- **SongDB**: Immutable song records contract with ownership tracking, purchase/gift/refund flows, and metadata management.
- **AlbumDB**: Album management contract supporting bundled songs, special editions with limited supply, and full purchase lifecycle.
- **SplitterDB**: Revenue splitting contract using basis points system for configurable multi-recipient payment distribution.
- **Orchestrator**: Central business logic hub coordinating all database contracts, enforcing business rules, and handling payments.
  - User & artist registration and profile management.
  - Fund management: deposits, withdrawals, donations.
  - Song management: registration, metadata updates, revenue split configuration, purchaseability and price controls, purchases, and gifts.
  - Album management: registration, metadata updates, revenue split configuration, purchaseability and price controls, purchases, and gifts.
  - Platform fee collection (basis points).
  - Operational breaker flags (`shopOperations`, `depositOperations`, `userRegistration`, `contentRegistration`) enforced at runtime via modifiers; initialized to active at deployment.
  - Time-locked stablecoin address upgrade mechanism (1-day timelock).
  - Orchestrator migration: `migrateOrchestrator()` transfers ownership of all DB contracts to a new orchestrator address.
  - Fee distribution: `withdrawCollectedFees()` and `giveCollectedFeesToUser()`.

#### Libraries & Interfaces

- **Orchestrator Libraries**: `ErrorsLib`, `EventsLib`, and `StructsLib` for shared error definitions, events, and data structures.
- **IdUtils Library**: Unique sequential ID generation utility for all entities.
- **IERC20 Interface**: Minimal ERC-20 interface for stablecoin interactions.

#### Deployment & Tooling

- **Deployment scripts**: `Deploy.s.sol` (mainnet/testnet) and `DeployAnvil.s.sol` (local development).
- **Makefile**: Commands for testnet, mainnet, and Anvil deployments, unit tests, and price checks.
- **Foundry configuration**: `foundry.toml` with IR pipeline, optimizer (200 runs), and custom remappings.
- **Environment template**: `.env.example` for RPC URLs and Etherscan API key.

#### Testing

- **Unit tests**: Happy path and revert condition tests for all database and orchestrator contracts.
- **Fuzz tests**: Property-based tests for album, song, user, and administrative operations.
- **Test constants**: Shared `Constants.sol` for consistent test account setup.

#### Documentation & Community

- **README**: Comprehensive project overview, architecture diagrams, setup instructions, and usage examples.
- **CONTRIBUTING.md**: Development workflow, code style standards, testing guidelines, commit conventions, and AI tool disclosure policy.
- **SECURITY.md**: Vulnerability reporting process, scope definitions, response timeline, and disclosure policy.
- **CODE_OF_CONDUCT.md**: Contributor Covenant v2.0 for community standards.
- **LICENSE**: SHINE-PPL-1.0 (Shine Protocol Public License) — non-commercial use permitted, commercial use requires partnership.

#### GitHub Templates

- **Bug report template**: Structured issue form with severity levels, affected contracts, reproduction steps, and AI tool disclosure.
- **Feature request template**: Proposal form with scope selection, gas considerations, and contribution willingness.
- **Issue config**: Links to security policy and support resources; blank issues disabled.

### Architecture

- **Database + Orchestrator pattern**: Immutable database contracts (UserDB, SongDB, AlbumDB, SplitterDB) owned by an upgradeable Orchestrator.
- **Ownable access control**: Each database sealed under its Orchestrator; migration path for future versions.
- **Basis points system**: All percentages calculated as `uint16` basis points (10,000 bp = 100%).
- **Event-driven**: All state changes emit events for off-chain indexing and transparency.
