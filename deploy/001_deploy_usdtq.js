/**
 * @title USDTq Deployment Script
 * @notice Deploys the non-upgradeable USDTq stablecoin contract
 * @dev Uses hardhat-deploy for deterministic deployments
 *
 * IMPORTANT: Update the addresses below before deploying to mainnet!
 */

module.exports = async ({ getNamedAccounts, deployments, network }) => {
    const { deploy, log } = deployments;
    const { deployer } = await getNamedAccounts();

    log("----------------------------------------------------");
    log(`Deploying USDTq to ${network.name}...`);
    log(`Deployer: ${deployer}`);

    // ============================================================
    // DEPLOYMENT CONFIGURATION - UPDATE BEFORE MAINNET DEPLOYMENT
    // ============================================================

    // For local/testnet: use deployer as placeholder
    // For mainnet: replace with actual Gnosis Safe address
    const isMainnet = network.name === "bsc_mainnet";

    let gnosisSafeAddress;
    let minterSigners;
    let blacklisterSigners;
    let pauserSigners;
    let reserveManagerSigners;

    if (isMainnet) {
        // MAINNET CONFIGURATION
        // TODO: Replace with actual production addresses
        gnosisSafeAddress = process.env.GNOSIS_SAFE_ADDRESS;
        minterSigners = process.env.MINTER_SIGNERS?.split(",") || [];
        blacklisterSigners = process.env.BLACKLISTER_SIGNERS?.split(",") || [];
        pauserSigners = process.env.PAUSER_SIGNERS?.split(",") || [];
        reserveManagerSigners =
            process.env.RESERVE_MANAGER_SIGNERS?.split(",") || [];

        // Validate mainnet configuration
        if (!gnosisSafeAddress || gnosisSafeAddress === "") {
            throw new Error(
                "GNOSIS_SAFE_ADDRESS must be set for mainnet deployment"
            );
        }
        if (minterSigners.length === 0) {
            throw new Error(
                "MINTER_SIGNERS must be set for mainnet deployment"
            );
        }
        if (blacklisterSigners.length === 0) {
            throw new Error(
                "BLACKLISTER_SIGNERS must be set for mainnet deployment"
            );
        }
        if (pauserSigners.length === 0) {
            throw new Error(
                "PAUSER_SIGNERS must be set for mainnet deployment"
            );
        }
        if (reserveManagerSigners.length === 0) {
            throw new Error(
                "RESERVE_MANAGER_SIGNERS must be set for mainnet deployment"
            );
        }
    } else {
        // TESTNET/LOCAL CONFIGURATION
        // Uses deployer account for all roles (testing only)
        const signers = await ethers.getSigners();

        gnosisSafeAddress = signers[0]?.address || deployer;
        minterSigners = [signers[1]?.address || deployer];
        blacklisterSigners = [signers[2]?.address || deployer];
        pauserSigners = [signers[3]?.address || deployer];
        reserveManagerSigners = [signers[4]?.address || deployer];
    }

    // Log configuration
    log("Configuration:");
    log(`  Gnosis Safe: ${gnosisSafeAddress}`);
    log(`  Minters: ${minterSigners.join(", ")}`);
    log(`  Blacklisters: ${blacklisterSigners.join(", ")}`);
    log(`  Pausers: ${pauserSigners.join(", ")}`);
    log(`  Reserve Managers: ${reserveManagerSigners.join(", ")}`);

    // ============================================================
    // DEPLOYMENT
    // ============================================================

    const constructorArgs = [
        gnosisSafeAddress,
        minterSigners,
        blacklisterSigners,
        pauserSigners,
        reserveManagerSigners,
    ];

    const usdtqDeployment = await deploy("USDTq", {
        from: deployer,
        args: constructorArgs,
        log: true,
        waitConfirmations: network.name === "hardhat" ? 1 : 3,
    });

    log("----------------------------------------------------");
    log(`USDTq deployed at: ${usdtqDeployment.address}`);
    log(`Transaction hash: ${usdtqDeployment.transactionHash}`);
    log("----------------------------------------------------");

    // ============================================================
    // POST-DEPLOYMENT VERIFICATION
    // ============================================================

    if (network.name !== "hardhat" && network.name !== "localhost") {
        log("Verifying deployment...");

        const usdtq = await ethers.getContractAt(
            "USDTq",
            usdtqDeployment.address
        );

        // Verify basic parameters
        const name = await usdtq.name();
        const symbol = await usdtq.symbol();
        const decimals = await usdtq.decimals();
        const totalSupply = await usdtq.totalSupply();

        log(`  Name: ${name}`);
        log(`  Symbol: ${symbol}`);
        log(`  Decimals: ${decimals}`);
        log(`  Total Supply: ${ethers.formatUnits(totalSupply, 6)} USDTq`);

        // Verify Gnosis Safe balance
        const safeBalance = await usdtq.balanceOf(gnosisSafeAddress);
        log(
            `  Gnosis Safe Balance: ${ethers.formatUnits(safeBalance, 6)} USDTq`
        );

        log("Deployment verification complete!");
    }

    // ============================================================
    // SAVE DEPLOYMENT ARTIFACTS
    // ============================================================

    const deploymentArtifact = {
        network: network.name,
        chainId: network.config.chainId,
        contractAddress: usdtqDeployment.address,
        deploymentTx: usdtqDeployment.transactionHash,
        deployer: deployer,
        timestamp: new Date().toISOString(),
        constructorArgs: {
            gnosisSafe: gnosisSafeAddress,
            minterSigners: minterSigners,
            blacklisterSigners: blacklisterSigners,
            pauserSigners: pauserSigners,
            reserveManagerSigners: reserveManagerSigners,
        },
    };

    log("Deployment artifact:");
    log(JSON.stringify(deploymentArtifact, null, 2));

    return usdtqDeployment;
};

module.exports.tags = ["USDTq", "stablecoin"];
