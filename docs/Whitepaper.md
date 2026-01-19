# USDTq Whitepaper: A Compliance-Ready BEP-20 Stablecoin with Multi-Signature Governance

**Version 1.0** | **January 2026** | **TeamQuant**

-----

## 1. Abstract

USDTq is a reserve-backed stablecoin built on the BNB Smart Chain (BSC) following the BEP-20 standard. Designed for institutional-grade treasury operations, USDTq provides a low-volatility digital asset for on-chain settlement, payments, and programmable treasury management. USDTq distinguishes itself through comprehensive regulatory compliance features, multi-signature governance, transparent reserve attestation, and a security-first architecture utilizing role-based access control.

## 2. Introduction

The decentralized finance (DeFi) ecosystem demands price-stable assets that balance innovation with regulatory compliance. While existing stablecoins provide price stability, many lack the governance transparency, compliance mechanisms, and security controls required by institutional users and regulatory frameworks.

USDTq addresses these requirements by implementing:

- **Multi-signature governance** via Gnosis Safe
- **Regulatory compliance features** (OFAC/AML blacklist capability)
- **Transparent reserve attestation** with on-chain verification
- **Emergency response mechanisms** (pausable minting)
- **Role-based security** with separation of duties

## 3. Technical Architecture

### 3.1 Token Standards and Specification

|Parameter           |Value                                       |
|--------------------|--------------------------------------------|
|**Standard**        |BEP-20 (ERC-20 compatible)                  |
|**Symbol**          |USDTq                                       |
|**Name**            |USDTq teamquant.space                       |
|**Decimals**        |6                                           |
|**Blockchain**      |BNB Smart Chain (BSC)                       |
|**Contract Address**|`0xD5Eb307D86EBAc71D743023A622982fF7acA62aE`|
|**Compiler**        |Solidity 0.8.28                             |
|**Verification**    |BscScan verified ✓                          |

The 6-decimal standard ensures maximum compatibility with:

- Hardware wallets (Ledger, Trezor)
- Centralized exchanges (CEX integration)
- Decentralized exchanges (DEX compatibility)
- Institutional custody providers
- Existing stablecoin infrastructure (USDT/USDC alignment)

### 3.2 Smart Contract Architecture

USDTq implements a **comprehensive security architecture** built on OpenZeppelin v5.x contracts:

**Core Components:**

1. **ERC20** - Standard token functionality
1. **ERC20Burnable** - Token burning capability
1. **AccessControl** - Role-based permissions (5 distinct roles)
1. **Pausable** - Emergency pause for minting operations

**Key Design Principles:**

- ✅ **Non-upgradeable** - Fixed contract for maximum trust
- ✅ **Gas-optimized** - Efficient for BSC network
- ✅ **Battle-tested** - Built on proven OpenZeppelin libraries
- ✅ **Transparent** - Fully verified source code
- ✅ **Auditable** - Clear event logs for all operations

### 3.3 Security Architecture: Separation of Duties

USDTq implements a **5-role governance model** to prevent single points of failure:

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

**Role Descriptions:**

1. **DEFAULT_ADMIN_ROLE** (Gnosis Safe)
- Master admin with ability to grant/revoke all roles
- Requires multi-signature approval (e.g., 3-of-5 signers)
- Controls role assignments and updates
1. **ADMIN_ROLE** (Gnosis Safe)
- Update supply caps (maxMintPerTransaction, maxTotalSupply)
- Adjust operational parameters
- Cannot mint or burn tokens directly
1. **MINTER_ROLE** (Operational Signers)
- Mint new tokens (within supply caps)
- Burn tokens via burnFrom()
- Subject to pause mechanism
1. **BLACKLISTER_ROLE** (Compliance Officers)
- Add/remove addresses from blacklist
- Enforce OFAC/AML compliance
- Maintain audit trail with reasons
1. **PAUSER_ROLE** (Security Team)
- Emergency pause minting operations
- Unpause after security review
- Transfers remain active for user protection
1. **RESERVE_MANAGER_ROLE** (Treasury Team)
- Attest to reserve levels
- Update reserve information
- Maintain transparency events

