// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
 * @title USDTq - TeamQuant Stablecoin
 * @author teamquant.space
 * @notice Reserve-backed stablecoin maintaining 1:1 peg with USD
 * @dev Built on OpenZeppelin v5.x, optimized for BNB Chain (BSC)
 *      This contract implements a regulated stablecoin with compliance features
 *      including blacklist functionality for OFAC/AML requirements.
 *
 * SECURITY ARCHITECTURE - SEPARATION OF DUTIES:
 * ┌─────────────────────────────────────────────────────────────────┐
 * │ Gnosis Safe Multi-Sig (Master Controller)                       │
 * │ • DEFAULT_ADMIN_ROLE: Grant/revoke all roles                    │
 * │ • ADMIN_ROLE: Update supply caps and parameters                 │
 * │ • Holds initial 10M USDTq supply (reserve backing)              │
 * │ • Can reassign any role via multi-sig vote                      │
 * └─────────────────────────────────────────────────────────────────┘
 *                              │
 *              ┌───────────────┼───────────────┬────────────────┐
 *              ▼               ▼               ▼                ▼
 *      ┌─────────────┐ ┌──────────────┐ ┌─────────────┐ ┌──────────────┐
 *      │ Signer 1    │ │ Signer 2     │ │ Signer 3    │ │ Signer N     │
 *      │ MINTER      │ │ BLACKLISTER  │ │ PAUSER      │ │ RESERVE_MGR  │
 *      │ Mint/Burn   │ │ Compliance   │ │ Emergency   │ │ Attestation  │
 *      └─────────────┘ └──────────────┘ └─────────────┘ └──────────────┘
 *
 * TOKENOMICS:
 * - 1:1 backing with USDT/USDC reserves
 * - Fee earnings distributed through liquidity pools
 * - Transparent on-chain reserve attestation
 * - Initial supply: 10,000,000 USDTq
 * - Adjustable supply caps for scalability
 *
 * FEATURES:
 * - Separated role-based access control for security
 * - Reserve tracking with transparency events
 * - Supply caps (per-transaction + total supply)
 * - Blacklist compliance (OFAC, sanctions, fraud prevention)
 * - Pausable minting only (transfers and burns always active)
 * - Full OpenZeppelin v5.x integration
 * - Fixed contract (non-upgradeable)
 * - Gas-optimized for BSC
 */

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";

