require("dotenv").config({ path: "./.env" });
require("@nomiclabs/hardhat-waffle");
var env = process.env.NODE_ENV || "hardhat";
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
    },
    solidity: {
        version: "0.8.0",
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
};