-----

## 4. Supply Mechanics: Controlled Elastic Supply

### 4.1 Reserve-Backed Model

USDTq maintains a **1:1 backing ratio** with USD-denominated reserves:

- **Primary Reserves:** USDT, USDC
- **Initial Supply:** 10,000,000 USDTq
- **Target Backing:** 100% (10,000 basis points)
- **Reserve Verification:** On-chain attestation via events

### 4.2 Minting Process

**Authorization:**

- Only addresses with `MINTER_ROLE` can mint
- Requires multi-sig approval from Gnosis Safe to grant role
- Subject to supply caps and pause mechanism

**Supply Caps:**

```
maxMintPerTransaction: 10,000,000 USDTq (adjustable)
maxTotalSupply: 1,000,000,000 USDTq (adjustable)
```

**Minting Workflow:**

1. Reserve Manager verifies backing assets received
1. Minter calls `mint(address to, uint256 amount)`
1. Contract checks:
- ✅ Minting is not paused
- ✅ Amount ≤ maxMintPerTransaction
- ✅ New supply ≤ maxTotalSupply
- ✅ Recipient is not blacklisted
1. Tokens minted, `TokensMinted` event emitted

### 4.3 Burning Process

**Two Burn Methods:**

1. **User Self-Burn** (No role required)
- `burn(uint256 amount)` - Burn your own tokens
- Always active (even when paused)
- User protection mechanism
1. **Authorized Burn** (MINTER_ROLE required)
- `burnFrom(address from, uint256 amount)` - Burn approved tokens
- Requires token approval from holder
- Used for redemptions
- `TokensBurned` event emitted

### 4.4 Pausable Minting

**Emergency Pause:**

- Only `PAUSER_ROLE` can pause/unpause minting
- **Pausing ONLY affects:** New minting operations
- **Never affects:** Transfers, burns, approvals (user protection)

**Use Cases:**

- Security incident response
- Smart contract vulnerability discovery
- Regulatory compliance hold
- Market manipulation prevention

-----

## 5. Regulatory Compliance Features

### 5.1 Blacklist Functionality

USDTq implements industry-standard blacklist capabilities similar to USDT and USDC:

**Purpose:**

- OFAC sanctions compliance
- AML (Anti-Money Laundering) requirements
- Court-ordered asset freezes
- Fraud prevention

**Implementation:**

- Only `BLACKLISTER_ROLE` can blacklist/unblacklist
- Blacklisted addresses **cannot:**
  - Send tokens
  - Receive tokens (including mints)
- Blacklisted addresses **can:**
  - Have tokens burned (compliance seizure)
- Each blacklist includes a **reason string** for transparency

**Events:**

```solidity
event Blacklisted(address indexed account, string reason)
event UnBlacklisted(address indexed account)
```

**Audit Trail:**

- View blacklist status: `isBlacklisted(address)`
- View blacklist reason: `blacklistReason(address)`

### 5.2 Transparent Reserve Attestation

**On-Chain Reserve Tracking:**

```solidity
totalReserves: Current reserve amount (6 decimals)
lastReserveUpdate: Timestamp of last attestation
```

**Reserve Management Functions:**

- `updateReserves(uint256)` - Update total reserve amount
- `addReserves(uint256, string)` - Record reserve addition
- `removeReserves(uint256, string)` - Record reserve removal

**Transparency Events:**

```solidity
event ReservesUpdated(
    uint256 totalReserves,
    uint256 totalSupply,
    uint256 collateralizationRatio,  // Basis points (10000 = 100%)
    address indexed updatedBy
)
```

**Public View Functions:**

```solidity
getCollateralizationRatio() → (ratio, reserves, supply)
getReserveHealth() → (isHealthy, deficit, surplus)
```

-----

## 6. Governance Model

### 6.1 Multi-Signature Governance (Gnosis Safe)

**Master Controller:**

- **Platform:** Gnosis Safe on BSC
- **Signers:** TeamQuant core team members
- **Threshold:** Recommended 3-of-5 or higher
- **Address:** `0xB00d4Ac55748ED6cB404C38027a46D2AB1b22A19`

