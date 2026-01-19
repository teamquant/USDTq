# USDTq Security Policy and Pre-Audit Checklist

This document provides an overview of the security measures integrated into the `USDTq` smart contract and serves as a pre-audit checklist for reviewers.

## Contract Information

| Parameter | Value |
|-----------|-------|
| **Contract Address** | `0xD5Eb307D86EBAc71D743023A622982fF7acA62aE` |
| **Gnosis Safe** | `0xB00d4Ac55748ED6cB404C38027a46D2AB1b22A19` |
| **Network** | BNB Smart Chain (BSC) |
| **Security Score** | SolidityScan 93.65/100 |
| **Verification** | [BscScan Verified](https://bscscan.com/address/0xD5Eb307D86EBAc71D743023A622982fF7acA62aE) |

## 1. Common Vulnerability Analysis

This section addresses common smart contract vulnerabilities and how the `USDTq` contract's design mitigates them.

### Reentrancy
-   **Mitigation**: The contract inherits from OpenZeppelin's contracts (v5.x). Functions do not have external calls that modify state, and the `_update` override contains no external calls. The design implicitly follows the Checks-Effects-Interactions pattern.

### Access Control
-   **Mitigation**: The contract uses OpenZeppelin's `AccessControl` to enforce a strict, role-based permission model.
    -   `DEFAULT_ADMIN_ROLE`: Held by a Gnosis Safe, this role is the only one that can grant or revoke other roles.
    -   `ADMIN_ROLE`: Manages key contract parameters. Also held by the Gnosis Safe.
    -   Operational roles (`MINTER`, `BLACKLISTER`, `PAUSER`, `RESERVE_MANAGER`) are separated to enforce the principle of least privilege.

### Integer Overflow/Underflow
-   **Mitigation**: The contract is compiled with Solidity `0.8.28`, which has built-in protection against integer overflow and underflow.

### Front-Running
-   **Mitigation**: The contract design minimizes front-running risk as it does not include inherent market mechanisms.

### Denial of Service (DoS)
-   **Mitigation**: The constructor includes checks to limit the size of input arrays (`minterSigners`, etc.) to a maximum of 10 each, preventing gas-limit-related DoS attacks during deployment.

### Insecure Randomness
-   **Mitigation**: The contract does not use any on-chain sources of randomness.

## 2. Security Tooling

The project is configured with:
-   **Solhint**: For style and security best practices.
-   **Prettier**: For consistent code formatting.
-   **Slither**: For static analysis vulnerability detection.
-   **solidity-coverage**: For test coverage reporting.
-   **Foundry** (optional): For fuzz testing and invariant testing.

## 3. Contract Immutability

The `USDTq` contract is **non-upgradeable** by design.

### Why Non-Upgradeable?

-   **Trust**: Users can verify the contract code and trust it will not change.
-   **Simplicity**: No proxy pattern complexity or storage collision risks.
-   **Security**: Eliminates upgrade-related attack vectors.
-   **Predictability**: Contract behavior is deterministic and permanent.

### Trade-offs

-   Bug fixes require deploying a new contract and migrating tokens.
-   New features require a new contract deployment.
-   This is mitigated by thorough testing and security audits before deployment.

### Future Versions

If a new version is needed, it will be deployed as a separate contract. Migration procedures will be documented and executed with user consent.

## 4. Role-Based Security Model

### Role Hierarchy

```
┌─────────────────────────────────────────────────────────┐
│ Gnosis Safe Multi-Sig (Master Controller)              │
│ • DEFAULT_ADMIN_ROLE: Grant/revoke all roles           │
│ • ADMIN_ROLE: Update supply caps and parameters        │
│ • Holds initial reserve backing                        │
└─────────────────────────────────────────────────────────┘
                        │
        ┌───────────────┼───────────────┬─────────────┐
        ▼               ▼               ▼             ▼
┌──────────────┐ ┌──────────────┐ ┌────────────┐ ┌──────────────┐
│ MINTER_ROLE  │ │ BLACKLISTER  │ │ PAUSER     │ │ RESERVE_MGR  │
│ Mint/Burn    │ │ Compliance   │ │ Emergency  │ │ Attestation  │
└──────────────┘ └──────────────┘ └────────────┘ └──────────────┘
```

### Role Permissions Matrix

| Action | DEFAULT_ADMIN | ADMIN | MINTER | BLACKLISTER | PAUSER | RESERVE_MGR |
|--------|---------------|-------|--------|-------------|--------|-------------|
| Grant/Revoke Roles | X | | | | | |
| Set Supply Caps | | X | | | | |
| Mint Tokens | | | X | | | |
| Burn Tokens | | | X | | | |
| Blacklist Address | | | | X | | |
| Pause/Unpause | | | | | X | |
| Update Reserves | | | | | | X |

## 5. Pre-Audit Checklist

This checklist should be completed before submitting the contract for an external audit.

### Code Quality
-   [x] All functions have NatSpec comments (`@notice`, `@dev`, `@param`, `@return`)
-   [x] Custom errors used for all validations (gas optimization)
-   [x] Consistent code formatting (Prettier + Solhint)
-   [x] No compiler warnings
-   [x] Latest stable Solidity version (0.8.28)

### Testing
-   [x] Unit tests for all public functions
-   [x] Access control tests (role enforcement)
-   [x] Edge case tests (zero amounts, max values)
-   [x] Blacklist functionality tests
-   [x] Supply cap enforcement tests
-   [ ] Fuzz tests for critical functions
-   [ ] Integration tests on testnet fork
-   [ ] Gas optimization benchmarks

### Security Analysis
-   [x] Slither static analysis passes
-   [x] No high/medium severity findings
-   [ ] Mythril symbolic execution (recommended)
-   [ ] Manual code review by security expert

### Deployment Readiness
-   [x] Testnet deployment completed
-   [x] Deployment scripts reviewed
-   [x] Constructor parameters documented
-   [x] Gnosis Safe configured and tested
-   [x] Role assignment plan documented
-   [x] Emergency procedures documented
-   [x] **Mainnet deployment completed** (Contract: `0xD5Eb307D86EBAc71D743023A622982fF7acA62aE`)

### Documentation
-   [x] README with setup instructions
-   [x] Architecture documentation
-   [x] Tokenomics documentation
-   [x] Security documentation (this file)
-   [x] Deployment guide
-   [x] SECURITY.md with disclosure policy
-   [x] Whitepaper documentation

## 6. Known Limitations

### Blacklist Bypass
-   Blacklisted addresses can still have tokens burned (compliance burns allowed)
-   This is intentional to allow burning tokens from sanctioned addresses

### Reserve Attestation
-   `totalReserves` is informational only and does not enforce actual backing
-   Users should verify reserves through external audits

### Centralization Risks
-   Gnosis Safe holds significant control (admin roles, initial supply)
-   Mitigated by multi-sig requirement and role separation

## 7. Incident Response

### Emergency Pause
1. `PAUSER_ROLE` holder calls `pause()`
2. Minting is disabled immediately
3. Transfers and burns remain active (user protection)
4. Investigate and resolve issue
5. `PAUSER_ROLE` holder calls `unpause()` when resolved

### Compromised Role Key
1. `DEFAULT_ADMIN_ROLE` (Gnosis Safe) revokes compromised role
2. Grant role to new secure address
3. Investigate scope of compromise
4. Notify affected users if necessary

### Contract Bug Discovery
1. Pause minting if exploitable
2. Assess severity and impact
3. If critical: plan migration to new contract
4. Communicate transparently with users

## 8. Contact

-   Security Issues: security@teamquant.space
-   General Inquiries: support@teamquant.space
-   Bug Bounty: https://teamquant.space/security
