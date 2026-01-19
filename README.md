<p align="center">
  <img src="assets/image_cb27aedd-171b-4e5e-82bb-ddb448853e18.png" alt="USDTq Logo" width="200">
</p>
# USDTq - TeamQuant Stablecoin

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.28-blue.svg)](https://soliditylang.org/)
[![OpenZeppelin](https://img.shields.io/badge/OpenZeppelin-5.x-blue.svg)](https://openzeppelin.com/contracts/)
[![BscScan](https://img.shields.io/badge/BscScan-Verified-green.svg)](https://bscscan.com/address/0xD5Eb307D86EBAc71D743023A622982fF7acA62aE)
[![Security](https://img.shields.io/badge/SolidityScan-93.65%2F100-brightgreen.svg)](https://solidityscan.com/)

## Overview

USDTq is a reserve-backed BEP-20 stablecoin designed to maintain a 1:1 peg with the US Dollar. Built on OpenZeppelin v5.x, it is deployed on BNB Smart Chain (BSC) with enterprise-grade compliance and security features.

| Contract | Address |
|----------|---------|
| **USDTq Token** | [`0xD5Eb307D86EBAc71D743023A622982fF7acA62aE`](https://bscscan.com/address/0xD5Eb307D86EBAc71D743023A622982fF7acA62aE) |
| **Gnosis Safe** | [`0xB00d4Ac55748ED6cB404C38027a46D2AB1b22A19`](https://bscscan.com/address/0xB00d4Ac55748ED6cB404C38027a46D2AB1b22A19) |

### Key Features

- **1:1 USD Peg**: Fully backed by stablecoin reserves (USDT, USDC)
- **Role-Based Access Control**: Six distinct roles for separation of duties
- **Compliance Ready**: Blacklist functionality for OFAC/AML requirements
- **Reserve Transparency**: On-chain attestation and collateralization tracking
- **Non-Upgradeable**: Immutable contract for maximum trust and predictability
- **Gas Optimized**: Custom errors and optimized for BNB Chain

## Project Structure

```
USDTq/
├── contracts/
│   ├── USDTq.sol              # Main stablecoin contract
│   └── interfaces/
│       └── IUSDTq.sol         # Contract interface
├── deploy/
│   └── 001_deploy_usdtq.js    # Deployment script for USDTq.sol
├── test/
│   ├── USDTq.test.js          # Hardhat test suite
│   └── foundry/               # Foundry fuzz & invariant tests
├── docs/
│   ├── Whitepaper.md          # Complete project whitepaper
│   ├── Architecture.md        # Security architecture
│   ├── Tokenomics.md          # Economic model
│   ├── Security.md            # Security checklist
│   └── deployment.md          # Deployment guide
├── hardhat.config.js          # Hardhat configuration
├── foundry.toml               # Foundry configuration
└── package.json               # Dependencies and scripts
```

## Getting Started

### Prerequisites

- [Node.js](https://nodejs.org/) v18 or later
- [npm](https://www.npmjs.com/) or [Yarn](https://yarnpkg.com/)
- [Foundry](https://book.getfoundry.sh/) (optional, for additional testing)

### Installation

```bash
git clone <repository-url>
cd USDTq
npm install
```

### Environment Setup

Create a `.env` file from the example:

```bash
cp .env.example .env
```

Configure the following variables:

| Variable | Description |
|----------|-------------|
| `PRIVATE_KEY` | Deployer wallet private key (without 0x prefix) |
| `BSCSCAN_API_KEY` | BscScan API key for verification |
| `COINMARKETCAP_API_KEY` | (Optional) For gas reporting in USD |

> **Security Warning**: Never commit `.env` files or expose private keys. Use a dedicated deployment wallet.

## Development

### Compile Contracts

```bash
npm run build
```

### Run Tests

```bash
# Run all tests
npm run test

# Run with gas reporting
REPORT_GAS=true npm run test

# Run with coverage
npm run test:coverage
```

### Linting & Formatting

```bash
# Check for issues
npm run lint

# Auto-format code
npm run format
```

### Static Analysis

```bash
# Run Slither
npm run slither
```

## Deployment

### Local Network

```bash
# Start local node
npx hardhat node

# Deploy (in another terminal)
npx hardhat deploy --network localhost
```

### Testnet (BSC Testnet)

```bash
npm run deploy:testnet
```

### Mainnet (BSC)

```bash
npm run deploy:mainnet
```

> **Important**: Before mainnet deployment, ensure you have:
> 1. Completed security audit
> 2. Tested thoroughly on testnet
> 3. Configured correct Gnosis Safe and signer addresses
> 4. Reviewed deployment parameters

See [docs/deployment.md](docs/deployment.md) for detailed deployment instructions.

## Contract Architecture

### Roles

| Role | Purpose | Holder |
|------|---------|--------|
| `DEFAULT_ADMIN_ROLE` | Grant/revoke all roles | Gnosis Safe |
| `ADMIN_ROLE` | Update supply caps | Gnosis Safe |
| `MINTER_ROLE` | Mint and burn tokens | Operational signer(s) |
| `BLACKLISTER_ROLE` | Manage compliance blacklist | Compliance signer(s) |
| `PAUSER_ROLE` | Emergency pause minting | Security signer(s) |
| `RESERVE_MANAGER_ROLE` | Update reserve attestations | Treasury signer(s) |

### Supply Configuration

| Parameter | Initial Value | Description |
|-----------|---------------|-------------|
| Initial Supply | 10,000,000 USDTq | Minted to Gnosis Safe |
| Max Per Transaction | 10,000,000 USDTq | Per-mint limit |
| Max Total Supply | 1,000,000,000 USDTq | Hard cap |
| Decimals | 6 | Matches USDT/USDC |

## Documentation

- [Whitepaper](docs/Whitepaper.md) - Complete project documentation and technical specifications
- [Architecture](docs/Architecture.md) - Security model and role separation
- [Tokenomics](docs/Tokenomics.md) - Economic model and reserve policy
- [Security](docs/Security.md) - Security checklist and vulnerability analysis
- [Deployment](docs/deployment.md) - Step-by-step deployment guide

## Security

### Reporting Vulnerabilities

Please report security vulnerabilities via email to **security@teamquant.space**. Do not create public GitHub issues for security concerns.

See [SECURITY.md](SECURITY.md) for our full security policy.

### Audits

Security audits will be conducted before mainnet deployment. Audit reports will be published in the `/audits` directory.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Links

- Website: [teamquant.space](https://teamquant.space)
- Documentation: [docs/](docs/)
- Security: [SECURITY.md](SECURITY.md)
