module.exports = {
    env: {
        browser: false,
        es2021: true,
        mocha: true,
        node: true,
    },
    extends: [
        "eslint:recommended",
    ],
    parserOptions: {
        ecmaVersion: "latest",
        sourceType: "module",
    },
    overrides: [
        {
            files: ["hardhat.config.js"],
            globals: { task: true },
        },
        {
            files: ["test/**/*.js"],
            globals: {
                describe: true,
                it: true,
                beforeEach: true,
                before: true,
                after: true,
                afterEach: true,
            },
        },
    ],
    rules: {
        "no-unused-vars": ["warn", {
            argsIgnorePattern: "^_",
            varsIgnorePattern: "^_"
        }],
        "no-console": "off",
        "prefer-const": "error",
        "no-var": "error",
    },
};
