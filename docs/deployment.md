# USDTq Deployment Guide

This document provides step-by-step instructions for deploying the USDTq stablecoin contract.

## Current Deployment (Mainnet)

| Parameter | Value |
|-----------|-------|
| **Contract Address** | [`0xD5Eb307D86EBAc71D743023A622982fF7acA62aE`](https://bscscan.com/address/0xD5Eb307D86EBAc71D743023A622982fF7acA62aE) |
| **Gnosis Safe** | [`0xB00d4Ac55748ED6cB404C38027a46D2AB1b22A19`](https://bscscan.com/address/0xB00d4Ac55748ED6cB404C38027a46D2AB1b22A19) |
| **Network** | BNB Smart Chain (BSC) Mainnet |
| **Chain ID** | 56 |
| **Deployment Date** | January 2026 |
| **Status** | Verified on BscScan |

## Prerequisites

### Environment Setup

1. **Node.js**: v18 or later
2. **npm**: Latest version
3. **Wallet**: Deployer wallet with sufficient BNB for gas
4. **Gnosis Safe**: Multi-sig wallet created and configured
5. **API Keys**: BscScan API key for verification

### Pre-Deployment Checklist

- [x] Security audit completed (SolidityScan 93.65/100)
- [x] All tests passing (`npm run test`)
- [x] Coverage thresholds met (`npm run test:coverage`)
- [x] Slither analysis clean (`npm run slither`)
- [x] Gnosis Safe deployed and owners confirmed
- [x] Role signer addresses documented
- [x] Deployment parameters reviewed

## Configuration

### 1. Environment Variables

Create `.env` file from template:

```bash
cp .env.example .env
```

Configure the following:

```env
# Deployer private key (without 0x prefix)
PRIVATE_KEY=your_private_key_here

# BscScan API key for contract verification
BSCSCAN_API_KEY=your_bscscan_api_key

# Optional: For gas reporting in USD
COINMARKETCAP_API_KEY=your_coinmarketcap_api_key
```

### 2. Deployment Parameters

For mainnet deployment, configure via environment variables in `.env`:

```env
# Gnosis Safe address (receives admin roles and initial supply)
GNOSIS_SAFE_ADDRESS=0x...

# Role holder addresses (comma-separated, up to 10 each)
MINTER_SIGNERS=0x...,0x...
BLACKLISTER_SIGNERS=0x...
PAUSER_SIGNERS=0x...
RESERVE_MANAGER_SIGNERS=0x...
```

Alternatively, edit the deployment script (`deploy/001_deploy_usdtq.js`) directly.

### Parameter Reference

| Parameter | Description | Constraints |
|-----------|-------------|-------------|
| `gnosisSafeAddress` | Multi-sig wallet for admin control | Must be non-zero |
| `minterSigners` | Addresses authorized to mint/burn | Max 10, non-zero |
| `blacklisterSigners` | Addresses for compliance management | Max 10, non-zero |
| `pauserSigners` | Addresses for emergency pause | Max 10, non-zero |
| `reserveManagerSigners` | Addresses for reserve attestation | Max 10, non-zero |

## Deployment Steps

### Step 1: Testnet Deployment

Always deploy to testnet first.

```bash
# Compile contracts
npm run build

# Deploy to BSC Testnet
npm run deploy:testnet
```

Expected output:
```
----------------------------------------------------
Deploying USDTq...
USDTq deployed at 0x...
----------------------------------------------------
```

### Step 2: Verify on Testnet

```bash
npx hardhat verify --network bsc_testnet <CONTRACT_ADDRESS> \
  "<GNOSIS_SAFE>" \
  "[\"<MINTER_1>\",\"<MINTER_2>\"]" \
  "[\"<BLACKLISTER_1>\"]" \
  "[\"<PAUSER_1>\"]" \
  "[\"<RESERVE_MGR_1>\"]"
```

### Step 3: Testnet Validation

After deployment, verify:

1. **Token Metadata**
   ```javascript
   await usdtq.name(); // "USDTq teamquant.space"
   await usdtq.symbol(); // "USDTq"
   await usdtq.decimals(); // 6
   ```

2. **Initial Supply**
   ```javascript
   await usdtq.totalSupply(); // 10,000,000 * 10^6
   await usdtq.balanceOf(gnosisSafe); // 10,000,000 * 10^6
   ```

3. **Role Assignments**
   ```javascript
   await usdtq.hasRole(DEFAULT_ADMIN_ROLE, gnosisSafe); // true
   await usdtq.hasRole(ADMIN_ROLE, gnosisSafe); // true
   await usdtq.hasRole(MINTER_ROLE, minter); // true
   // etc.
   ```

4. **Supply Caps**
   ```javascript
   await usdtq.maxMintPerTransaction(); // 10,000,000 * 10^6
   await usdtq.maxTotalSupply(); // 1,000,000,000 * 10^6
   ```

5. **Test Operations**
   - Mint tokens (as minter)
   - Transfer tokens
   - Burn tokens
   - Blacklist/unblacklist address
   - Pause/unpause
   - Update reserves

### Step 4: Mainnet Deployment

Once testnet validation is complete:

```bash
# Final compilation check
npm run build

# Deploy to BSC Mainnet
npm run deploy:mainnet
```

### Step 5: Mainnet Verification

```bash
npx hardhat verify --network bsc_mainnet <CONTRACT_ADDRESS> \
  "<GNOSIS_SAFE>" \
  "[\"<MINTER_1>\",\"<MINTER_2>\"]" \
  "[\"<BLACKLISTER_1>\"]" \
  "[\"<PAUSER_1>\"]" \
  "[\"<RESERVE_MGR_1>\"]"
```

### Step 6: Post-Deployment

1. **Document Deployment**
   - Save contract address
   - Save deployment transaction hash
   - Save constructor arguments
   - Update project documentation

2. **Configure Gnosis Safe**
   - Verify role assignments
   - Test multi-sig operations
   - Document signing procedures

3. **Monitoring Setup**
   - Set up event monitoring
   - Configure alerts for critical functions
   - Track token transfers and mints

## Deployment Artifacts

Current mainnet deployment:

```json
{
  "network": "bsc_mainnet",
  "chainId": 56,
  "contractAddress": "0xD5Eb307D86EBAc71D743023A622982fF7acA62aE",
  "gnosisSafe": "0xB00d4Ac55748ED6cB404C38027a46D2AB1b22A19",
  "timestamp": "2026-01",
  "verification": "BscScan Verified",
  "securityScore": "SolidityScan 93.65/100",
  "initialConfig": {
    "name": "USDTq teamquant.space",
    "symbol": "USDTq",
    "decimals": 6,
    "initialSupply": "10000000000000",
    "maxMintPerTransaction": "10000000000000",
    "maxTotalSupply": "1000000000000000"
  }
}
```

## Troubleshooting

### Common Issues

**Deployment fails with "gas estimation failed"**
- Ensure deployer has sufficient BNB
- Check constructor arguments are valid
- Verify network RPC is responsive

**Verification fails**
- Ensure exact constructor arguments match deployment
- Check BscScan API key is valid
- Wait a few blocks before verifying

**Role assignment issues**
- Verify addresses are not zero address
- Check arrays don't exceed 10 elements
- Ensure addresses are checksummed correctly

### Getting Help

- GitHub Issues: [repository]/issues
- Security Issues: security@teamquant.space
- General Support: support@teamquant.space

## Security Reminders

1. **Never share private keys** - Use hardware wallets for mainnet
2. **Double-check addresses** - Verify Gnosis Safe and signer addresses
3. **Test thoroughly** - Complete all testnet validation steps
4. **Document everything** - Keep records of all deployment details
5. **Monitor actively** - Set up alerts for contract events
