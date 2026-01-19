// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "../../contracts/USDTq.sol";

/**
 * @title USDTq Fuzz Tests
 * @notice Fuzz testing suite for USDTq stablecoin
 * @dev Run with: forge test -vvv --match-contract USDTqFuzzTest
 */
contract USDTqFuzzTest is Test {
    USDTq public usdtq;

    address public gnosisSafe;
    address public minter;
    address public blacklister;
    address public pauser;
    address public reserveManager;
    address public user1;
    address public user2;

    uint256 constant DECIMALS = 6;
    uint256 constant INITIAL_SUPPLY = 10_000_000 * 10 ** DECIMALS;
    uint256 constant MAX_TOTAL_SUPPLY = 1_000_000_000 * 10 ** DECIMALS;
    uint256 constant MAX_MINT_PER_TX = 10_000_000 * 10 ** DECIMALS;

    function setUp() public {
        gnosisSafe = makeAddr("gnosisSafe");
        minter = makeAddr("minter");
        blacklister = makeAddr("blacklister");
        pauser = makeAddr("pauser");
        reserveManager = makeAddr("reserveManager");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        address[] memory minters = new address[](1);
        minters[0] = minter;

        address[] memory blacklisters = new address[](1);
        blacklisters[0] = blacklister;

        address[] memory pausers = new address[](1);
        pausers[0] = pauser;

        address[] memory reserveManagers = new address[](1);
        reserveManagers[0] = reserveManager;

        usdtq = new USDTq(
            gnosisSafe,
            minters,
            blacklisters,
            pausers,
            reserveManagers
        );
    }

    // ============ Mint Fuzz Tests ============

    /**
     * @notice Fuzz test: Minting should always respect maxMintPerTransaction
     */
    function testFuzz_MintRespectsPerTxLimit(uint256 amount) public {
        vm.assume(amount > 0 && amount <= MAX_MINT_PER_TX);
        vm.assume(amount + INITIAL_SUPPLY <= MAX_TOTAL_SUPPLY);

        vm.prank(minter);
        usdtq.mint(user1, amount);

        assertEq(usdtq.balanceOf(user1), amount);
    }

    /**
     * @notice Fuzz test: Minting above limit should always revert
     */
    function testFuzz_MintAboveLimitReverts(uint256 amount) public {
        vm.assume(amount > MAX_MINT_PER_TX);

        vm.prank(minter);
        vm.expectRevert(
            abi.encodeWithSelector(
                USDTq.ExceedsMaxMintPerTransaction.selector,
                amount,
                MAX_MINT_PER_TX
            )
        );
        usdtq.mint(user1, amount);
    }

    /**
     * @notice Fuzz test: Total supply should never exceed maxTotalSupply
     */
    function testFuzz_TotalSupplyNeverExceedsMax(uint256 mintAmount) public {
        vm.assume(mintAmount > 0 && mintAmount <= MAX_MINT_PER_TX);

        uint256 currentSupply = usdtq.totalSupply();

        if (currentSupply + mintAmount <= MAX_TOTAL_SUPPLY) {
            vm.prank(minter);
            usdtq.mint(user1, mintAmount);
            assertLe(usdtq.totalSupply(), MAX_TOTAL_SUPPLY);
        } else {
            vm.prank(minter);
            vm.expectRevert();
            usdtq.mint(user1, mintAmount);
        }
    }

    // ============ Transfer Fuzz Tests ============

    /**
     * @notice Fuzz test: Transfer should maintain total supply invariant
     */
    function testFuzz_TransferMaintainsSupply(uint256 amount) public {
        vm.assume(amount > 0 && amount <= INITIAL_SUPPLY);

        uint256 supplyBefore = usdtq.totalSupply();

        vm.prank(gnosisSafe);
        usdtq.transfer(user1, amount);

        assertEq(usdtq.totalSupply(), supplyBefore);
    }

    /**
     * @notice Fuzz test: Transfer should correctly update balances
     */
    function testFuzz_TransferUpdatesBalances(uint256 amount) public {
        vm.assume(amount > 0 && amount <= INITIAL_SUPPLY);

        uint256 senderBalanceBefore = usdtq.balanceOf(gnosisSafe);
        uint256 receiverBalanceBefore = usdtq.balanceOf(user1);

        vm.prank(gnosisSafe);
        usdtq.transfer(user1, amount);

        assertEq(usdtq.balanceOf(gnosisSafe), senderBalanceBefore - amount);
        assertEq(usdtq.balanceOf(user1), receiverBalanceBefore + amount);
    }

    // ============ Burn Fuzz Tests ============

    /**
     * @notice Fuzz test: Burn should correctly reduce supply
     */
    function testFuzz_BurnReducesSupply(uint256 amount) public {
        vm.assume(amount > 0 && amount <= INITIAL_SUPPLY);

        // Transfer to user1 first
        vm.prank(gnosisSafe);
        usdtq.transfer(user1, amount);

        // Approve minter
        vm.prank(user1);
        usdtq.approve(minter, amount);

        uint256 supplyBefore = usdtq.totalSupply();

        vm.prank(minter);
        usdtq.burnFrom(user1, amount);

        assertEq(usdtq.totalSupply(), supplyBefore - amount);
    }

    // ============ Reserve Fuzz Tests ============

    /**
     * @notice Fuzz test: Reserve updates should correctly track amounts
     */
    function testFuzz_ReserveUpdates(uint256 newReserves) public {
        vm.assume(newReserves <= type(uint256).max / 10000); // Prevent overflow in ratio calc

        vm.prank(reserveManager);
        usdtq.updateReserves(newReserves);

        assertEq(usdtq.totalReserves(), newReserves);
    }

    /**
     * @notice Fuzz test: Adding reserves should correctly increase total
     */
    function testFuzz_AddReserves(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount <= type(uint256).max - INITIAL_SUPPLY); // Prevent overflow

        uint256 reservesBefore = usdtq.totalReserves();

        vm.prank(reserveManager);
        usdtq.addReserves(amount, "USDC");

        assertEq(usdtq.totalReserves(), reservesBefore + amount);
    }

    /**
     * @notice Fuzz test: Removing reserves should correctly decrease total
     */
    function testFuzz_RemoveReserves(uint256 amount) public {
        vm.assume(amount > 0 && amount <= INITIAL_SUPPLY);

        uint256 reservesBefore = usdtq.totalReserves();

        vm.prank(reserveManager);
        usdtq.removeReserves(amount, "Withdrawal");

        assertEq(usdtq.totalReserves(), reservesBefore - amount);
    }

    /**
     * @notice Fuzz test: Cannot remove more reserves than available
     */
    function testFuzz_CannotRemoveExcessReserves(uint256 amount) public {
        vm.assume(amount > INITIAL_SUPPLY);

        vm.prank(reserveManager);
        vm.expectRevert(
            abi.encodeWithSelector(
                USDTq.InsufficientReserves.selector,
                amount,
                INITIAL_SUPPLY
            )
        );
        usdtq.removeReserves(amount, "Test");
    }

    // ============ Blacklist Fuzz Tests ============

    /**
     * @notice Fuzz test: Blacklisted addresses cannot transfer
     */
    function testFuzz_BlacklistedCannotTransfer(address target, uint256 amount) public {
        vm.assume(target != address(0));
        vm.assume(target != gnosisSafe);
        vm.assume(amount > 0 && amount <= INITIAL_SUPPLY / 2);

        // Send tokens to target
        vm.prank(gnosisSafe);
        usdtq.transfer(target, amount);

        // Blacklist target
        vm.prank(blacklister);
        usdtq.blacklist(target, "Test");

        // Target should not be able to transfer
        vm.prank(target);
        vm.expectRevert(
            abi.encodeWithSelector(USDTq.AccountBlacklisted.selector, target)
        );
        usdtq.transfer(user2, 1);
    }

    // ============ Supply Cap Fuzz Tests ============

    /**
     * @notice Fuzz test: maxTotalSupply cannot be set below current supply
     */
    function testFuzz_MaxSupplyCannotBeBelowCurrent(uint256 newMax) public {
        vm.assume(newMax < INITIAL_SUPPLY);

        vm.prank(gnosisSafe);
        vm.expectRevert(
            abi.encodeWithSelector(
                USDTq.MaxSupplyBelowCurrentSupply.selector,
                newMax,
                INITIAL_SUPPLY
            )
        );
        usdtq.setMaxTotalSupply(newMax);
    }

    // ============ Collateralization Ratio Tests ============

    /**
     * @notice Fuzz test: Collateralization ratio calculation
     */
    function testFuzz_CollateralizationRatio(uint256 reserveAmount, uint256 mintAmount) public {
        vm.assume(reserveAmount > 0 && reserveAmount <= type(uint256).max / 10000);
        vm.assume(mintAmount > 0 && mintAmount <= MAX_MINT_PER_TX);
        vm.assume(INITIAL_SUPPLY + mintAmount <= MAX_TOTAL_SUPPLY);

        // Mint additional tokens
        vm.prank(minter);
        usdtq.mint(user1, mintAmount);

        // Set reserves
        vm.prank(reserveManager);
        usdtq.updateReserves(reserveAmount);

        (uint256 ratio, uint256 reserves, uint256 supply) = usdtq.getCollateralizationRatio();

        assertEq(reserves, reserveAmount);
        assertEq(supply, INITIAL_SUPPLY + mintAmount);

        // Verify ratio calculation
        uint256 expectedRatio = (reserveAmount * 10000) / (INITIAL_SUPPLY + mintAmount);
        assertEq(ratio, expectedRatio);
    }
}