contract USDTq is ERC20, ERC20Burnable, AccessControl, Pausable {
    // ============ Access Control Roles ============

    /// @notice Role for administrative functions (supply cap updates)
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /// @notice Role for minting and burning tokens
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @notice Role for blacklisting addresses
    bytes32 public constant BLACKLISTER_ROLE = keccak256("BLACKLISTER_ROLE");

    /// @notice Role for pausing minting operations
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @notice Role for managing reserve attestations
    bytes32 public constant RESERVE_MANAGER_ROLE = keccak256("RESERVE_MANAGER_ROLE");

    // ============ State Variables ============

    /// @notice Mapping of blacklisted addresses for compliance
    mapping(address account => bool isBlacklisted) private _blacklisted;

    /// @notice Reason for blacklisting (for transparency and audit trail)
    mapping(address account => string reason) private _blacklistReason;

    /// @notice Maximum amount that can be minted in a single transaction
    uint256 public maxMintPerTransaction;

    /// @notice Maximum total supply cap
    uint256 public maxTotalSupply;

    /// @notice Total reserves backing the stablecoin (USDT + USDC equivalent)
    uint256 public totalReserves;

    /// @notice Last reserve attestation timestamp
    uint256 public lastReserveUpdate;

    // ============ Events ============

    /// @notice Emitted when an address is blacklisted
    event Blacklisted(address indexed account, string reason);

    /// @notice Emitted when an address is removed from blacklist
    event UnBlacklisted(address indexed account);

    /// @notice Emitted when tokens are minted by an operator
    event TokensMinted(address indexed minter, address indexed to, uint256 amount);

    /// @notice Emitted when tokens are burned by an operator
    event TokensBurned(address indexed burner, address indexed from, uint256 amount);

    /// @notice Emitted when max mint per transaction is updated
    event MaxMintPerTransactionUpdated(uint256 oldLimit, uint256 newLimit);

    /// @notice Emitted when max total supply is updated
    event MaxTotalSupplyUpdated(uint256 oldLimit, uint256 newLimit);

    /// @notice Emitted when reserves are updated (for transparency)
    /// @dev Ratio is in basis points (10000 = 100%)
    event ReservesUpdated(
        uint256 totalReserves,
        uint256 totalSupply,
        uint256 collateralizationRatio,
        address indexed updatedBy
    );

    /// @notice Emitted when reserves are added
    event ReservesAdded(uint256 amount, string reserveType, address indexed addedBy);

    /// @notice Emitted when reserves are removed
    event ReservesRemoved(uint256 amount, string reason, address indexed removedBy);

    // ============ Custom Errors ============

    error AccountBlacklisted(address account);
    error ExceedsMaxMintPerTransaction(uint256 requested, uint256 maximum);
    error ExceedsMaxTotalSupply(uint256 newSupply, uint256 maximum);
    error MaxSupplyBelowCurrentSupply(uint256 proposed, uint256 current);
    error InsufficientReserves(uint256 required, uint256 available);
    error TooManySigners(uint256 provided, uint256 maximum);
    error ZeroAddress();
    error ZeroAmount();
    error SameValue();

    // ============ Constructor ============

    /**
     * @notice Initialize USDTq with separated role assignments for enhanced security
     * @param gnosisSafe Address of Gnosis Safe multi-sig (master admin + reserve holder)
     * @param minterSigners Array of addresses authorized for minting/burning operations
     * @param blacklisterSigners Array of addresses authorized for compliance blacklist
     * @param pauserSigners Array of addresses authorized for emergency pause
     * @param reserveManagerSigners Array of addresses authorized for reserve attestations
     *
     * @dev SECURITY MODEL - Separation of Duties:
     *
     *      Gnosis Safe (Master Admin):
     *      • Holds DEFAULT_ADMIN_ROLE (can grant/revoke all roles)
     *      • Holds ADMIN_ROLE (can update supply caps)
     *      • Receives initial 10M USDTq supply
     *      • Can update any role assignment via multi-sig
     *
     *      Operational Roles (Assigned to Separate Signers):
     *      • MINTER_ROLE: Supply management (mint/burn)
     *      • BLACKLISTER_ROLE: Compliance management
     *      • PAUSER_ROLE: Emergency response
     *      • RESERVE_MANAGER_ROLE: Reserve attestations
     *
     *      This separation ensures no single signer can control all operations,
     *      enhancing security through distributed responsibilities.
     *
     *      All role assignments can be updated later by Gnosis Safe multi-sig.
     *
     * @dev Initial Configuration:
     *      • Supply: 10,000,000 USDTq minted to Gnosis Safe
     *      • Max per tx: 10M USDTq (adjustable)
     *      • Max total: 1B USDTq (adjustable)
     *      • Token: "USDTq teamquant.space" (USDTq), 6 decimals
     *      • Collateralization ratio: 10000 basis points = 100%
     */
    constructor(
        address gnosisSafe,
        address[] memory minterSigners,
        address[] memory blacklisterSigners,
        address[] memory pauserSigners,
        address[] memory reserveManagerSigners
    ) ERC20("USDTq teamquant.space", "USDTq") {
        if (gnosisSafe == address(0)) revert ZeroAddress();

        // Validate array lengths to prevent DoS attacks
        if (minterSigners.length > 10) revert TooManySigners(minterSigners.length, 10);
        if (blacklisterSigners.length > 10) revert TooManySigners(blacklisterSigners.length, 10);
        if (pauserSigners.length > 10) revert TooManySigners(pauserSigners.length, 10);
        if (reserveManagerSigners.length > 10) revert TooManySigners(reserveManagerSigners.length, 10);

        // ============ Grant Master Admin Roles to Gnosis Safe ============
        _grantRole(DEFAULT_ADMIN_ROLE, gnosisSafe);
        _grantRole(ADMIN_ROLE, gnosisSafe);

        // ============ Assign Operational Roles to Separate Signers ============

        // Cache array lengths for gas optimization
        uint256 minterLength = minterSigners.length;
        for (uint256 i = 0; i < minterLength; ) {
            if (minterSigners[i] == address(0)) revert ZeroAddress();
            _grantRole(MINTER_ROLE, minterSigners[i]);
            unchecked {
                ++i;
            }
        }

        uint256 blacklisterLength = blacklisterSigners.length;
        for (uint256 i = 0; i < blacklisterLength; ) {
            if (blacklisterSigners[i] == address(0)) revert ZeroAddress();
            _grantRole(BLACKLISTER_ROLE, blacklisterSigners[i]);
            unchecked {
                ++i;
            }
        }

        uint256 pauserLength = pauserSigners.length;
        for (uint256 i = 0; i < pauserLength; ) {
            if (pauserSigners[i] == address(0)) revert ZeroAddress();
            _grantRole(PAUSER_ROLE, pauserSigners[i]);
            unchecked {
                ++i;
            }
        }

        uint256 reserveMgrLength = reserveManagerSigners.length;
        for (uint256 i = 0; i < reserveMgrLength; ) {
            if (reserveManagerSigners[i] == address(0)) revert ZeroAddress();
            _grantRole(RESERVE_MANAGER_ROLE, reserveManagerSigners[i]);
            unchecked {
                ++i;
            }
        }

        // ============ Initialize Supply Caps ============
        maxMintPerTransaction = 10_000_000 * 1e6; // 10 million per transaction
        maxTotalSupply = 1_000_000_000 * 1e6; // 1 billion total cap

        // ============ Mint Initial Supply to Gnosis Safe ============
        uint256 initialSupply = 10_000_000 * 1e6; // 10 million USDTq
        _mint(gnosisSafe, initialSupply);

        // ============ Initialize Reserve Tracking ============
        totalReserves = initialSupply;
        lastReserveUpdate = block.timestamp;

        // ============ Emit Initial Events ============
        emit TokensMinted(address(0), gnosisSafe, initialSupply);
        emit ReservesUpdated(
            totalReserves,
            initialSupply,
            10000, // 10000 basis points = 100% collateralization
            address(this)
        );
    }

    // ============ Minting Functions ============

    /**
     * @notice Mint tokens to an address (only authorized minters)
     * @param to Address to receive minted tokens
     * @param amount Amount to mint (6 decimals)
     *
     * @dev Only works when contract is not paused
     *      Enforces per-transaction and total supply limits
     *      Prevents minting to blacklisted addresses
     *      Emits TokensMinted event for transparency
     */
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) whenNotPaused {
        if (to == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();
        if (_blacklisted[to]) revert AccountBlacklisted(to);

        if (amount > maxMintPerTransaction) {
            revert ExceedsMaxMintPerTransaction(amount, maxMintPerTransaction);
        }

        uint256 newSupply = totalSupply() + amount;
        if (newSupply > maxTotalSupply) {
            revert ExceedsMaxTotalSupply(newSupply, maxTotalSupply);
        }

        _mint(to, amount);
        emit TokensMinted(msg.sender, to, amount);
    }

    /**
     * @notice Burn tokens from an address (only authorized minters)
     * @param from Address to burn tokens from
     * @param amount Amount to burn
     *
     * @dev Requires approval from token holder (standard ERC20 burn)
     *      Always active even when paused (for user safety)
     *      Emits TokensBurned event for transparency
     */
    function burnFrom(address from, uint256 amount) public override onlyRole(MINTER_ROLE) {
        if (from == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();

        super.burnFrom(from, amount);
        emit TokensBurned(msg.sender, from, amount);
    }

    // ============ Supply Management ============

    /**
     * @notice Update maximum mint per transaction
     * @param newLimit New maximum mint amount per transaction
     *
     * @dev Only callable by admin (Gnosis Safe)
     *      Useful for scaling operations as demand grows
     *      Prevents re-storing the same value to save gas
     */
    function setMaxMintPerTransaction(uint256 newLimit) external onlyRole(ADMIN_ROLE) {
        if (newLimit == 0) revert ZeroAmount();
        if (newLimit == maxMintPerTransaction) revert SameValue();

        uint256 oldLimit = maxMintPerTransaction;
        maxMintPerTransaction = newLimit;

        emit MaxMintPerTransactionUpdated(oldLimit, newLimit);
    }

    /**
     * @notice Update maximum total supply cap
     * @param newLimit New maximum total supply
     *
     * @dev Only callable by admin (Gnosis Safe)
     *      Cannot be set below current supply
     *      Useful for planned supply expansion
     *      Prevents re-storing the same value to save gas
     */
    function setMaxTotalSupply(uint256 newLimit) external onlyRole(ADMIN_ROLE) {
        uint256 currentSupply = totalSupply();

        if (newLimit < currentSupply) {
            revert MaxSupplyBelowCurrentSupply(newLimit, currentSupply);
        }

        if (newLimit == maxTotalSupply) revert SameValue();

        uint256 oldLimit = maxTotalSupply;
        maxTotalSupply = newLimit;

        emit MaxTotalSupplyUpdated(oldLimit, newLimit);
    }

    // ============ Reserve Management & Transparency ============

    /**
     * @notice Update reserve attestation
     * @param newReserveAmount Total reserves in USD equivalent (6 decimals)
     *
     * @dev Only callable by reserve manager
     *      Calculates and emits collateralization ratio in basis points
     *      Purely informational - does not affect token operations
     *      Ratio: 10000 = 100%, 15000 = 150%, etc.
     */
    function updateReserves(uint256 newReserveAmount) external onlyRole(RESERVE_MANAGER_ROLE) {
        totalReserves = newReserveAmount;
        lastReserveUpdate = block.timestamp;

        uint256 currentSupply = totalSupply();
        uint256 collateralizationRatio = currentSupply != 0 ? (newReserveAmount * 10000) / currentSupply : 10000;

        emit ReservesUpdated(newReserveAmount, currentSupply, collateralizationRatio, msg.sender);
    }

    /**
     * @notice Record reserve addition
     * @param amount Amount of reserves added (6 decimals)
     * @param reserveType Type of reserve (e.g., "USDT", "USDC", "Mixed")
     *
     * @dev Only callable by reserve manager
     *      Increases total reserves and emits transparency event
     */
    function addReserves(uint256 amount, string calldata reserveType) external onlyRole(RESERVE_MANAGER_ROLE) {
        if (amount == 0) revert ZeroAmount();

        totalReserves += amount;
        lastReserveUpdate = block.timestamp;

        emit ReservesAdded(amount, reserveType, msg.sender);

        // Emit general update with new ratio
        uint256 currentSupply = totalSupply();
        uint256 collateralizationRatio = currentSupply != 0 ? (totalReserves * 10000) / currentSupply : 10000;

        emit ReservesUpdated(totalReserves, currentSupply, collateralizationRatio, msg.sender);
    }

    /**
     * @notice Record reserve removal
     * @param amount Amount of reserves removed (6 decimals)
     * @param reason Reason for removal (e.g., "Liquidity provision", "Redemption")
     *
     * @dev Only callable by reserve manager
     *      Decreases total reserves and emits transparency event
     */
    function removeReserves(uint256 amount, string calldata reason) external onlyRole(RESERVE_MANAGER_ROLE) {
        if (amount == 0) revert ZeroAmount();

        if (amount > totalReserves) {
            revert InsufficientReserves(amount, totalReserves);
        }

        totalReserves -= amount;
        lastReserveUpdate = block.timestamp;

        emit ReservesRemoved(amount, reason, msg.sender);

        // Emit general update with new ratio
        uint256 currentSupply = totalSupply();
        uint256 collateralizationRatio = currentSupply != 0 ? (totalReserves * 10000) / currentSupply : 10000;

        emit ReservesUpdated(totalReserves, currentSupply, collateralizationRatio, msg.sender);
    }

    // ============ Blacklist Functions ============

    /**
     * @notice Add an address to the blacklist
     * @param account Address to blacklist
     * @param reason Reason for blacklisting (e.g., "OFAC sanctions")
     *
     * @dev Only callable by authorized blacklister
     *      Used for regulatory compliance (OFAC, AML, court orders)
     */
    function blacklist(address account, string calldata reason) external onlyRole(BLACKLISTER_ROLE) {
        if (account == address(0)) revert ZeroAddress();

        _blacklisted[account] = true;
        _blacklistReason[account] = reason;

        emit Blacklisted(account, reason);
    }

    /**
     * @notice Remove an address from the blacklist
     * @param account Address to unblacklist
     *
     * @dev Only callable by authorized blacklister
     *      Uses delete keyword for gas efficiency
     */
    function unBlacklist(address account) external onlyRole(BLACKLISTER_ROLE) {
        if (account == address(0)) revert ZeroAddress();

        delete _blacklisted[account];
        delete _blacklistReason[account];

        emit UnBlacklisted(account);
    }

    /**
     * @notice Check if an address is blacklisted
     * @param account Address to check
     * @return bool True if address is blacklisted
     */
    function isBlacklisted(address account) external view returns (bool) {
        return _blacklisted[account];
    }

    /**
     * @notice Get the reason why an address was blacklisted
     * @param account Address to check
     * @return string Blacklist reason
     */
    function blacklistReason(address account) external view returns (string memory) {
        return _blacklistReason[account];
    }

    // ============ Pause Functions ============

    /**
     * @notice Pause minting operations (emergency use only)
     *
     * @dev Transfers and burns remain active for user protection
     *      Only authorized pauser can execute
     *      Emits Paused event from OpenZeppelin Pausable
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @notice Unpause minting operations
     *
     * @dev Only authorized pauser can execute
     *      Emits Unpaused event from OpenZeppelin Pausable
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // ============ View Functions ============

    /**
     * @notice Get remaining mint capacity
     * @return perTxRemaining Amount available for next single transaction
     * @return totalRemaining Amount available before hitting supply cap
     */
    function getRemainingMintCapacity() external view returns (uint256 perTxRemaining, uint256 totalRemaining) {
        uint256 currentSupply = totalSupply();

        perTxRemaining = maxMintPerTransaction;
        totalRemaining = maxTotalSupply > currentSupply ? maxTotalSupply - currentSupply : 0;
    }

    /**
     * @notice Get current collateralization ratio
     * @return ratio Collateralization in basis points (10000 = 100%)
     * @return reserves Total reserves in USD equivalent
     * @return supply Current circulating supply
     */
    function getCollateralizationRatio() external view returns (uint256 ratio, uint256 reserves, uint256 supply) {
        supply = totalSupply();
        reserves = totalReserves;
        ratio = supply != 0 ? (reserves * 10000) / supply : 10000;
    }

    /**
     * @notice Get reserve health status
     * @return isHealthy True if reserves >= supply (1:1 or over-collateralized)
     * @return reserveDeficit Amount of reserve shortfall (0 if healthy)
     * @return reserveSurplus Amount of reserve excess (0 if deficit exists)
     */
    function getReserveHealth() external view returns (bool isHealthy, uint256 reserveDeficit, uint256 reserveSurplus) {
        uint256 _totalReserves = totalReserves;
        uint256 supply = totalSupply();

        if (_totalReserves >= supply) {
            isHealthy = true;
            reserveSurplus = _totalReserves - supply;
        } else {
            reserveDeficit = supply - _totalReserves;
        }
    }

    // ============ Internal Overrides ============

    /**
     * @notice Internal function to update balances (OpenZeppelin override)
     * @dev Implements blacklist checks for transfers
     *      Prevents blacklisted addresses from sending or receiving
     *      Allows burning from blacklisted addresses for compliance
     *
     * @param from Sender address (address(0) for minting)
     * @param to Receiver address (address(0) for burning)
     * @param amount Token amount
     */
    function _update(address from, address to, uint256 amount) internal override {
        // Regular transfer - check both parties
        if (from != address(0) && to != address(0)) {
            if (_blacklisted[from]) revert AccountBlacklisted(from);
            if (_blacklisted[to]) revert AccountBlacklisted(to);
        }
        // Minting - check receiver only
        else if (from == address(0)) {
            if (_blacklisted[to]) revert AccountBlacklisted(to);
        }
        // Burning - no blacklist check (allows compliance burns)

        super._update(from, to, amount);
    }

    /**
     * @notice Returns the number of decimals used for token amounts
     * @return uint8 Number of decimals (6 for USDTq)
     *
     * @dev Overrides ERC20 default of 18 decimals to match USDT/USDC standard
     */
    function decimals() public pure override returns (uint8) {
        return 6;
    }

    /**
     * @notice Check if interface is supported
     * @dev Required override for AccessControl + ERC20
     * @param interfaceId Interface identifier
     * @return bool True if interface is supported
     */
    function supportsInterface(bytes4 interfaceId) public view override(AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
