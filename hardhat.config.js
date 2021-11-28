require("dotenv").config({ path: "./.env" });
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
var env = process.env.NODE_ENV || "sidechain";
const config = require("./config")[env];
const network = config.network;

module.exports = {
    defaultNetwork: network,
    networks: {
        hardhat: {},
        rinkeby: {
            url: "https://rinkeby.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161",
            accounts: [config.priv_key],
            gas: 2100000,
        },
        sidechain: {
            url: "http://13.57.177.184:8545",
            chainId: 1338,
            accounts: [config.priv_key],
            gas: 2100000,
        },
    },
    solidity: {
        version: "0.8.7",
        // settings: {
        //     optimizer: {
        //         enabled: true,
        //         runs: 200,
        //     },
        // },
    },
    paths: {
        sources: "./contracts",
        tests: "./test",
        cache: "./cache",
        artifacts: "./build",
    },
    mocha: {
        timeout: 20000,
    },
    environment: {
        chainId: config.chainId,
    },
    etherscan: {
        // Your API key for Etherscan
        // Obtain one at https://etherscan.io/
        apiKey: "1W2RA3EXUF3KBGJ2USHXZCNRE75PDKDJNS",
    },
};