**Powers:**

- Grant/revoke any operational role
- Update supply caps (ADMIN_ROLE)
- Modify role assignments
- Emergency governance actions

**Separation of Duties:**

- ❌ Gnosis Safe **cannot** mint tokens directly
- ❌ Gnosis Safe **cannot** blacklist addresses directly
- ❌ Gnosis Safe **cannot** pause operations directly
- ✅ Gnosis Safe **can** assign roles to addresses that can perform these actions

### 6.2 Operational Security

**Key Management:**

- Multi-signature requirement prevents single-signer control
- Hardware wallet signers recommended (Ledger/Trezor)
- Geographic distribution of signers
- Time-delayed transactions for critical operations

**Transparency:**

- All role assignments visible on-chain
- All role changes emit events
- Public verification via BscScan

-----

## 7. Use Cases

### 7.1 DeFi Integration

**Decentralized Exchanges (DEXs):**

- Trading pair: USDTq/BNB, USDTq/USDT, USDTq/BUSD
- Liquidity provision
- Yield farming pools

**Lending Protocols:**

- Collateral asset
- Borrowing asset
- Stable yield generation

**Derivatives & Perpetuals:**

- Margin trading settlement
- Collateral for leveraged positions

### 7.2 Cross-Border Settlements

**International Payments:**

- Fast settlement (3-second BSC block time)
- Low transaction fees (~$0.10-0.50)
- 24/7 availability
- Programmable payment conditions

**Treasury Operations:**

- Multi-currency settlement
- Automated reconciliation
- Real-time audit trails

### 7.3 Privacy-Enhanced Operations (Future)

While USDTq itself is a transparent on-chain asset, it serves as a building block for privacy-enhanced financial operations:

**Privacy Layer Integration (Future Development):**

- Compatible with zero-knowledge (ZK) proof systems
- Suitable for private payment channels
- Can be wrapped for confidential transactions
- Partitioned settlement for institutional privacy

**Important Note:** Privacy features are **not built into the base contract**. USDTq provides the stable, compliant foundation upon which privacy protocols can be built in future iterations or through third-party integrations.

-----

## 8. Security Considerations

### 8.1 Smart Contract Security

**Audit Status:** Self-audited with SolidityScan score: 93.65/100

**Security Measures:**

- Gas optimization (DoS attack prevention)
- Reentrancy protection (checks-effects-interactions pattern)
- Integer overflow protection (Solidity 0.8.28 built-in)
- Role-based access control (OpenZeppelin v5.x)
- Custom error messages (gas-efficient reverts)

**Known Design Decisions:**

- ⚠️ **Pausable** - Intentional for emergency response
- ⚠️ **Blacklist** - Required for regulatory compliance
- ⚠️ **Mintable** - Elastic supply for scalability
- ✅ **Non-upgradeable** - Immutable code for trust

### 8.2 Operational Security

**Access Control:**

- Multi-signature governance (3-of-5+ recommended)
- Hardware wallet signers
- Geographic distribution
- Time-delayed critical operations

**Monitoring:**

- Real-time event monitoring
- Unusual transaction alerts
- Reserve ratio monitoring
- Collateralization health checks

### 8.3 User Protection

**Always Active Functions:**

- ✅ Token transfers (never pausable)
- ✅ User self-burn (always available)
- ✅ Approvals (always functional)
- ✅ Balance queries (always accessible)

**Protected Functions:**

- 🔒 Minting (pausable for security)
- 🔒 Admin operations (multi-sig required)

-----

## 9. Tokenomics

### 9.1 Initial Distribution

```
Total Initial Supply: 10,000,000 USDTq
└─ Gnosis Safe Treasury: 10,000,000 USDTq (100%)
   Purpose: Reserve backing + liquidity provision
```

### 9.2 Supply Expansion Model

**Scalability:**

- Max Total Supply: 1,000,000,000 USDTq (adjustable)
- Expansion driven by reserve backing
- Transparent on-chain attestation
- Community oversight via events

### 9.3 Fee Structure

