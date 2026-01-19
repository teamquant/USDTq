# Security Policy

## Contract Information

| Parameter | Value |
|-----------|-------|
| **Contract Address** | [`0xD5Eb307D86EBAc71D743023A622982fF7acA62aE`](https://bscscan.com/address/0xD5Eb307D86EBAc71D743023A622982fF7acA62aE) |
| **Gnosis Safe** | [`0xB00d4Ac55748ED6cB404C38027a46D2AB1b22A19`](https://bscscan.com/address/0xB00d4Ac55748ED6cB404C38027a46D2AB1b22A19) |
| **Network** | BNB Smart Chain (BSC) |
| **Security Score** | SolidityScan 93.65/100 |

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

The USDTq team takes security vulnerabilities seriously. We appreciate your efforts to responsibly disclose your findings.

### How to Report

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report them via email to: **security@teamquant.space**

### What to Include

Please include the following information in your report:

- **Type of issue** (e.g., access control bypass, reentrancy, integer overflow, etc.)
- **Full paths of source file(s)** related to the manifestation of the issue
- **Location of the affected source code** (tag/branch/commit or direct URL)
- **Step-by-step instructions** to reproduce the issue
- **Proof-of-concept or exploit code** (if possible)
- **Impact of the issue**, including how an attacker might exploit it

### Response Timeline

- **Initial Response**: Within 48 hours of submission
- **Status Update**: Within 7 days with an assessment of the vulnerability
- **Resolution Timeline**: Depends on severity; critical issues will be prioritized

### Severity Classification

| Severity | Description | Example |
|----------|-------------|---------|
| Critical | Direct loss of funds or complete system compromise | Unauthorized minting, bypassing blacklist on transfers |
| High | Significant impact on protocol functionality | Denial of service, role escalation |
| Medium | Limited impact, requires specific conditions | Gas griefing, minor access control issues |
| Low | Minimal impact, best practice violations | Informational findings, code quality |

### Safe Harbor

We support responsible disclosure and will not pursue legal action against security researchers who:

- Make a good faith effort to avoid privacy violations, data destruction, or service interruption
- Only interact with accounts you own or with explicit permission from account holders
- Do not exploit a vulnerability beyond what is necessary to demonstrate its existence
- Report vulnerabilities promptly and provide reasonable time for remediation before public disclosure

## Bug Bounty Program

Details about our bug bounty program will be published at: **https://teamquant.space/security**

Rewards will be determined based on:
- Severity of the vulnerability
- Quality of the report
- Potential impact on users and the protocol

## Security Audits

### Completed Audits

- [x] SolidityScan automated audit (Score: 93.65/100)
- [ ] External third-party audit (Planned for Q3 2026)

### Planned Audits

External security audits will be conducted by reputable third-party firms. Audit reports will be published in the `/audits` directory of this repository.

## Security Best Practices for Users

1. **Verify Contract Addresses**: Always verify you are interacting with the official USDTq contract
2. **Check Transactions**: Review transaction details before signing
3. **Secure Your Keys**: Never share your private keys or seed phrases
4. **Use Hardware Wallets**: For large holdings, consider using a hardware wallet

## Contact

For non-security related questions, please use:
- GitHub Issues: For bugs and feature requests
- Telegram: t.me/teamquant (upcoming)
- Twitter: @TeamQuantSpace (upcoming)
- Email: support@teamquant.space
- Website: https://teamquant.space
