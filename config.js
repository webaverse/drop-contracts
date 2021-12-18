require("dotenv").config({ path: "./.env" });

module.exports = {
    rinkeby: {
        network: "rinkeby",
        chainId: 4,
        mnemonic: process.env.MNEMONIC,
        priv_key: process.env.PRIVATE_KEY,
        signer_key: process.env.SIGNER_KEY,
        claimer_key: process.env.CLAIMER_PRIVATE_KEY,
        external_signer_key: process.env.EXTERNAL_SIGNER_PRIVATE_KEY,
        infura_key: process.env.INFURA_KEY,
        etherscan_api_key: process.env.ETHERSCAN_API_KEY,
        contract_address: ""
    },
    hardhat: {
        network: "hardhat",
        chainId: 31337,
        mnemonic: process.env.MNEMONIC,
        priv_key: process.env.PRIVATE_KEY,
    },
    sidechain: {
        network: "sidechain",
        chainId: 1338,
        priv_key: process.env.PRIVATE_KEY,
        contract_address: "0x818EA83e5747258b6Bc421C9b8C2147059f42FC8"
    },
    maticmainnet: {
        network: "maticmainnet",
        chainId: 137,
        priv_key: process.env.PRIVATE_KEY,
        contract_address: "0xACE9277dF1Ca282f6924a731389A5cA9bd91c204"
    }
};