**Token Fees:** 0% (no transfer tax)

- No buy tax
- No sell tax
- No transfer tax

**Network Fees:**

- BSC gas fees apply (~$0.10-0.50 per transaction)

-----

## 10. Roadmap

### Phase 1: Foundation (Q1 2026) ✅

- ✅ Smart contract development
- ✅ BscScan verification
- ✅ Gnosis Safe deployment
- ✅ Security optimization (SolidityScan 93.65)

### Phase 2: Market Launch (Q1-Q2 2026)

- ⏳ Initial liquidity pool (PancakeSwap)
- ⏳ CoinMarketCap listing
- ⏳ CoinGecko listing
- ⏳ Trust Wallet logo submission
- ⏳ Community building

### Phase 3: Integration (Q3 2026)

- ⏳ CEX listings (BitGet, MEXC)
- ⏳ Lending protocol integration
- ⏳ External security audit
- ⏳ Reserve reporting automation

### Phase 4: Expansion (Q4 2026+)

- ⏳ Cross-chain bridge development
- ⏳ Privacy layer protocol research
- ⏳ Institutional partnerships
- ⏳ Decentralized governance transition

-----

## 11. Technical Specifications

### 11.1 Smart Contract Functions

**Public View Functions:**

```solidity
// Standard ERC20
totalSupply() → uint256
balanceOf(address) → uint256
allowance(address, address) → uint256

// USDTq Specific
maxMintPerTransaction() → uint256
maxTotalSupply() → uint256
totalReserves() → uint256
lastReserveUpdate() → uint256
getRemainingMintCapacity() → (perTx, total)
getCollateralizationRatio() → (ratio, reserves, supply)
getReserveHealth() → (isHealthy, deficit, surplus)
isBlacklisted(address) → bool
blacklistReason(address) → string
paused() → bool
```

**Administrative Functions:**

```solidity
// MINTER_ROLE
mint(address, uint256)
burnFrom(address, uint256)

// BLACKLISTER_ROLE
blacklist(address, string)
unBlacklist(address)

// PAUSER_ROLE
pause()
unpause()

// RESERVE_MANAGER_ROLE
updateReserves(uint256)
addReserves(uint256, string)
removeReserves(uint256, string)

// ADMIN_ROLE
setMaxMintPerTransaction(uint256)
setMaxTotalSupply(uint256)

// DEFAULT_ADMIN_ROLE
grantRole(bytes32, address)
revokeRole(bytes32, address)
```

### 11.2 Events

```solidity
// ERC20 Standard
Transfer(address indexed from, address indexed to, uint256 value)
Approval(address indexed owner, address indexed spender, uint256 value)

// USDTq Specific
TokensMinted(address indexed minter, address indexed to, uint256 amount)
TokensBurned(address indexed burner, address indexed from, uint256 amount)
Blacklisted(address indexed account, string reason)
UnBlacklisted(address indexed account)
MaxMintPerTransactionUpdated(uint256 oldLimit, uint256 newLimit)
MaxTotalSupplyUpdated(uint256 oldLimit, uint256 newLimit)
ReservesUpdated(uint256 totalReserves, uint256 totalSupply, uint256 ratio, address indexed updatedBy)
ReservesAdded(uint256 amount, string reserveType, address indexed addedBy)
ReservesRemoved(uint256 amount, string reason, address indexed removedBy)
Paused(address account)
Unpaused(address account)
RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
```

-----

## 12. Comparison with Industry Leaders

|Feature                      |USDTq          |USDT       |USDC        |
|-----------------------------|---------------|-----------|------------|
|**Blockchain**               |BSC            |Multi-chain|Multi-chain |
|**Decimals**                 |6              |6          |6           |
|**Blacklist**                |✅              |✅          |✅           |
|**Pausable**                 |Minting only   |Full       |Full        |
|**Upgradeable**              |❌ Fixed        |✅ Proxy    |✅ Proxy     |
|**Multi-Sig**                |✅ Gnosis Safe  |✅          |✅           |
|**On-Chain Reserve Tracking**|✅              |❌          |❌           |
|**Role Separation**          |5 roles        |2 roles    |3 roles     |
|**Reserve Attestation**      |On-chain events|Off-chain  |Attestations|

