# drop-contracts

This codebase contains the smart contracts that implement Ethereum's Fungible i.e. ERC20 and, Non Fungible token standards i.e. ERC721, ERC115. Webaverse main app uses these smart contracts for utilizing the features such as `mint`, `drop`, and `redeem` (see [webaverse/app](https://github.com/webaverse/app)). All of the smart contracts follow the Ethereum EIP standards by using the interfaces for all the token standards.

Currently, all the smart contracts reside on the `rinkeby` testnet and webaverse `sidechain`.

## Installation
 
```bash
# Clone the repo
$ git clone https://github.com/webaverse/redis-server.git

# Install the packages and dependencies
$ npm install
```

## Configuration
1. Create a new file `.env` with the given template
```bash
# Infura Project Id
INFURA_KEY = 9bbv673y23cn88cnm73hfqwwbf87zonf

# Private key
PRIVATE_KEY = 8407415743ab6f7214df9fce86e7ad87ce5e0cef82822d1e6622d4043623f473

# Test keys
SIGNER_PRIVATE_KEY = 27b02257623d1fe8ca9594dfef495ad51080e80b84230bd63eea18f33a2a8229
CLAIMER_PRIVATE_KEY = e536bff80ff5d9863cb983fc8cbbc117d53aa142f23c4e02250e93b90a6d751b
EXTERNAL_SIGNER_PRIVATE_KEY = c2d3541a6ac24c67f0312a33d15daf0c0409776fbc092d8f55eee2edbdd7b8bb

# Etherscan API key
ETHERSCAN_API_KEY = 1ERUWBNCIUW8464WBCXBEWEU39CY5L2BD0
```

## Build
```bash
# Compile the smart contracts, artifacts will be stored in the `build/` directory

$ npx hardhat compile
```

## Migrations
```bash
# Deploy the smart contracts on different networks defined in `hardhat.config.js`

$ npx hardhat run migrations/2_deploy_WebaverseERC721.js
```

## Tests
```bash
# Run the tests for all the smart contracts

$ npx hardhat test
```
