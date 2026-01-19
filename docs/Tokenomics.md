# USDTq Tokenomics

This document outlines the economic principles, supply mechanism, and reserve policy of the USDTq stablecoin.

## 1. Core Principles

-   **Peg Stability**: The primary goal of USDTq is to maintain a stable value pegged 1:1 to the US Dollar.
-   **Transparency**: All reserve holdings and the token's circulating supply will be verifiable on-chain through reserve attestation events.
-   **Liquidity**: The protocol is designed to ensure deep liquidity for USDTq across decentralized exchanges (DEXs) and other DeFi protocols.

## 2. Supply Management

The total supply of USDTq is dynamically managed based on the value of the underlying reserves.

-   **Minting**: New USDTq tokens are minted when backing assets are deposited into the reserve. The minting process is controlled by the `MINTER_ROLE` and is subject to supply caps and pause mechanism.
-   **Burning**: USDTq tokens can be burned in two ways:
    -   **User Self-Burn**: Any user can burn their own tokens using `burn()` - always active, even when minting is paused
    -   **Authorized Burn**: `MINTER_ROLE` can burn tokens via `burnFrom()` with token holder approval
-   **Initial Supply**: 10,000,000 USDTq minted to the Gnosis Safe treasury upon deployment, fully backed by equivalent reserves.

### Supply Caps

To ensure controlled growth and mitigate risks, the contract has two supply caps:

| Parameter | Value | Description |
|-----------|-------|-------------|
| `maxMintPerTransaction` | 10,000,000 USDTq | Per-mint limit to prevent errors and malicious actions |
| `maxTotalSupply` | 1,000,000,000 USDTq | Hard cap on total circulating supply |

Both caps can be adjusted by the `ADMIN_ROLE` (held by the Gnosis Safe multi-sig) to allow for scaling as the ecosystem grows.

## 3. Reserve Policy

The USDTq stablecoin is a fully collateralized, reserve-backed token maintaining a **1:1 backing ratio** with USD-denominated reserves.

### 3.1. Reserve Composition

-   **Primary Reserves:** USDT, USDC
-   **Target Backing:** 100% (10,000 basis points)
-   The goal is to maintain high-quality, liquid stablecoin reserves for reliable redemption.

### 3.2. Reserve Management

-   Reserve assets are held in the Gnosis Safe multi-signature wallet at: `0xB00d4Ac55748ED6cB404C38027a46D2AB1b22A19`
-   The `RESERVE_MANAGER_ROLE` is responsible for attesting reserve data on-chain. This role does not have permission to move funds but serves as a transparency reporter.

### 3.3. On-Chain Transparency

The contract includes built-in reserve tracking:

```solidity
totalReserves: Current reserve amount (6 decimals)
lastReserveUpdate: Timestamp of last attestation
```

**Reserve Management Functions:**
- `updateReserves(uint256)` - Update total reserve amount
- `addReserves(uint256, string)` - Record reserve addition with type
- `removeReserves(uint256, string)` - Record reserve removal with reason

**Public View Functions:**
- `getCollateralizationRatio()` - Returns (ratio, reserves, supply)
- `getReserveHealth()` - Returns (isHealthy, deficit, surplus)

**Events:**
```solidity
ReservesUpdated(uint256 totalReserves, uint256 totalSupply, uint256 collateralizationRatio, address indexed updatedBy)
ReservesAdded(uint256 amount, string reserveType, address indexed addedBy)
ReservesRemoved(uint256 amount, string reason, address indexed removedBy)
```

## 4. Fee Structure

**Token Fees:** 0% (no transfer tax)

- No buy tax
- No sell tax
- No transfer tax

**Network Fees:**

- BSC gas fees apply (~$0.10-0.50 per transaction)

Revenue is generated from:
-   **Yield on Reserves**: Interest earned from deploying reserve assets into secure, yield-bearing protocols.
-   **Liquidity Provision**: Fees earned by providing USDTq liquidity to DEXs.

This revenue is used to cover operational costs and fund further development.
