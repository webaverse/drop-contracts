### Install Instruction:

> yarn install

### To run the frontend:

> yarn run dev

### To recomplie and deploy on rinkeby:

> truffle migrate --network rinkeby

Add your secret mnemonic to a .secret file in the root directory.

Note: After the contract is deployed please update the smart contract address in src/main.ts file

## Application Work Flow: (network rinkeby)

### Create claimable Voucher:

1. Choose metamask wallet address (make sure this adress has already minted the tokenID in the contract)
2. Enter token ID
3. Press "create voucher" button to create the voucher

### Claim the voucher:

1. Choose metamask wallet address from which you want to claim the NFT drop
2. Enter the tokenID (of the same token for which the voucher was created)
3. Press "Reddem an NFT" button to claim the NFT

### To run the tests:

> npm run test

_Check metamask transaction confirmation inorder to verify the transfer on chain._
