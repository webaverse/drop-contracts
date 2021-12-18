require("dotenv").config({ path: "./.env" });
require('@openzeppelin/hardhat-upgrades');
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
var env = process.env.NODE_ENV || "sidechain";
const config = require("./config")[env];
const network = config.network;

module.exports = {
    defaultNetwork: network,
    networks: {
        hardhat: {
            seeds: [config.mnemonic],
            gas: 2100000,
        },
        rinkeby: {
            url: `https://rinkeby.infura.io/v3/${config.infura_key}`,
            accounts: [config.priv_key],
            gas: 2100000,
        },
        sidechain: {
            url: "http://54.219.247.220:8545/",
            chainId: 1338,
            accounts: [config.priv_key],
            gas: 2100000,
        },
    },
    solidity: {
        version: "0.8.7",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            },
        },
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
        apiKey: config.etherscan_api_key,
    },
};
