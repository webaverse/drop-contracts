const { ethers } = require("hardhat");
async function main() {
    const WebaverseERC721Factory = await ethers.getContractFactory("WebaverseERC721");
    const WebaverseERC721 = await WebaverseERC721Factory.deploy();
    await WebaverseERC721.deployed();
    console.log("WebaverseERC721 deployed to:", WebaverseERC721.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
