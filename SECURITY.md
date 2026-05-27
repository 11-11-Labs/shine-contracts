# Security Policy

## Supported Versions

The following versions of the Shine smart contracts are currently supported with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 0.0.1   | :white_check_mark: |

> **Note:** Each deployed version of the smart contracts has its own support lifecycle. When a new Orchestrator version is deployed, support status will be updated accordingly.

## Reporting a Vulnerability

We take security seriously. Shine is built to protect artists and listeners, and that means protecting the contracts that hold their work and earnings.

If you find something that could put users at risk, please let us know as soon as you can.

### Where to Report

Please report security vulnerabilities via **one** of the following channels:

- **Twitter/X DM**: [https://x.com/shinemusic_app](https://x.com/shinemusic_app)
- **Email**: [contact@jistro.xyz](mailto:contact@jistro.xyz)

### What to Include

To help us triage and resolve issues quickly, please provide:

1. **Description** — A clear description of the vulnerability and its potential impact
2. **Steps to Reproduce** — Detailed instructions or proof-of-concept code to reproduce the issue
3. **Affected Contracts** — Specific contract files, functions, or deployment addresses involved
4. **Impact Assessment** — Your assessment of severity (e.g., fund drainage, access control bypass, corruption of permanent ownership records, griefing)
5. **Suggested Fix** (optional) — If you have a proposed remediation, we welcome it

### PGP Encryption

PGP encryption is **not required** but you may use it if you prefer. If you need our public key, please request it via email.

## Response Process

Here is what happens after you report:

1. **Acknowledgment** — We will confirm we received your report within **48 hours**
2. **Triage** — We check if the vulnerability is real and how severe it is
3. **Investigation** — We dig in and work on a fix. We may reach out if we need more details
4. **Resolution** — Once fixed, we will coordinate with you before going public
5. **Disclosure** — We publish an advisory and update the [CHANGELOG](CHANGELOG.md)

Critical issues get top priority. We focus on what protects user funds and the integrity of the platform.

## Scope

The following are **in scope** for security reports:

- Smart contracts in `src/contracts/` (AlbumDB, SongDB, UserDB, SplitterDB, Orchestrator)
- Deployment scripts in `script/`
- Foundry configuration in `foundry.toml` that affects contract behavior
- Access control, fund management, and royalty distribution logic

## Out of Scope

The following are **out of scope** for this security policy:

- Frontend applications, APIs, or off-chain infrastructure
- Third-party dependencies (`lib/forge-std`, `lib/solady`) — report these to their respective maintainers
- Test code (`test/`) unless it demonstrates a vulnerability in production contracts
- Previously disclosed vulnerabilities that have not yet been patched in a supported version
- Social engineering attacks against team members or users

## Disclosure Policy

We follow a **responsible disclosure** process:

- **Do not** publicly disclose the vulnerability before we have had a reasonable opportunity to investigate and deploy a fix
- We ask that you give us **at least 90 days** from acknowledgment before publishing details, unless agreed otherwise
- We will credit reporters in our security advisories if they wish to be named
- We reserve the right to bring in external auditors for complex issues

## AI Tool Disclosure

If you use AI-assisted tools (e.g., ChatGPT, Claude, GitHub Copilot) to help identify, analyze, or validate a security vulnerability, please disclose this in your report. Include:

- **Which tool(s)** were used
- **How** they were used (e.g., "Used to generate proof-of-concept", "Used to analyze bytecode patterns")
- **Your independent verification** — confirm that you have independently verified all findings and that the vulnerability is reproducible without AI assistance

This helps us accurately assess the report and ensures that human judgment remains central to our security process.

## Bug Bounty

We do not run a formal bug bounty program right now. That said, we genuinely appreciate responsible disclosure and will happily give public credit to reporters who want it.

## Security Best Practices for Users

- Always verify contract addresses against official sources before interacting
- Be cautious of phishing attempts impersonating the Shine platform or team
- Report suspicious activity to the channels listed above

---

Thanks for helping keep Shine safe, transparent, and resilient.
