module.exports = {
    skipFiles: [
        'test/',
        'mocks/',
        'USDTqV1.sol',
        'USDTqV2.sol'
    ],
    configureYulOptimizer: true,
    solcOptimizerDetails: {
        yul: true,
        yulDetails: {
            stackAllocation: true,
        },
    },
    istanbulReporter: ['html', 'lcov', 'text', 'json'],
    mocha: {
        grep: "@skip-coverage",
        invert: true
    },
    // Coverage thresholds - CI will fail if not met
    // These are enforced separately in CI, but documented here for reference
    // Target: 95% lines, 95% statements, 95% functions, 90% branches
};