**Key Differentiators:**

- ✅ More transparent on-chain reserve tracking
- ✅ Greater role separation (5 vs 2-3)
- ✅ Non-upgradeable (no proxy risk)
- ✅ User-friendly pause (transfers always work)

-----

## 13. Compliance & Legal

### 13.1 Regulatory Alignment

**Compliance Features:**

- ✅ OFAC/AML blacklist capability
- ✅ Court-ordered asset freeze capability
- ✅ Transparent reserve attestation
- ✅ Multi-signature governance
- ✅ Audit trail via events
- ✅ Non-upgradeable (code certainty)

**Jurisdictional Considerations:**

- USDTq is designed for global use
- Users responsible for local compliance
- TeamQuant maintains compliance controls
- Cooperation with regulatory requests

### 13.2 Risk Disclosure

**Smart Contract Risks:**

- Code vulnerabilities (mitigated via audits)
- Network congestion (BSC reliability)
- No oracle dependency (manual attestation)

**Financial Risks:**

- Reserve custodian risk
- Depegging risk (mitigated via 1:1 backing)
- Liquidity risk (dependent on market depth)

**Regulatory Risks:**

- Changing stablecoin regulations
- Jurisdictional restrictions
- Compliance requirement evolution

**Operational Risks:**

- Multi-sig key management
- Role holder security
- Coordination complexity

-----

## 14. Community & Support

**Official Channels:**

- 🌐 Website: https://teamquant.space
- 📧 Email: support@teamquant.space
- 🐦 Twitter: @0teamquant0
- 💬 Telegram: t.me/teamquant (upcoming)
- 📊 BscScan: 0xD5Eb307D86EBAc71D743023A622982fF7acA62aE

**Documentation:**

- Smart Contract: BscScan verified source
- Whitepaper: This document
- Technical Docs: docs.teamquant.space (upcoming)
- GitHub: github.com/teamquant (upcoming)

-----

## 15. Conclusion

USDTq represents a comprehensive approach to institutional-grade stablecoin infrastructure. By combining:

- **Regulatory compliance** (blacklist, transparency, audit trails)
- **Security** (multi-sig, role separation, pausable minting)
- **Transparency** (verified contract, reserve attestation, public events)
- **Scalability** (elastic supply, adjustable caps)
- **User protection** (always-active transfers, self-burn capability)

USDTq provides a foundation for the next generation of decentralized financial operations. Whether used for cross-border settlements, DeFi integration, treasury management, or as a building block for future privacy-enhanced protocols, USDTq delivers the stability, compliance, and security required by modern digital finance.

-----

**Document Version:** 1.0  
**Last Updated:** January 19, 2026  
**Contract Address:** `0xD5Eb307D86EBAc71D743023A622982fF7acA62aE`  
**Network:** BNB Smart Chain (BSC)  
**Verification:** BscScan Verified ✓

-----

## Appendix: Technical Constants

**Role Identifiers (Keccak256 Hashes):**

```solidity
DEFAULT_ADMIN_ROLE = 0x0000000000000000000000000000000000000000000000000000000000000000

ADMIN_ROLE = 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775

MINTER_ROLE = 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6

BLACKLISTER_ROLE = 0x98db8a220cd0f09badce9f22d0ba7e93edb3d404448cc3560d391ab096ad16e9

PAUSER_ROLE = 0x65d7a28e3265b37a6474929f336521b332c1681b933f6cb9f3376673440d862a

RESERVE_MANAGER_ROLE = 0xcc938097bd07c9f1619d5e95c26b457140e80b889795c7c1cbd51a28005e02ac
```

-----

**Disclaimer:** This whitepaper is for informational purposes only and does not constitute financial, investment, or legal advice. USDTq is a utility token intended for use as a medium of exchange. Users should conduct their own research and consult with qualified professionals before using USDTq. TeamQuant makes no warranties regarding the accuracy or completeness of this information.

**© 2026 TeamQuant. All rights reserved.**
