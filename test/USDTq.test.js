const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("USDTq (Non-Upgradeable)", function () {
    let USDTq, usdtq;
    let owner,
        gnosisSafe,
        minter,
        blacklister,
        pauser,
        reserveManager,
        user1,
        user2;

    const DECIMALS = 6;
    const INITIAL_SUPPLY = ethers.parseUnits("10000000", DECIMALS); // 10M
    const MAX_TOTAL_SUPPLY = ethers.parseUnits("1000000000", DECIMALS); // 1B
    const MAX_MINT_PER_TX = ethers.parseUnits("10000000", DECIMALS); // 10M

    // Role hashes
    const DEFAULT_ADMIN_ROLE = ethers.ZeroHash;
    const ADMIN_ROLE = ethers.keccak256(ethers.toUtf8Bytes("ADMIN_ROLE"));
    const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("MINTER_ROLE"));
    const BLACKLISTER_ROLE = ethers.keccak256(
        ethers.toUtf8Bytes("BLACKLISTER_ROLE")
    );
    const PAUSER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("PAUSER_ROLE"));
    const RESERVE_MANAGER_ROLE = ethers.keccak256(
        ethers.toUtf8Bytes("RESERVE_MANAGER_ROLE")
    );

    beforeEach(async function () {
        [
            owner,
            gnosisSafe,
            minter,
            blacklister,
            pauser,
            reserveManager,
            user1,
            user2,
        ] = await ethers.getSigners();

        USDTq = await ethers.getContractFactory("USDTq");

        usdtq = await USDTq.deploy(
            gnosisSafe.address,
            [minter.address],
            [blacklister.address],
            [pauser.address],
            [reserveManager.address]
        );
        await usdtq.waitForDeployment();
    });

    describe("Deployment", function () {
        it("Should set the correct name, symbol, and decimals", async function () {
            expect(await usdtq.name()).to.equal("USDTq teamquant.space");
            expect(await usdtq.symbol()).to.equal("USDTq");
            expect(await usdtq.decimals()).to.equal(DECIMALS);
        });

        it("Should grant DEFAULT_ADMIN_ROLE to Gnosis Safe", async function () {
            expect(await usdtq.hasRole(DEFAULT_ADMIN_ROLE, gnosisSafe.address))
                .to.be.true;
        });

        it("Should grant ADMIN_ROLE to Gnosis Safe", async function () {
            expect(await usdtq.hasRole(ADMIN_ROLE, gnosisSafe.address)).to.be
                .true;
        });

        it("Should grant operational roles correctly", async function () {
            expect(await usdtq.hasRole(MINTER_ROLE, minter.address)).to.be.true;
            expect(await usdtq.hasRole(BLACKLISTER_ROLE, blacklister.address))
                .to.be.true;
            expect(await usdtq.hasRole(PAUSER_ROLE, pauser.address)).to.be.true;
            expect(
                await usdtq.hasRole(
                    RESERVE_MANAGER_ROLE,
                    reserveManager.address
                )
            ).to.be.true;
        });

        it("Should mint the initial supply to the Gnosis Safe", async function () {
            expect(await usdtq.balanceOf(gnosisSafe.address)).to.equal(
                INITIAL_SUPPLY
            );
        });

        it("Should set the correct supply caps", async function () {
            expect(await usdtq.maxTotalSupply()).to.equal(MAX_TOTAL_SUPPLY);
            expect(await usdtq.maxMintPerTransaction()).to.equal(
                MAX_MINT_PER_TX
            );
        });

        it("Should initialize reserves equal to initial supply", async function () {
            expect(await usdtq.totalReserves()).to.equal(INITIAL_SUPPLY);
        });

        it("Should set lastReserveUpdate to deployment timestamp", async function () {
            const lastUpdate = await usdtq.lastReserveUpdate();
            expect(lastUpdate).to.be.gt(0);
        });

        it("Should revert if gnosis safe is zero address", async function () {
            await expect(
                USDTq.deploy(
                    ethers.ZeroAddress,
                    [minter.address],
                    [blacklister.address],
                    [pauser.address],
                    [reserveManager.address]
                )
            ).to.be.revertedWithCustomError(USDTq, "ZeroAddress");
        });

        it("Should revert if too many minter signers", async function () {
            const tooManySigners = Array(11).fill(minter.address);
            await expect(
                USDTq.deploy(
                    gnosisSafe.address,
                    tooManySigners,
                    [blacklister.address],
                    [pauser.address],
                    [reserveManager.address]
                )
            ).to.be.revertedWithCustomError(USDTq, "TooManySigners");
        });

        it("Should revert if too many blacklister signers", async function () {
            const tooManySigners = Array(11).fill(blacklister.address);
            await expect(
                USDTq.deploy(
                    gnosisSafe.address,
                    [minter.address],
                    tooManySigners,
                    [pauser.address],
                    [reserveManager.address]
                )
            ).to.be.revertedWithCustomError(USDTq, "TooManySigners");
        });

        it("Should revert if too many pauser signers", async function () {
            const tooManySigners = Array(11).fill(pauser.address);
            await expect(
                USDTq.deploy(
                    gnosisSafe.address,
                    [minter.address],
                    [blacklister.address],
                    tooManySigners,
                    [reserveManager.address]
                )
            ).to.be.revertedWithCustomError(USDTq, "TooManySigners");
        });

        it("Should revert if too many reserve manager signers", async function () {
            const tooManySigners = Array(11).fill(reserveManager.address);
            await expect(
                USDTq.deploy(
                    gnosisSafe.address,
                    [minter.address],
                    [blacklister.address],
                    [pauser.address],
                    tooManySigners
                )
            ).to.be.revertedWithCustomError(USDTq, "TooManySigners");
        });

        it("Should revert if minter signer is zero address", async function () {
            await expect(
                USDTq.deploy(
                    gnosisSafe.address,
                    [ethers.ZeroAddress],
                    [blacklister.address],
                    [pauser.address],
                    [reserveManager.address]
                )
            ).to.be.revertedWithCustomError(USDTq, "ZeroAddress");
        });

        it("Should revert if blacklister signer is zero address", async function () {
            await expect(
                USDTq.deploy(
                    gnosisSafe.address,
                    [minter.address],
                    [ethers.ZeroAddress],
                    [pauser.address],
                    [reserveManager.address]
                )
            ).to.be.revertedWithCustomError(USDTq, "ZeroAddress");
        });

        it("Should revert if pauser signer is zero address", async function () {
            await expect(
                USDTq.deploy(
                    gnosisSafe.address,
                    [minter.address],
                    [blacklister.address],
                    [ethers.ZeroAddress],
                    [reserveManager.address]
                )
            ).to.be.revertedWithCustomError(USDTq, "ZeroAddress");
        });

        it("Should revert if reserve manager signer is zero address", async function () {
            await expect(
                USDTq.deploy(
                    gnosisSafe.address,
                    [minter.address],
                    [blacklister.address],
                    [pauser.address],
                    [ethers.ZeroAddress]
                )
            ).to.be.revertedWithCustomError(USDTq, "ZeroAddress");
        });

        it("Should allow multiple signers per role", async function () {
            const multiMinter = await USDTq.deploy(
                gnosisSafe.address,
                [minter.address, user1.address],
                [blacklister.address],
                [pauser.address],
                [reserveManager.address]
            );
            await multiMinter.waitForDeployment();

            expect(await multiMinter.hasRole(MINTER_ROLE, minter.address)).to.be
                .true;
            expect(await multiMinter.hasRole(MINTER_ROLE, user1.address)).to.be
                .true;
        });
    });

    describe("Access Control", function () {
        it("Should not allow non-minters to mint", async function () {
            await expect(usdtq.connect(user1).mint(user1.address, 1000)).to.be
                .reverted;
        });

        it("Should not allow non-admins to set supply caps", async function () {
            await expect(
                usdtq.connect(minter).setMaxTotalSupply(MAX_TOTAL_SUPPLY + 1n)
            ).to.be.reverted;
        });

        it("Should not allow non-blacklisters to blacklist", async function () {
            await expect(usdtq.connect(user1).blacklist(user2.address, "Test"))
                .to.be.reverted;
        });

        it("Should not allow non-pausers to pause", async function () {
            await expect(usdtq.connect(user1).pause()).to.be.reverted;
        });

        it("Should not allow non-reserve-managers to update reserves", async function () {
            await expect(usdtq.connect(user1).updateReserves(1000)).to.be
                .reverted;
        });

        it("Should allow Gnosis Safe to grant roles", async function () {
            await usdtq
                .connect(gnosisSafe)
                .grantRole(MINTER_ROLE, user1.address);
            expect(await usdtq.hasRole(MINTER_ROLE, user1.address)).to.be.true;
        });

        it("Should allow Gnosis Safe to revoke roles", async function () {
            await usdtq
                .connect(gnosisSafe)
                .revokeRole(MINTER_ROLE, minter.address);
            expect(await usdtq.hasRole(MINTER_ROLE, minter.address)).to.be
                .false;
        });

        it("Should not allow non-admins to grant roles", async function () {
            await expect(
                usdtq.connect(user1).grantRole(MINTER_ROLE, user2.address)
            ).to.be.reverted;
        });
    });

    describe("Minting", function () {
        it("Should allow minter to mint tokens within limits", async function () {
            const amount = ethers.parseUnits("1000", DECIMALS);
            await usdtq.connect(minter).mint(user1.address, amount);
            expect(await usdtq.balanceOf(user1.address)).to.equal(amount);
        });

        it("Should emit TokensMinted event", async function () {
            const amount = ethers.parseUnits("1000", DECIMALS);
            await expect(usdtq.connect(minter).mint(user1.address, amount))
                .to.emit(usdtq, "TokensMinted")
                .withArgs(minter.address, user1.address, amount);
        });

        it("Should increase total supply after minting", async function () {
            const amount = ethers.parseUnits("1000", DECIMALS);
            const supplyBefore = await usdtq.totalSupply();
            await usdtq.connect(minter).mint(user1.address, amount);
            expect(await usdtq.totalSupply()).to.equal(supplyBefore + amount);
        });

        it("Should fail to mint above maxMintPerTransaction", async function () {
            const amount = MAX_MINT_PER_TX + 1n;
            await expect(
                usdtq.connect(minter).mint(user1.address, amount)
            ).to.be.revertedWithCustomError(
                usdtq,
                "ExceedsMaxMintPerTransaction"
            );
        });

        it("Should fail to mint above maxTotalSupply", async function () {
            // First, increase maxMintPerTransaction to test total supply limit
            await usdtq
                .connect(gnosisSafe)
                .setMaxMintPerTransaction(MAX_TOTAL_SUPPLY);

            const remainingCapacity = MAX_TOTAL_SUPPLY - INITIAL_SUPPLY;
            const excessAmount = remainingCapacity + 1n;

            await expect(
                usdtq.connect(minter).mint(user1.address, excessAmount)
            ).to.be.revertedWithCustomError(usdtq, "ExceedsMaxTotalSupply");
        });

        it("Should fail to mint to zero address", async function () {
            await expect(
                usdtq.connect(minter).mint(ethers.ZeroAddress, 1000)
            ).to.be.revertedWithCustomError(usdtq, "ZeroAddress");
        });

        it("Should fail to mint zero amount", async function () {
            await expect(
                usdtq.connect(minter).mint(user1.address, 0)
            ).to.be.revertedWithCustomError(usdtq, "ZeroAmount");
        });

        it("Should fail to mint to blacklisted address", async function () {
            await usdtq.connect(blacklister).blacklist(user1.address, "Test");
            await expect(
                usdtq.connect(minter).mint(user1.address, 1000)
            ).to.be.revertedWithCustomError(usdtq, "AccountBlacklisted");
        });

        it("Should mint exactly at maxMintPerTransaction limit", async function () {
            await expect(
                usdtq.connect(minter).mint(user1.address, MAX_MINT_PER_TX)
            ).to.not.be.reverted;
        });
    });

    describe("Burning", function () {
        beforeEach(async function () {
            // Transfer some tokens to user1
            const amount = ethers.parseUnits("1000", DECIMALS);
            await usdtq.connect(gnosisSafe).transfer(user1.address, amount);
            // User1 approves minter to burn
            await usdtq.connect(user1).approve(minter.address, amount);
        });

        it("Should allow minter to burn tokens with approval", async function () {
            const amount = ethers.parseUnits("500", DECIMALS);
            await usdtq.connect(minter).burnFrom(user1.address, amount);
            expect(await usdtq.balanceOf(user1.address)).to.equal(
                ethers.parseUnits("500", DECIMALS)
            );
        });

        it("Should emit TokensBurned event", async function () {
            const amount = ethers.parseUnits("500", DECIMALS);
            await expect(usdtq.connect(minter).burnFrom(user1.address, amount))
                .to.emit(usdtq, "TokensBurned")
                .withArgs(minter.address, user1.address, amount);
        });

        it("Should decrease total supply after burning", async function () {
            const amount = ethers.parseUnits("500", DECIMALS);
            const supplyBefore = await usdtq.totalSupply();
            await usdtq.connect(minter).burnFrom(user1.address, amount);
            expect(await usdtq.totalSupply()).to.equal(supplyBefore - amount);
        });

        it("Should fail to burn from zero address", async function () {
            await expect(
                usdtq.connect(minter).burnFrom(ethers.ZeroAddress, 1000)
            ).to.be.revertedWithCustomError(usdtq, "ZeroAddress");
        });

        it("Should fail to burn zero amount", async function () {
            await expect(
                usdtq.connect(minter).burnFrom(user1.address, 0)
            ).to.be.revertedWithCustomError(usdtq, "ZeroAmount");
        });

        it("Should fail to burn without sufficient allowance", async function () {
            const amount = ethers.parseUnits("2000", DECIMALS); // More than approved
            await expect(
                usdtq.connect(minter).burnFrom(user1.address, amount)
            ).to.be.revertedWithCustomError(
                usdtq,
                "ERC20InsufficientAllowance"
            );
        });

        it("Should fail to burn more than balance", async function () {
            // Approve more than balance
            await usdtq
                .connect(user1)
                .approve(minter.address, ethers.parseUnits("2000", DECIMALS));
            await expect(
                usdtq
                    .connect(minter)
                    .burnFrom(
                        user1.address,
                        ethers.parseUnits("1500", DECIMALS)
                    )
            ).to.be.revertedWithCustomError(usdtq, "ERC20InsufficientBalance");
        });
    });

    describe("Blacklisting", function () {
        beforeEach(async function () {
            const amount = ethers.parseUnits("1000", DECIMALS);
            await usdtq.connect(gnosisSafe).transfer(user1.address, amount);
        });

        it("Should allow blacklister to blacklist an address", async function () {
            await usdtq
                .connect(blacklister)
                .blacklist(user1.address, "OFAC sanctions");
            expect(await usdtq.isBlacklisted(user1.address)).to.be.true;
            expect(await usdtq.blacklistReason(user1.address)).to.equal(
                "OFAC sanctions"
            );
        });

        it("Should emit Blacklisted event", async function () {
            await expect(
                usdtq.connect(blacklister).blacklist(user1.address, "Test")
            )
                .to.emit(usdtq, "Blacklisted")
                .withArgs(user1.address, "Test");
        });

        it("Should not allow blacklisted address to send tokens", async function () {
            await usdtq.connect(blacklister).blacklist(user1.address, "Test");
            await expect(
                usdtq.connect(user1).transfer(user2.address, 100)
            ).to.be.revertedWithCustomError(usdtq, "AccountBlacklisted");
        });

        it("Should not allow blacklisted address to receive tokens", async function () {
            await usdtq.connect(blacklister).blacklist(user2.address, "Test");
            await expect(
                usdtq.connect(user1).transfer(user2.address, 100)
            ).to.be.revertedWithCustomError(usdtq, "AccountBlacklisted");
        });

        it("Should allow blacklister to unblacklist an address", async function () {
            await usdtq.connect(blacklister).blacklist(user1.address, "Test");
            await usdtq.connect(blacklister).unBlacklist(user1.address);
            expect(await usdtq.isBlacklisted(user1.address)).to.be.false;
        });

        it("Should emit UnBlacklisted event", async function () {
            await usdtq.connect(blacklister).blacklist(user1.address, "Test");
            await expect(usdtq.connect(blacklister).unBlacklist(user1.address))
                .to.emit(usdtq, "UnBlacklisted")
                .withArgs(user1.address);
        });

        it("Should clear blacklist reason after unblacklisting", async function () {
            await usdtq
                .connect(blacklister)
                .blacklist(user1.address, "Test reason");
            await usdtq.connect(blacklister).unBlacklist(user1.address);
            expect(await usdtq.blacklistReason(user1.address)).to.equal("");
        });

        it("Should allow burning from blacklisted addresses", async function () {
            await usdtq
                .connect(user1)
                .approve(minter.address, ethers.parseUnits("1000", DECIMALS));
            await usdtq.connect(blacklister).blacklist(user1.address, "Test");

            // Burning should still work (compliance burns)
            await expect(
                usdtq
                    .connect(minter)
                    .burnFrom(user1.address, ethers.parseUnits("100", DECIMALS))
            ).to.not.be.reverted;
        });

        it("Should revert when blacklisting zero address", async function () {
            await expect(
                usdtq.connect(blacklister).blacklist(ethers.ZeroAddress, "Test")
            ).to.be.revertedWithCustomError(usdtq, "ZeroAddress");
        });

        it("Should revert when unblacklisting zero address", async function () {
            await expect(
                usdtq.connect(blacklister).unBlacklist(ethers.ZeroAddress)
            ).to.be.revertedWithCustomError(usdtq, "ZeroAddress");
        });

        it("Should allow transfers after unblacklisting", async function () {
            await usdtq.connect(blacklister).blacklist(user1.address, "Test");
            await usdtq.connect(blacklister).unBlacklist(user1.address);

            await expect(usdtq.connect(user1).transfer(user2.address, 100)).to
                .not.be.reverted;
        });
    });

    describe("Pausing", function () {
        it("Should allow pauser to pause", async function () {
            await usdtq.connect(pauser).pause();
            expect(await usdtq.paused()).to.be.true;
        });

        it("Should prevent minting when paused", async function () {
            await usdtq.connect(pauser).pause();
            await expect(
                usdtq.connect(minter).mint(user1.address, 1000)
            ).to.be.revertedWithCustomError(usdtq, "EnforcedPause");
        });

        it("Should allow transfers when paused", async function () {
            const amount = ethers.parseUnits("100", DECIMALS);
            await usdtq.connect(gnosisSafe).transfer(user1.address, amount);

            await usdtq.connect(pauser).pause();

            // Transfers should still work
            await expect(usdtq.connect(user1).transfer(user2.address, amount))
                .to.not.be.reverted;
        });

        it("Should allow burns when paused", async function () {
            const amount = ethers.parseUnits("100", DECIMALS);
            await usdtq.connect(gnosisSafe).transfer(user1.address, amount);
            await usdtq.connect(user1).approve(minter.address, amount);

            await usdtq.connect(pauser).pause();

            // Burns should still work
            await expect(usdtq.connect(minter).burnFrom(user1.address, amount))
                .to.not.be.reverted;
        });

        it("Should allow pauser to unpause", async function () {
            await usdtq.connect(pauser).pause();
            await usdtq.connect(pauser).unpause();
            expect(await usdtq.paused()).to.be.false;
        });

        it("Should allow minting after unpause", async function () {
            await usdtq.connect(pauser).pause();
            await usdtq.connect(pauser).unpause();

            await expect(usdtq.connect(minter).mint(user1.address, 1000)).to.not
                .be.reverted;
        });

        it("Should revert when pausing already paused contract", async function () {
            await usdtq.connect(pauser).pause();
            await expect(
                usdtq.connect(pauser).pause()
            ).to.be.revertedWithCustomError(usdtq, "EnforcedPause");
        });

        it("Should revert when unpausing non-paused contract", async function () {
            await expect(
                usdtq.connect(pauser).unpause()
            ).to.be.revertedWithCustomError(usdtq, "ExpectedPause");
        });
    });

    describe("Supply Management", function () {
        it("Should allow admin to update maxMintPerTransaction", async function () {
            const newLimit = ethers.parseUnits("5000000", DECIMALS);
            await usdtq.connect(gnosisSafe).setMaxMintPerTransaction(newLimit);
            expect(await usdtq.maxMintPerTransaction()).to.equal(newLimit);
        });

        it("Should emit MaxMintPerTransactionUpdated event", async function () {
            const newLimit = ethers.parseUnits("5000000", DECIMALS);
            await expect(
                usdtq.connect(gnosisSafe).setMaxMintPerTransaction(newLimit)
            )
                .to.emit(usdtq, "MaxMintPerTransactionUpdated")
                .withArgs(MAX_MINT_PER_TX, newLimit);
        });

        it("Should allow admin to update maxTotalSupply", async function () {
            const newLimit = ethers.parseUnits("2000000000", DECIMALS);
            await usdtq.connect(gnosisSafe).setMaxTotalSupply(newLimit);
            expect(await usdtq.maxTotalSupply()).to.equal(newLimit);
        });

        it("Should emit MaxTotalSupplyUpdated event", async function () {
            const newLimit = ethers.parseUnits("2000000000", DECIMALS);
            await expect(usdtq.connect(gnosisSafe).setMaxTotalSupply(newLimit))
                .to.emit(usdtq, "MaxTotalSupplyUpdated")
                .withArgs(MAX_TOTAL_SUPPLY, newLimit);
        });

        it("Should not allow setting maxTotalSupply below current supply", async function () {
            const belowCurrentSupply = INITIAL_SUPPLY - 1n;
            await expect(
                usdtq.connect(gnosisSafe).setMaxTotalSupply(belowCurrentSupply)
            ).to.be.revertedWithCustomError(
                usdtq,
                "MaxSupplyBelowCurrentSupply"
            );
        });

        it("Should allow setting maxTotalSupply equal to current supply", async function () {
            await expect(
                usdtq.connect(gnosisSafe).setMaxTotalSupply(INITIAL_SUPPLY)
            ).to.not.be.reverted;
        });

        it("Should not allow setting same maxMintPerTransaction", async function () {
            await expect(
                usdtq
                    .connect(gnosisSafe)
                    .setMaxMintPerTransaction(MAX_MINT_PER_TX)
            ).to.be.revertedWithCustomError(usdtq, "SameValue");
        });

        it("Should not allow setting same maxTotalSupply", async function () {
            await expect(
                usdtq.connect(gnosisSafe).setMaxTotalSupply(MAX_TOTAL_SUPPLY)
            ).to.be.revertedWithCustomError(usdtq, "SameValue");
        });

        it("Should not allow setting zero maxMintPerTransaction", async function () {
            await expect(
                usdtq.connect(gnosisSafe).setMaxMintPerTransaction(0)
            ).to.be.revertedWithCustomError(usdtq, "ZeroAmount");
        });
    });

    describe("Reserve Management", function () {
        it("Should allow reserve manager to update reserves", async function () {
            const newReserves = ethers.parseUnits("15000000", DECIMALS);
            await usdtq.connect(reserveManager).updateReserves(newReserves);
            expect(await usdtq.totalReserves()).to.equal(newReserves);
        });

        it("Should update lastReserveUpdate timestamp", async function () {
            const beforeUpdate = await usdtq.lastReserveUpdate();

            // Advance time
            await ethers.provider.send("evm_increaseTime", [100]);
            await ethers.provider.send("evm_mine", []);

            await usdtq
                .connect(reserveManager)
                .updateReserves(ethers.parseUnits("15000000", DECIMALS));

            const afterUpdate = await usdtq.lastReserveUpdate();
            expect(afterUpdate).to.be.gt(beforeUpdate);
        });

        it("Should emit ReservesUpdated event with correct ratio", async function () {
            const newReserves = ethers.parseUnits("15000000", DECIMALS);
            // ratio = (15M * 10000) / 10M = 15000 (150%)
            await expect(
                usdtq.connect(reserveManager).updateReserves(newReserves)
            )
                .to.emit(usdtq, "ReservesUpdated")
                .withArgs(
                    newReserves,
                    INITIAL_SUPPLY,
                    15000n,
                    reserveManager.address
                );
        });

        it("Should allow reserve manager to add reserves", async function () {
            const addAmount = ethers.parseUnits("5000000", DECIMALS);
            await usdtq.connect(reserveManager).addReserves(addAmount, "USDC");
            expect(await usdtq.totalReserves()).to.equal(
                INITIAL_SUPPLY + addAmount
            );
        });

        it("Should emit ReservesAdded event", async function () {
            const addAmount = ethers.parseUnits("5000000", DECIMALS);
            await expect(
                usdtq.connect(reserveManager).addReserves(addAmount, "USDC")
            )
                .to.emit(usdtq, "ReservesAdded")
                .withArgs(addAmount, "USDC", reserveManager.address);
        });

        it("Should allow reserve manager to remove reserves", async function () {
            const removeAmount = ethers.parseUnits("1000000", DECIMALS);
            await usdtq
                .connect(reserveManager)
                .removeReserves(removeAmount, "Liquidity provision");
            expect(await usdtq.totalReserves()).to.equal(
                INITIAL_SUPPLY - removeAmount
            );
        });

        it("Should emit ReservesRemoved event", async function () {
            const removeAmount = ethers.parseUnits("1000000", DECIMALS);
            await expect(
                usdtq
                    .connect(reserveManager)
                    .removeReserves(removeAmount, "Liquidity")
            )
                .to.emit(usdtq, "ReservesRemoved")
                .withArgs(removeAmount, "Liquidity", reserveManager.address);
        });

        it("Should not allow removing more reserves than available", async function () {
            const excessAmount = INITIAL_SUPPLY + 1n;
            await expect(
                usdtq
                    .connect(reserveManager)
                    .removeReserves(excessAmount, "Test")
            ).to.be.revertedWithCustomError(usdtq, "InsufficientReserves");
        });

        it("Should not allow adding zero reserves", async function () {
            await expect(
                usdtq.connect(reserveManager).addReserves(0, "USDC")
            ).to.be.revertedWithCustomError(usdtq, "ZeroAmount");
        });

        it("Should not allow removing zero reserves", async function () {
            await expect(
                usdtq.connect(reserveManager).removeReserves(0, "Test")
            ).to.be.revertedWithCustomError(usdtq, "ZeroAmount");
        });

        it("Should allow removing all reserves", async function () {
            await usdtq
                .connect(reserveManager)
                .removeReserves(INITIAL_SUPPLY, "Complete withdrawal");
            expect(await usdtq.totalReserves()).to.equal(0);
        });
    });

    describe("View Functions", function () {
        it("Should return correct remaining mint capacity", async function () {
            const [perTx, total] = await usdtq.getRemainingMintCapacity();
            expect(perTx).to.equal(MAX_MINT_PER_TX);
            expect(total).to.equal(MAX_TOTAL_SUPPLY - INITIAL_SUPPLY);
        });

        it("Should update remaining capacity after minting", async function () {
            const mintAmount = ethers.parseUnits("1000000", DECIMALS);
            await usdtq.connect(minter).mint(user1.address, mintAmount);

            const [perTx, total] = await usdtq.getRemainingMintCapacity();
            expect(perTx).to.equal(MAX_MINT_PER_TX);
            expect(total).to.equal(
                MAX_TOTAL_SUPPLY - INITIAL_SUPPLY - mintAmount
            );
        });

        it("Should return correct collateralization ratio at 100%", async function () {
            const [ratio, reserves, supply] =
                await usdtq.getCollateralizationRatio();
            expect(ratio).to.equal(10000n); // 100% = 10000 basis points
            expect(reserves).to.equal(INITIAL_SUPPLY);
            expect(supply).to.equal(INITIAL_SUPPLY);
        });

        it("Should return correct collateralization ratio above 100%", async function () {
            // Add 5M reserves (total 15M reserves vs 10M supply = 150%)
            await usdtq
                .connect(reserveManager)
                .addReserves(ethers.parseUnits("5000000", DECIMALS), "USDT");

            const [ratio, reserves, supply] =
                await usdtq.getCollateralizationRatio();
            expect(ratio).to.equal(15000n); // 150%
        });

        it("Should return correct collateralization ratio below 100%", async function () {
            // Mint 5M more (total 15M supply vs 10M reserves = 66.67%)
            await usdtq
                .connect(minter)
                .mint(user1.address, ethers.parseUnits("5000000", DECIMALS));

            const [ratio, reserves, supply] =
                await usdtq.getCollateralizationRatio();
            expect(ratio).to.equal(6666n); // 66.66%
        });

        it("Should return healthy reserve status when equal", async function () {
            const [isHealthy, deficit, surplus] =
                await usdtq.getReserveHealth();
            expect(isHealthy).to.be.true;
            expect(deficit).to.equal(0);
            expect(surplus).to.equal(0);
        });

        it("Should return deficit when reserves are below supply", async function () {
            // Mint more tokens to create deficit
            await usdtq
                .connect(minter)
                .mint(user1.address, ethers.parseUnits("1000000", DECIMALS));

            const [isHealthy, deficit, surplus] =
                await usdtq.getReserveHealth();
            expect(isHealthy).to.be.false;
            expect(deficit).to.equal(ethers.parseUnits("1000000", DECIMALS));
            expect(surplus).to.equal(0);
        });

        it("Should return surplus when reserves exceed supply", async function () {
            // Add reserves
            const addAmount = ethers.parseUnits("5000000", DECIMALS);
            await usdtq.connect(reserveManager).addReserves(addAmount, "USDT");

            const [isHealthy, deficit, surplus] =
                await usdtq.getReserveHealth();
            expect(isHealthy).to.be.true;
            expect(deficit).to.equal(0);
            expect(surplus).to.equal(addAmount);
        });
    });

    describe("ERC20 Standard", function () {
        beforeEach(async function () {
            const amount = ethers.parseUnits("1000", DECIMALS);
            await usdtq.connect(gnosisSafe).transfer(user1.address, amount);
        });

        it("Should allow standard transfers", async function () {
            const amount = ethers.parseUnits("100", DECIMALS);
            await usdtq.connect(user1).transfer(user2.address, amount);
            expect(await usdtq.balanceOf(user2.address)).to.equal(amount);
        });

        it("Should emit Transfer event", async function () {
            const amount = ethers.parseUnits("100", DECIMALS);
            await expect(usdtq.connect(user1).transfer(user2.address, amount))
                .to.emit(usdtq, "Transfer")
                .withArgs(user1.address, user2.address, amount);
        });

        it("Should allow approvals and transferFrom", async function () {
            const amount = ethers.parseUnits("100", DECIMALS);
            await usdtq.connect(user1).approve(user2.address, amount);
            expect(
                await usdtq.allowance(user1.address, user2.address)
            ).to.equal(amount);

            await usdtq
                .connect(user2)
                .transferFrom(user1.address, user2.address, amount);
            expect(await usdtq.balanceOf(user2.address)).to.equal(amount);
        });

        it("Should emit Approval event", async function () {
            const amount = ethers.parseUnits("100", DECIMALS);
            await expect(usdtq.connect(user1).approve(user2.address, amount))
                .to.emit(usdtq, "Approval")
                .withArgs(user1.address, user2.address, amount);
        });

        it("Should decrease allowance after transferFrom", async function () {
            const approveAmount = ethers.parseUnits("100", DECIMALS);
            const transferAmount = ethers.parseUnits("60", DECIMALS);

            await usdtq.connect(user1).approve(user2.address, approveAmount);
            await usdtq
                .connect(user2)
                .transferFrom(user1.address, user2.address, transferAmount);

            expect(
                await usdtq.allowance(user1.address, user2.address)
            ).to.equal(approveAmount - transferAmount);
        });

        it("Should not allow transfer to zero address", async function () {
            await expect(
                usdtq.connect(user1).transfer(ethers.ZeroAddress, 100)
            ).to.be.revertedWithCustomError(usdtq, "ERC20InvalidReceiver");
        });

        it("Should not allow transfer more than balance", async function () {
            const balance = await usdtq.balanceOf(user1.address);
            await expect(
                usdtq.connect(user1).transfer(user2.address, balance + 1n)
            ).to.be.revertedWithCustomError(usdtq, "ERC20InsufficientBalance");
        });
    });

    describe("Interface Support", function () {
        it("Should support AccessControl interface", async function () {
            // IAccessControl interface ID
            const accessControlInterfaceId = "0x7965db0b";
            expect(await usdtq.supportsInterface(accessControlInterfaceId)).to
                .be.true;
        });

        it("Should not support random interface", async function () {
            const randomInterfaceId = "0x12345678";
            expect(await usdtq.supportsInterface(randomInterfaceId)).to.be
                .false;
        });
    });

    describe("Edge Cases", function () {
        it("Should handle multiple minters", async function () {
            // Grant minter role to user1
            await usdtq
                .connect(gnosisSafe)
                .grantRole(MINTER_ROLE, user1.address);

            // Both should be able to mint
            await expect(usdtq.connect(minter).mint(user2.address, 1000)).to.not
                .be.reverted;
            await expect(usdtq.connect(user1).mint(user2.address, 1000)).to.not
                .be.reverted;
        });

        it("Should handle rapid successive mints", async function () {
            for (let i = 0; i < 5; i++) {
                await usdtq
                    .connect(minter)
                    .mint(user1.address, ethers.parseUnits("1000", DECIMALS));
            }
            expect(await usdtq.balanceOf(user1.address)).to.equal(
                ethers.parseUnits("5000", DECIMALS)
            );
        });

        it("Should handle mint at exactly max per transaction multiple times", async function () {
            // Need to increase max total supply first
            const newMaxSupply = MAX_MINT_PER_TX * 10n + INITIAL_SUPPLY;
            await usdtq.connect(gnosisSafe).setMaxTotalSupply(newMaxSupply);

            await usdtq.connect(minter).mint(user1.address, MAX_MINT_PER_TX);
            await usdtq.connect(minter).mint(user1.address, MAX_MINT_PER_TX);

            expect(await usdtq.balanceOf(user1.address)).to.equal(
                MAX_MINT_PER_TX * 2n
            );
        });
    });
});
