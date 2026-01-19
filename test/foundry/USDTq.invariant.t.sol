// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "forge-std/StdInvariant.sol";
import "../../contracts/USDTq.sol";

/**
 * @title USDTq Invariant Tests
 * @notice Invariant testing suite for USDTq stablecoin
 * @dev Run with: forge test -vvv --match-contract USDTqInvariantTest
 */
contract USDTqHandler is Test {
    USDTq public usdtq;

    address public gnosisSafe;
    address public minter;
    address public blacklister;
    address public reserveManager;

    address[] public actors;
    address internal currentActor;

    uint256 public ghost_mintedSum;
    uint256 public ghost_burnedSum;

    modifier useActor(uint256 actorIndexSeed) {
        currentActor = actors[bound(actorIndexSeed, 0, actors.length - 1)];
        vm.startPrank(currentActor);
        _;
        vm.stopPrank();
    }

    constructor(
        USDTq _usdtq,
        address _gnosisSafe,
        address _minter,
        address _blacklister,
        address _reserveManager
    ) {
        usdtq = _usdtq;
        gnosisSafe = _gnosisSafe;
        minter = _minter;
        blacklister = _blacklister;
        reserveManager = _reserveManager;

        // Initialize actors
        actors.push(gnosisSafe);
        actors.push(makeAddr("actor1"));
        actors.push(makeAddr("actor2"));
        actors.push(makeAddr("actor3"));

        // Give initial tokens to actors
        vm.startPrank(gnosisSafe);
        for (uint256 i = 1; i < actors.length; i++) {
            usdtq.transfer(actors[i], 1_000_000 * 10 ** 6);
        }
        vm.stopPrank();
    }

    function mint(uint256 actorSeed, uint256 amount) external {
        amount = bound(amount, 1, usdtq.maxMintPerTransaction());

        address to = actors[bound(actorSeed, 0, actors.length - 1)];

        // Skip if would exceed max supply
        if (usdtq.totalSupply() + amount > usdtq.maxTotalSupply()) {
            return;
        }

        // Skip if recipient is blacklisted
        if (usdtq.isBlacklisted(to)) {
            return;
        }

        vm.prank(minter);
        usdtq.mint(to, amount);

        ghost_mintedSum += amount;
    }

    function burn(uint256 actorSeed, uint256 amount) external {
        address from = actors[bound(actorSeed, 0, actors.length - 1)];
        uint256 balance = usdtq.balanceOf(from);

        if (balance == 0) return;

        amount = bound(amount, 1, balance);

        vm.prank(from);
        usdtq.approve(minter, amount);

        vm.prank(minter);
        usdtq.burnFrom(from, amount);

        ghost_burnedSum += amount;
    }

    function transfer(uint256 fromSeed, uint256 toSeed, uint256 amount) external {
        address from = actors[bound(fromSeed, 0, actors.length - 1)];
        address to = actors[bound(toSeed, 0, actors.length - 1)];

        if (from == to) return;

        uint256 balance = usdtq.balanceOf(from);
        if (balance == 0) return;

        amount = bound(amount, 1, balance);

        // Skip if either party is blacklisted
        if (usdtq.isBlacklisted(from) || usdtq.isBlacklisted(to)) {
            return;
        }

        vm.prank(from);
        usdtq.transfer(to, amount);
    }

    function addReserves(uint256 amount) external {
        amount = bound(amount, 1, 1_000_000_000 * 10 ** 6);

        vm.prank(reserveManager);
        usdtq.addReserves(amount, "USDC");
    }

    function removeReserves(uint256 amount) external {
        uint256 currentReserves = usdtq.totalReserves();
        if (currentReserves == 0) return;

        amount = bound(amount, 1, currentReserves);

        vm.prank(reserveManager);
        usdtq.removeReserves(amount, "Withdrawal");
    }
}

contract USDTqInvariantTest is StdInvariant, Test {
    USDTq public usdtq;
    USDTqHandler public handler;

    address public gnosisSafe;
    address public minter;
    address public blacklister;
    address public pauser;
    address public reserveManager;

    uint256 constant INITIAL_SUPPLY = 10_000_000 * 10 ** 6;

    function setUp() public {
        gnosisSafe = makeAddr("gnosisSafe");
        minter = makeAddr("minter");
        blacklister = makeAddr("blacklister");
        pauser = makeAddr("pauser");
        reserveManager = makeAddr("reserveManager");

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

        handler = new USDTqHandler(
            usdtq,
            gnosisSafe,
            minter,
            blacklister,
            reserveManager
        );

        targetContract(address(handler));
    }

    /**
     * @notice Invariant: Total supply should never exceed maxTotalSupply
     */
    function invariant_totalSupplyNeverExceedsMax() public view {
        assertLe(usdtq.totalSupply(), usdtq.maxTotalSupply());
    }

    /**
     * @notice Invariant: Sum of all balances equals total supply
     * @dev This is a simplified check - in practice you'd track all holders
     */
    function invariant_supplyMatchesMintedMinusBurned() public view {
        uint256 expectedSupply = INITIAL_SUPPLY + handler.ghost_mintedSum() - handler.ghost_burnedSum();
        assertEq(usdtq.totalSupply(), expectedSupply);
    }

    /**
     * @notice Invariant: Gnosis Safe always has admin roles
     */
    function invariant_gnosisSafeHasAdminRoles() public view {
        assertTrue(usdtq.hasRole(usdtq.DEFAULT_ADMIN_ROLE(), gnosisSafe));
        assertTrue(usdtq.hasRole(usdtq.ADMIN_ROLE(), gnosisSafe));
    }

    /**
     * @notice Invariant: Minter always has minter role
     */
    function invariant_minterHasRole() public view {
        assertTrue(usdtq.hasRole(usdtq.MINTER_ROLE(), minter));
    }

    /**
     * @notice Invariant: maxMintPerTransaction is never zero
     */
    function invariant_maxMintPerTxNonZero() public view {
        assertGt(usdtq.maxMintPerTransaction(), 0);
    }

    /**
     * @notice Invariant: maxTotalSupply is never below current supply
     */
    function invariant_maxSupplyNeverBelowCurrent() public view {
        assertGe(usdtq.maxTotalSupply(), usdtq.totalSupply());
    }

    /**
     * @notice Invariant: Decimals is always 6
     */
    function invariant_decimalsAlways6() public view {
        assertEq(usdtq.decimals(), 6);
    }

    /**
     * @notice Invariant: Name and symbol are immutable
     */
    function invariant_nameAndSymbolImmutable() public view {
        assertEq(usdtq.name(), "USDTq teamquant.space");
        assertEq(usdtq.symbol(), "USDTq");
    }
}
