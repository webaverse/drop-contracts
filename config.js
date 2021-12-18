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
        Webaverse_contract_address: "0xcb15fF358998817a3dF382A4117ef440F9E1eBc0",
        ERC721_contract_address: "0x64fb265ADDC3F9d6Fb9A2043AAD407198657b7D4",
        ERC20_contract_address: "0x7D673Ef0EF30bEEe95b6aceA74732b1326CAb316"
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
        Webaverse_contract_address: "0xB97f9250e8164b1C5A19b233D744F02b6277cB70",
        ERC721_contract_address: "0x0cE21A5Fa1E3c50AF683c20Ad49C36c6c01316Ea",
        ERC20_contract_address: "0xc3AC15084dd2023F3AcC3aa182eFed8563f7EF6d"
    },
    maticmainnet: {
        network: "maticmainnet",
        chainId: 137,
        priv_key: process.env.PRIVATE_KEY,
        contract_address: "0xACE9277dF1Ca282f6924a731389A5cA9bd91c204"
    }
};
