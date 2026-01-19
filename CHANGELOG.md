# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- CoinMarketCap listing
- CoinGecko listing
- Trust Wallet logo submission
- External security audit (Q3 2026)
- CEX listings

## [1.0.0] - 2026-01-19

### Deployed
- **Contract Address**: [`0xD5Eb307D86EBAc71D743023A622982fF7acA62aE`](https://bscscan.com/address/0xD5Eb307D86EBAc71D743023A622982fF7acA62aE)
- **Gnosis Safe**: [`0xB00d4Ac55748ED6cB404C38027a46D2AB1b22A19`](https://bscscan.com/address/0xB00d4Ac55748ED6cB404C38027a46D2AB1b22A19)
- **Network**: BNB Smart Chain (BSC) Mainnet
- **Security Score**: SolidityScan 93.65/100

### Added
- **USDTq Token Contract**: BEP-20 compliant stablecoin with 6 decimals
- **Role-Based Access Control**: Six distinct roles for separation of duties
  - `DEFAULT_ADMIN_ROLE`: Master admin held by Gnosis Safe
  - `ADMIN_ROLE`: Supply cap management
  - `MINTER_ROLE`: Token minting and burning
  - `BLACKLISTER_ROLE`: Compliance and sanctions management
  - `PAUSER_ROLE`: Emergency pause functionality
  - `RESERVE_MANAGER_ROLE`: Reserve attestation reporting
- **Supply Management**:
  - Per-transaction mint limit (`maxMintPerTransaction`)
  - Total supply cap (`maxTotalSupply`)
  - Initial supply: 10,000,000 USDTq
- **Compliance Features**:
  - Blacklist functionality for OFAC/AML compliance
  - Blacklist reason tracking for audit trail
  - Pausable minting (transfers remain active)
- **Reserve Transparency**:
  - On-chain reserve attestation
  - Collateralization ratio tracking
  - Reserve add/remove event logging
- **Gas Optimizations**:
  - Custom errors instead of revert strings
  - Unchecked blocks for safe arithmetic
  - Optimized for BNB Chain deployment

### Security
- Built on OpenZeppelin Contracts v5.x
- Non-upgradeable (immutable) contract design
- Constructor-based role initialization with array length limits
- Comprehensive NatSpec documentation

### Technical
- Solidity 0.8.28
- Hardhat development environment
- Foundry support for additional testing
- Slither static analysis integration

---

## Version History Notes

### Versioning Strategy
- **Major (X.0.0)**: Breaking changes or significant feature additions
- **Minor (0.X.0)**: New features, backward compatible
- **Patch (0.0.X)**: Bug fixes, documentation updates

### Contract Immutability
As USDTq is a non-upgradeable contract, version numbers in this changelog refer to:
1. Documentation and tooling updates
2. Test suite improvements
3. Deployment configurations

New contract features would require deploying a new contract version.
