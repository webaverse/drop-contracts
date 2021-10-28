require("dotenv").config({ path: "./.env" });

module.exports = {
    testnet: {
        network: "rinkeby",
        chainId: 4,
        mnemonic: process.env.TEST_SECRET,
        priv_key: process.env.PRIVATE_KEY,
        signer_key: process.env.SIGNER_KEY,
        claimer_key: process.env.CLAIMER_PRIVATE_KEY,
        external_signer_key: process.env.EXTERNAL_SIGNER_PRIVATE_KEY,
        infura_key: process.env.INFURA_KEY,
    },
    hardhat: {
        network: "hardhat",
        chainId: 31337,
        priv_key: process.env.PRIVATE_KEY,
    },
};
