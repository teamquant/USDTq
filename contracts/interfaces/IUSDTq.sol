// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
 * @title IUSDTq - Interface for USDTq Stablecoin
 * @author teamquant.space
 * @notice Interface defining the public functions of the USDTq stablecoin contract
 * @dev This interface can be used by external contracts to interact with USDTq
 */
interface IUSDTq {
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

    /// @notice Emitted when reserves are updated
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

    // ============ Role Constants ============
    // solhint-disable-next-line func-name-mixedcase
    function ADMIN_ROLE() external view returns (bytes32);
    // solhint-disable-next-line func-name-mixedcase
    function MINTER_ROLE() external view returns (bytes32);
    // solhint-disable-next-line func-name-mixedcase
    function BLACKLISTER_ROLE() external view returns (bytes32);
    // solhint-disable-next-line func-name-mixedcase
    function PAUSER_ROLE() external view returns (bytes32);
    // solhint-disable-next-line func-name-mixedcase
    function RESERVE_MANAGER_ROLE() external view returns (bytes32);

    // ============ State Variables ============

    function maxMintPerTransaction() external view returns (uint256);
    function maxTotalSupply() external view returns (uint256);
    function totalReserves() external view returns (uint256);
    function lastReserveUpdate() external view returns (uint256);

    // ============ Minting Functions ============

    /**
     * @notice Mint tokens to an address (only authorized minters)
     * @param to Address to receive minted tokens
     * @param amount Amount to mint (6 decimals)
     */
    function mint(address to, uint256 amount) external;

    /**
     * @notice Burn tokens from an address (only authorized minters)
     * @param from Address to burn tokens from
     * @param amount Amount to burn
     */
    function burnFrom(address from, uint256 amount) external;

    // ============ Supply Management ============

    /**
     * @notice Update maximum mint per transaction
     * @param newLimit New maximum mint amount per transaction
     */
    function setMaxMintPerTransaction(uint256 newLimit) external;

    /**
     * @notice Update maximum total supply cap
     * @param newLimit New maximum total supply
     */
    function setMaxTotalSupply(uint256 newLimit) external;

    // ============ Reserve Management ============

    /**
     * @notice Update reserve attestation
     * @param newReserveAmount Total reserves in USD equivalent (6 decimals)
     */
    function updateReserves(uint256 newReserveAmount) external;

    /**
     * @notice Record reserve addition
     * @param amount Amount of reserves added (6 decimals)
     * @param reserveType Type of reserve (e.g., "USDT", "USDC", "Mixed")
     */
    function addReserves(uint256 amount, string calldata reserveType) external;

    /**
     * @notice Record reserve removal
     * @param amount Amount of reserves removed (6 decimals)
     * @param reason Reason for removal
     */
    function removeReserves(uint256 amount, string calldata reason) external;

    // ============ Blacklist Functions ============

    /**
     * @notice Add an address to the blacklist
     * @param account Address to blacklist
     * @param reason Reason for blacklisting
     */
    function blacklist(address account, string calldata reason) external;

    /**
     * @notice Remove an address from the blacklist
     * @param account Address to unblacklist
     */
    function unBlacklist(address account) external;

    /**
     * @notice Check if an address is blacklisted
     * @param account Address to check
     * @return bool True if address is blacklisted
     */
    function isBlacklisted(address account) external view returns (bool);

    /**
     * @notice Get the reason why an address was blacklisted
     * @param account Address to check
     * @return string Blacklist reason
     */
    function blacklistReason(address account) external view returns (string memory);

    // ============ Pause Functions ============

    /**
     * @notice Pause minting operations
     */
    function pause() external;

    /**
     * @notice Unpause minting operations
     */
    function unpause() external;

    // ============ View Functions ============

    /**
     * @notice Get remaining mint capacity
     * @return perTxRemaining Amount available for next single transaction
     * @return totalRemaining Amount available before hitting supply cap
     */
    function getRemainingMintCapacity() external view returns (uint256 perTxRemaining, uint256 totalRemaining);

    /**
     * @notice Get current collateralization ratio
     * @return ratio Collateralization in basis points (10000 = 100%)
     * @return reserves Total reserves in USD equivalent
     * @return supply Current circulating supply
     */
    function getCollateralizationRatio() external view returns (uint256 ratio, uint256 reserves, uint256 supply);

    /**
     * @notice Get reserve health status
     * @return isHealthy True if reserves >= supply
     * @return reserveDeficit Amount of reserve shortfall (0 if healthy)
     * @return reserveSurplus Amount of reserve excess (0 if deficit exists)
     */
    function getReserveHealth() external view returns (bool isHealthy, uint256 reserveDeficit, uint256 reserveSurplus);
}
