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
  - Song and album purchase flows with automatic revenue split distribution.
  - Gift and refund support for songs and albums.
  - Platform fee collection (basis points).
  - Circuit breaker controls: `shopOperations`, `depositOperations`, `userRegistration`, `contentRegistration`.
  - Time-locked stablecoin address upgrade mechanism.
  - Ban/unban moderation for users, songs, and albums.
- **Orchestrator Libraries**: `ErrorsLib`, `EventsLib`, and `StructsLib` for shared error definitions, events, and data structures.
- **IdUtils Library**: Unique sequential ID generation utility for all entities.
- **IERC20 Interface**: Minimal ERC-20 interface for stablecoin interactions.
- **Deployment script**: `SongDataBase.s.sol` for deploying the full contract suite.
- **Test suite**: Unit tests (correct behavior and revert cases) and fuzz tests for database and orchestrator contracts.
