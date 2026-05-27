---
name: Bug Report
description: Report unexpected behavior, reverts, or security concerns in the contracts.
title: '[Bug] '
labels: ['bug']
---

<!--
Thank you for reporting.
Shine is only as strong as the community that keeps it honest.
-->

## Severity

How serious is this?

- [ ] Critical — loss of funds, permanent data corruption, or total contract lock
- [ ] High — access control bypass, incorrect royalty distribution, or significant DoS
- [ ] Medium — unexpected reverts, state inconsistency, or notable gas waste
- [ ] Low — cosmetic issues, off-by-one edge cases, or minor gas inefficiency
- [ ] Informational — unclear behavior, missing documentation, or code smell

## Affected contracts

Which contracts are involved?

- [ ] Orchestrator
- [ ] UserDB
- [ ] SongDB
- [ ] AlbumDB
- [ ] SplitterDB
- [ ] IdUtils / Library
- [ ] Deployment Script
- [ ] Multiple / Other: ___

## What happened?

Describe the unexpected behavior in plain language.

> When a user tries to purchase a song after...

## Steps to reproduce

Give us a minimal test case or sequence of calls.

1. Deploy contracts with...
2. Call `Orchestrator.purchaseSong(1, 1)` as...
3. Observe that...

## Expected vs actual behavior

What did you expect to happen? What actually happened?

> **Expected:** User balance is deducted and song ownership is recorded.
> **Actual:** Transaction reverts with...

## Logs or error output

```
Paste relevant traces, revert reasons, or event logs here.
```

## Environment

Help us reproduce your setup.

- **Foundry version:**
- **Solidity version:**
- **Operating system:**
- **Commit hash:**

---

## AI Tool Disclosure (Required)

<!--
Transparency is mandatory. For every AI tool you used to create or refine this issue, state:
- Tool name (e.g., ChatGPT, Claude, Copilot, Cursor)
- Model version (e.g., GPT-4, Claude 3.5 Sonnet)
- Specific purpose (e.g., "Analyzed the contract to identify the vulnerability", "Drafted the reproduction steps", "Generated the proof-of-concept trace", "Grammar checking only", "Reviewed this issue before posting")

If you did not use any AI tools, write "None".

Any issue found to contain undisclosed AI-generated content will be closed and disregarded.
-->

**AI tools used:**

<!-- Example:
- Claude 3.5 Sonnet: Used to analyze the Orchestrator code and identify the reentrancy vector described above.
- ChatGPT-4o: Used to draft the initial issue description.

Or:
None
-->

---

## Checklist

- [ ] I have searched existing issues and this has not been reported before
- [ ] I can reproduce this on the latest commit
- [ ] I have reviewed the relevant contract code and NatSpec before filing this
