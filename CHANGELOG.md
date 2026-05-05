# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.0.1] - 2026-03-22

### Added

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
- **Orchestrator Libraries**: `ErrorsLib`, `EventsLib`, and `StructsLib` for shared error definitions, events, and data structures.
- **IdUtils Library**: Unique sequential ID generation utility for all entities.
- **IERC20 Interface**: Minimal ERC-20 interface for stablecoin interactions.
- **Deployment script**: `Deploy.s.sol` for deploying the full contract suite.
- **Test suite**: Unit tests (correct behavior and revert cases) and fuzz tests for database and orchestrator contracts.
