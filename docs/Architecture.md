# USDTq Architecture

This document outlines the security architecture, tokenomics, and core features of the USDTq stablecoin contract.

## Contract Information

| Parameter | Value |
|-----------|-------|
| **Contract Address** | `0xD5Eb307D86EBAc71D743023A622982fF7acA62aE` |
| **Gnosis Safe** | `0xB00d4Ac55748ED6cB404C38027a46D2AB1b22A19` |
| **Network** | BNB Smart Chain (BSC) |
| **Standard** | BEP-20 (ERC-20 compatible) |
| **Compiler** | Solidity 0.8.28 |
| **Security Score** | SolidityScan 93.65/100 |

## Security Architecture: Separation of Duties

The security of the USDTq contract relies on a multi-layered, role-based access control system managed by a Gnosis Safe multi-signature wallet. This model enforces a strict separation of duties, ensuring no single address or entity can control all critical functions of the system.

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

### Roles

-   **Gnosis Safe (Master Admin)**:
    -   **`DEFAULT_ADMIN_ROLE`**: The highest level of authority. This role holder can grant and revoke any other role, including other admin roles. It is intended to be held exclusively by the Gnosis Safe to require a multi-signature consensus for any changes to the permission structure.
    -   **`ADMIN_ROLE`**: A high-privilege role responsible for managing key contract parameters, such as the `maxTotalSupply` and `maxMintPerTransaction`. This role is also held by the Gnosis Safe.

-   **Operational Roles (Single-Purpose Signers)**:
    -   **`MINTER_ROLE`**: Authorized to mint new tokens and burn tokens from consenting users. This role is intended for a secure, automated system or a tightly controlled operational wallet responsible for managing the token supply in response to reserve changes.
    -   **`BLACKLISTER_ROLE`**: Authorized to add or remove addresses from the blacklist for compliance with regulations (e.g., OFAC sanctions) and prevention of fraud. This role is managed by the compliance department.
    -   **`PAUSER_ROLE`**: Authorized to pause minting operations in the event of an emergency, such as the discovery of a critical vulnerability. Transfers and burns remain enabled to protect user assets.
    -   **`RESERVE_MANAGER_ROLE`**: Authorized to update the on-chain reserve attestation data. This role is for transparency and does not directly manage funds.

This separation ensures that, for example, a compromised `MINTER` key cannot be used to change supply caps or blacklist addresses. All high-level administrative changes must go through the multi-signature process of the Gnosis Safe.

## Tokenomics

| Parameter | Value | Description |
|-----------|-------|-------------|
| **Initial Supply** | 10,000,000 USDTq | Minted to Gnosis Safe |
| **Max Per Transaction** | 10,000,000 USDTq | Per-mint limit |
| **Max Total Supply** | 1,000,000,000 USDTq | Hard cap (adjustable) |
| **Decimals** | 6 | Matches USDT/USDC |
| **Reserve Backing** | 1:1 | USD-equivalent (USDT, USDC) |

## Core Features

-   **OpenZeppelin v5.x**: Built on the latest, audited contracts from OpenZeppelin.
-   **Fixed Contract (Non-Upgradeable)**: To enhance trust and predictability, the contract is non-upgradeable. Future versions will be deployed as new, separate contracts.
-   **Gas Optimization**: The contract is optimized for gas efficiency with custom error messages for the BNB Chain.
-   **Compliance**:
    -   **Blacklist**: Allows the `BLACKLISTER_ROLE` to block addresses from sending or receiving tokens. Each blacklist includes a reason string for transparency.
    -   **Pausable Minting**: Minting can be paused via the `PAUSER_ROLE` without affecting core transfer and burn functionality, allowing users to move their funds even during an emergency.
-   **Reserve Transparency**:
    -   Includes functions (`updateReserves`, `addReserves`, `removeReserves`) that allow the `RESERVE_MANAGER_ROLE` to attest reserve levels on-chain.
    -   Emits `ReservesUpdated` events, allowing third-party tools and users to track the collateralization ratio transparently.
    -   Public view functions: `getCollateralizationRatio()` and `getReserveHealth()`

## User Protection

The following functions remain active even during emergencies:

| Function | Status | Description |
|----------|--------|-------------|
| Token transfers | Always active | Users can always move their tokens |
| User self-burn | Always active | Users can always burn their own tokens |
| Approvals | Always active | Users can always manage allowances |
| Balance queries | Always active | Users can always check balances |
| Minting | Pausable | Can be paused for security |
| Admin operations | Multi-sig required | Requires Gnosis Safe approval |
