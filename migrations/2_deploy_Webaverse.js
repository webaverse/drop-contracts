const { ethers, upgrades } = require("hardhat");
async function main() {
    // const WebaverseERC721Factory = await ethers.getContractFactory("WebaverseERC721");
    // const WebaverseERC721 = await WebaverseERC721Factory.deploy("WebaverseERC721", "WBVRS-NFT", "");
    // await WebaverseERC721.deployed();
    // console.log("WebaverseERC721 deployed to:", WebaverseERC721.address);

    // const WebaverseERC20Factory = await ethers.getContractFactory("WebaverseERC20");
    // const WebaverseERC20 = await WebaverseERC20Factory.deploy("WebaverseERC20", "SILK", ethers.utils.parseEther("2147483648"));
    // await WebaverseERC20.deployed();
    // console.log("WebaverseERC20 deployed to:", WebaverseERC20.address);

    const WebaverseFactory = await ethers.getContractFactory("Webaverse");
    const Webaverse = await upgrades.deployProxy(WebaverseFactory, ["0xb6fb5ECe738b8A79AD8A28Bd8f5f7581E348852f", "0x7d205bFe4911d27B1FF1E02Dd3E1238Da714C72E", ethers.utils.parseEther("10"), "0xa6510E349be7786200AC9eDC6443D09FE486Cb40"], {
        initializer: "initialize"
    });
    await Webaverse.deployed();
    console.log("Webaverse deployed to:", Webaverse.address);

    // Upgrade the proxy
    // const WebaverseFactory = await ethers.getContractFactory("Webaverse");
    // const Webaverse = await upgrades.upgradeProxy("0x2253D5914D5Bccbe50652DB4Ed0A1A2B857a60c4", WebaverseFactory, []);
    // await Webaverse.deployed();
    // console.log("Webaverse deployed to:", Webaverse.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
