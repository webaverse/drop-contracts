import "dotenv/config";

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
    },
    sidechain: {
        network: "sidechain",
        chainId: 1338,
        priv_key: process.env.PRIVATE_KEY,
    },
    maticmainnet: {
        network: "maticmainnet",
        chainId: 137,
        priv_key: process.env.PRIVATE_KEY,
    }
};
