# Contributing to Shine Smart Contracts

Thank you for considering contributing to Shine.

Shine is a transparent, resilient music platform built **by and for artists**. We believe musicians deserve direct connections with their listeners, fair compensation, and full control over their work. These smart contracts exist to make that possible.

Everything here is on-chain and open. If the platform ever goes offline, the records stay alive — your purchases, your releases, your royalties. No one can take that away. Every contribution you make helps keep this promise real.

Please read this guide thoroughly before opening a pull request. It will save time for both you and the maintainers.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Project Architecture](#project-architecture)
- [Development Workflow](#development-workflow)
- [Branch Naming](#branch-naming)
- [Code Style & Standards](#code-style--standards)
- [Testing Guidelines](#testing-guidelines)
- [Formatting](#formatting)
- [Gas Analysis](#gas-analysis)
- [Commit & Pull Request Guidelines](#commit--pull-request-guidelines)
- [Deployment Notes](#deployment-notes)
- [License Notice](#license-notice)
- [Questions & Support](#questions--support)

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- Solidity ^0.8.20
- Git

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd Shine_contracts

# Install dependencies
forge install

# Build contracts
forge build
```

## Project Architecture

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
    • Permanent and immutable — your data survives no matter what
    • Can point to new Orchestrator versions
```

### Key Directories

| Directory | Purpose |
|-----------|---------|
| `src/contracts/database/` | Immutable data storage (AlbumDB, SongDB, UserDB, SplitterDB) |
| `src/contracts/orchestrator/` | Business logic hub (Orchestrator.sol) and shared libraries |
| `src/library/` | Utilities (IdUtils.sol, IERC20.sol) |
| `test/uint/correct/` | Happy path unit tests |
| `test/uint/revert/` | Revert condition unit tests |
| `test/fuzz/` | Fuzzing tests |
| `script/` | Deployment scripts |

## Development Workflow

1. **Create a branch** from `main` (see [Branch Naming](#branch-naming))
2. **Make your changes** following our [Code Style](#code-style--standards)
3. **Format your code**: `forge fmt`
4. **Run all tests**: `forge test`
5. **Generate gas snapshot** if you modified core logic: `forge snapshot`
6. **Open a Pull Request** using our PR template/checklist

## Branch Naming

We recommend the following prefixes, but they are not strictly enforced:

| Prefix | Use case |
|--------|----------|
| `feature/` | New functionality |
| `fix/` | Bug fixes |
| `security/` | Security patches |
| `docs/` | Documentation updates |
| `refactor/` | Code refactoring without behavior change |
| `gas/` | Gas optimizations |

Example: `feature/song-collaboration-split` or `fix/album-purchase-overflow`.

## Code Style & Standards

### Licensing

- All source files under `src/` must include: `// SPDX-License-Identifier: SHINE-PPL-1.0`
- All test files under `test/` must include: `// SPDX-License-Identifier: UNLICENSED`

### NatSpec Documentation

Every contract, function, event, error, and state variable must be fully documented using [NatSpec](https://docs.soliditylang.org/en/latest/natspec-format.html):

- `@title` — Contract name and purpose
- `@author` — Author or organization
- `@notice` — Human-readable description for end users
- `@dev` — Technical details for developers
- `@param` — Description of each parameter
- `@return` — Description of return values

### Section Headers

Use decorative Unicode block-drawing comment blocks to demarcate major sections within contracts (e.g., State Variables, Modifiers, External Functions, Admin Functions).

### Basis Points

All percentages and fees are calculated in basis points where **10,000 bp = 100%**. Always use `uint16` for fee variables to save gas and prevent overflow.

### Shared Libraries

Centralize shared definitions in the orchestrator library layer:

- `ErrorsLib.sol` — Custom error definitions
- `EventsLib.sol` — Event declarations
- `StructsLib.sol` — Shared data structures

Do not duplicate errors, events, or structs across multiple contracts.

### Safety & Optimization

- **No unsafe patterns**: Avoid `delegatecall` unless absolutely necessary and thoroughly audited. No unchecked low-level calls.
- **Gas optimization**: Prefer `calldata` over `memory` for external function parameters. Use `immutable` and `constant` where possible. Minimize storage writes.
- **Access control**: Always enforce access control via modifiers. The Orchestrator is the sole owner of all database contracts.
- **Reentrancy**: Be mindful of reentrancy vectors when handling token transfers. Use checks-effects-interactions pattern.

## Testing Guidelines

### Test Naming Conventions

| Type | Naming pattern | Example |
|------|----------------|---------|
| Happy path unit | `test_unit_correct_ContractName__functionName` | `test_unit_correct_SongDB__register` |
| Revert unit | `test_unit_revert_ContractName__functionName_condition` | `test_unit_revert_SongDB__register_emptyTitle` |
| Fuzz | `test_fuzz_ContractName__functionName` | `test_fuzz_SongDB__register` |

### Directory Structure

Place tests in the appropriate directory:

- `test/uint/correct/` — Happy path tests verifying expected behavior
- `test/uint/revert/` — Tests verifying proper revert conditions and error messages
- `test/fuzz/` — Fuzzing tests using Foundry's fuzzer

### Test Setup

- All test contracts should inherit from `testing/Constants.sol` (our shared test setup)
- Use `vm.startPrank(address)` / `vm.stopPrank()` to simulate different callers
- Use predefined `AccountData` structs from `Constants.sol` for consistent test accounts
- Deploy a fresh `MockUsdc` (6 decimals) for testing stablecoin interactions

### Coverage Expectations

For every change to a database or orchestrator contract, you must provide:

1. **Happy path tests** — Verifying the function works as intended
2. **Revert tests** — Verifying all `require` / `if-revert` conditions trigger correctly with the expected custom errors
3. **Fuzz tests** (where applicable) — For functions with many input combinations

### Running Tests

```bash
# Run all tests
forge test

# Run with verbose output and gas report
forge test -vvv --gas-report

# Run specific test file
forge test --match-path test/uint/correct/database/SongDB_test_unit_correct.t.sol

# Run tests matching a pattern
forge test --match-contract SongDB
```

## Formatting

All code must be formatted with Foundry's formatter before submitting a PR:

```bash
forge fmt
```

Please do not mix formatting changes with functional changes in the same commit.

## Gas Analysis

If your change affects core logic (Orchestrator, database writes, or payment flows), generate a gas snapshot for comparison:

```bash
forge snapshot
```

Include the snapshot diff in your PR description if gas costs changed significantly.

## Commit & Pull Request Guidelines

### Commits

- Write clear, descriptive commit messages in English
- Use the imperative mood: "Add royalty split validation" not "Added royalty split validation"
- Keep commits focused and atomic. One logical change per commit

### Pull Request Checklist

Before requesting a review, ensure:

- [ ] All tests pass (`forge test`)
- [ ] Code is formatted (`forge fmt`)
- [ ] NatSpec documentation is complete for new functions and contracts
- [ ] New code follows the [Code Style & Standards](#code-style--standards)
- [ ] Revert conditions are tested
- [ ] Gas impact is considered and documented if significant
- [ ] No unsafe patterns introduced
- [ ] Branch is up to date with `main`

### PR Description

Provide a concise summary of:

- **What** changed and **why**
- **How** to test the change
- Any **breaking changes** or **deployment considerations**
- Gas impact (if any)

## Deployment Notes

### Environment Setup

Copy `.env.example` to `.env` and fill in your credentials:

```bash
RPC_URL=<mainnet_rpc>
RPC_URL_TESTNET=<testnet_rpc>
ETHERSCAN_API=<etherscan_api_key>
```

### Makefile Commands

| Command | Description |
|---------|-------------|
| `make deployTestnet` | Deploy to Arbitrum Sepolia with verification |
| `make deployMainnet` | Deploy to Arbitrum mainnet with verification |
| `make unitTest` | Run SongDB unit tests with verbose output and gas report |
| `make checkPrice` | Check pricing on mainnet |

### Mainnet Precautions

- **Never** commit private keys or `.env` files
- Always test on testnet before mainnet deployment
- Verify contract source code on Etherscan after deployment
- The Orchestrator initialization (`setDatabaseAddresses`) is a one-time operation — double-check all database addresses before calling it

## AI Tool Disclosure

We welcome contributions enhanced by AI tools, but we require transparency. If you use any AI-assisted coding tools (e.g., GitHub Copilot, ChatGPT, Claude, Cursor, etc.) to generate or significantly modify code, documentation, or tests, you must disclose this in your pull request description.

### What to Disclose

- **Which tool(s)** were used (e.g., "GitHub Copilot", "ChatGPT-4")
- **Which parts** of the contribution were AI-generated or AI-assisted (e.g., "Fuzz tests in `SongDB_test_fuzz.t.sol`", "NatSpec comments in `AlbumDB.sol`")
- **Your review process** — confirm that you have personally reviewed, tested, and understood all AI-generated code before submitting

### Important Notes

- AI-generated code is **not exempt** from our testing, formatting, and review requirements
- You remain fully responsible for the correctness, security, and licensing compliance of any AI-assisted contributions
- Undisclosed AI-generated code may result in rejection of the pull request

## License Notice

This project is licensed under the **SHINE-PPL-1.0** (Shine Protocol Public License v1.0).

- You are free to use, study, and modify the code for **non-commercial** purposes
- **Commercial use** or deployment as a **competitive product** requires explicit written authorization from 11:11 Labs
- See [LICENSE](LICENSE) for full terms

By contributing, you agree that your contributions will be licensed under the same SHINE-PPL-1.0 license.

## Questions & Support

- **Docs**: Check the [README](README.md) and inline NatSpec comments
- **Examples**: The test files are the best reference for how things work
- **History**: See the [CHANGELOG](CHANGELOG.md) for recent changes
- **Talk to us**: Reach out through the project's official channels

---

Built transparently. Owned by no one. Made for artists.
