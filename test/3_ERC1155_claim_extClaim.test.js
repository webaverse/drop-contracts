const { expect } = require("chai");
const { ethers } = require("hardhat");

const { ClaimableVoucher } = require("../lib");

async function deploy() {
    const [signer, claimer, externalSigner, _] = await ethers.getSigners();

    let WebaverseFactory = await ethers.getContractFactory("WebaverseERC1155", signer);
    const Webaverse = await WebaverseFactory.deploy();
    await Webaverse.deployed();

    // the redeemerContract is an instance of the contract that's wired up to the redeemer's signing key
    const signerFactory = WebaverseFactory.connect(signer);
    const signerContract = signerFactory.attach(Webaverse.address);

    const claimerFactory = WebaverseFactory.connect(claimer);
    const claimerContract = claimerFactory.attach(Webaverse.address);

    const externalSignerFactory = WebaverseFactory.connect(externalSigner);
    const externalSignerContract = externalSignerFactory.attach(Webaverse.address);

    await signerContract.mint(signer.address, 1, 1, "abcdef", "0x01");
    await signerContract.mint(signer.address, 2, 1, "xyzder", "0x01");
    await signerContract.mint(signer.address, 3, 1, "qwerty", "0x01");

    let ERC1155Factory = await ethers.getContractFactory("ERC1155Mock");
    const ERC1155 = await ERC1155Factory.deploy("ExampleURI");
    await ERC1155.deployed();

    const externalSignerFactoryERC1155 = ERC1155Factory.connect(externalSigner);
    const externalSignerERC1155 = externalSignerFactoryERC1155.attach(ERC1155.address);

    await externalSignerERC1155.mint(externalSigner.address, 1, 1, "0x01");
    await externalSignerERC1155.mint(externalSigner.address, 2, 1, "0x01");
    await externalSignerERC1155.mint(externalSigner.address, 3, 1, "0x01");

    const claimerFactoryERC1155 = ERC1155Factory.connect(claimer);
    const claimerERC1155 = claimerFactoryERC1155.attach(ERC1155.address);

    return {
        signer,
        claimer,
        externalSigner,
        signerContract,
        claimerContract,
        externalSignerContract,
        externalSignerERC1155,
        claimerERC1155,
    };
}

describe("ERC1155: Claim", async function () {
    var balance = 1;
    var validTokenIds = [1, 2, 3];
    var nonce = ethers.BigNumber.from(ethers.utils.randomBytes(4)).toNumber();
    var expiry = ethers.BigNumber.from(Math.round(+new Date() / 1000)).toNumber();
    context("With valid signature, valid nonce, valid expiry", async function () {
        it("Should redeem an NFT from a signed voucher", async function () {
            const { signer, claimer, signerContract, claimerContract } = await deploy();
            const claimableVoucher = new ClaimableVoucher({
                contract: signerContract,
                signer: signer,
            });
            const voucher = await claimableVoucher.createVoucher(
                validTokenIds[0],
                balance,
                nonce,
                expiry + 1000
            );

            //check if event transfer is emitted
            await expect(claimerContract.claim(claimer.address, voucher))
                .to.emit(claimerContract, "TransferSingle") // transfer from minter to redeemer
                .withArgs(
                    claimer.address,
                    signer.address,
                    claimer.address,
                    validTokenIds[0],
                    balance
                );
        });
    });
    context("With invalid signature, invalid nonce, invalid expiry", async function () {
        it("Should fail to redeem an NFT with invalid signature", async function () {
            const { claimer, claimerContract } = await deploy();
            const claimableVoucher = new ClaimableVoucher({
                contract: claimerContract,
                signer: claimer,
            });
            const voucher = await claimableVoucher.createVoucher(
                validTokenIds[0],
                balance,
                nonce + 1,
                expiry + 1000
            );
            await expect(claimerContract.claim(claimer.address, voucher)).to.be.revertedWith(
                "Authorization failed: Invalid signature"
            );
        });

        it("Should fail to redeem an NFT after the expiry has passed", async function () {
            const { signer, claimer, claimerContract } = await deploy();
            const claimableVoucher = new ClaimableVoucher({
                contract: claimerContract,
                signer: signer,
            });
            const voucher = await claimableVoucher.createVoucher(
                validTokenIds[0],
                balance,
                nonce + 1,
                expiry - 100
            );
            await expect(claimerContract.claim(claimer.address, voucher)).to.be.revertedWith(
                "Voucher has already expired"
            );
        });

        it("Should fail to redeem an NFT with already used nonce", async function () {
            const { signer, claimer, signerContract, claimerContract } = await deploy();
            let claimableVoucher = new ClaimableVoucher({
                contract: claimerContract,
                signer: signer,
            });
            let voucher = await claimableVoucher.createVoucher(
                validTokenIds[0],
                balance,
                nonce,
                expiry + 1000
            );
            await claimerContract.claim(claimer.address, voucher);

            claimableVoucher = new ClaimableVoucher({
                contract: claimerContract,
                signer: claimer,
            });
            voucher = await claimableVoucher.createVoucher(
                validTokenIds[0],
                balance,
                nonce,
                expiry + 1000
            );
            await expect(signerContract.claim(signer.address, voucher)).to.be.revertedWith(
                "Invalid nonce value"
            );
        });

        it("Should fail to redeem an NFT with modified voucher", async function () {
            const { claimer, claimerContract } = await deploy();
            const claimableVoucher = new ClaimableVoucher({
                contract: claimerContract,
                signer: claimer,
            });
            const voucher = await claimableVoucher.createVoucher(
                validTokenIds[0],
                balance,
                nonce + 1,
                expiry + 1000
            );
            voucher.tokenId = validTokenIds[1];
            await expect(claimerContract.claim(claimer.address, voucher)).to.be.revertedWith(
                "Authorization failed: Invalid signature"
            );
        });
    });
});

describe("ERC1155: externalClaim", async function () {
    let balance = 1;
    var validTokenIds = [1, 2, 3];
    var nonce = ethers.BigNumber.from(ethers.utils.randomBytes(4)).toNumber();
    var expiry = ethers.BigNumber.from(Math.round(+new Date() / 1000)).toNumber();
    context("With valid signature, valid nonce, valid expiry", async function () {
        it("Should redeem an NFT from a signed voucher", async function () {
            const {
                claimer,
                externalSigner,
                claimerContract,
                externalSignerContract,
                externalSignerERC1155,
            } = await deploy();

            await externalSignerERC1155.setApprovalForAll(externalSignerContract.address, true);

            const claimableVoucher = new ClaimableVoucher({
                contract: externalSignerContract,
                signer: externalSigner,
            });
            const voucher = await claimableVoucher.createVoucher(
                validTokenIds[0],
                balance,
                nonce,
                expiry + 1000
            );
            //check if event transfer is emitted
            const logs = await claimerContract.externalClaim(
                claimer.address,
                externalSignerERC1155.address,
                voucher
            );
            const claimerBalance = await externalSignerERC1155.balanceOf(
                claimer.address,
                validTokenIds[0]
            );
            await expect(claimerBalance.toNumber() >= 1);
        });
    });

    context("With invalid signature, invalid nonce, invalid expiry", async function () {
        it("Should fail to redeem an NFT with invalid signature", async function () {
            const {
                claimer,
                externalSigner,
                claimerContract,
                externalSignerContract,
                externalSignerERC1155,
            } = await deploy();

            await externalSignerERC1155.setApprovalForAll(externalSignerContract.address, true);

            const claimableVoucher = new ClaimableVoucher({
                contract: claimerContract,
                signer: claimer,
            });
            const voucher = await claimableVoucher.createVoucher(
                validTokenIds[0],
                balance,
                nonce,
                expiry + 1000
            );

            //check if event transfer is emitted
            await expect(
                claimerContract.externalClaim(
                    claimer.address,
                    externalSignerERC1155.address,
                    voucher
                )
            ).to.be.revertedWith("Authorization failed: Invalid signature");
        });

        it("Should fail to redeem an NFT after the expiry has passed", async function () {
            const {
                claimer,
                externalSigner,
                claimerContract,
                externalSignerContract,
                externalSignerERC1155,
            } = await deploy();

            await externalSignerERC1155.setApprovalForAll(externalSignerContract.address, true);

            const claimableVoucher = new ClaimableVoucher({
                contract: externalSignerContract,
                signer: externalSigner,
            });
            const voucher = await claimableVoucher.createVoucher(
                validTokenIds[0],
                balance,
                nonce,
                expiry - 50
            );

            //check if event transfer is emitted
            await expect(
                claimerContract.externalClaim(
                    claimer.address,
                    externalSignerERC1155.address,
                    voucher
                )
            ).to.be.revertedWith("Voucher has already expired");
        });

        it("Should fail to redeem an NFT with already used nonce", async function () {
            const {
                claimer,
                externalSigner,
                claimerContract,
                externalSignerContract,
                externalSignerERC1155,
                claimerERC1155,
            } = await deploy();

            await externalSignerERC1155.setApprovalForAll(externalSignerContract.address, true);

            let claimableVoucher = new ClaimableVoucher({
                contract: externalSignerContract,
                signer: externalSigner,
            });
            let voucher = await claimableVoucher.createVoucher(
                validTokenIds[0],
                balance,
                nonce,
                expiry + 1000
            );
            await claimerContract.externalClaim(
                claimer.address,
                externalSignerERC1155.address,
                voucher
            );

            await claimerERC1155.setApprovalForAll(externalSignerContract.address, true);

            claimableVoucher = new ClaimableVoucher({
                contract: claimerContract,
                signer: claimer,
            });
            voucher = await claimableVoucher.createVoucher(
                validTokenIds[0],
                balance,
                nonce,
                expiry + 1000
            );

            //check if event transfer is emitted
            await expect(
                claimerContract.externalClaim(
                    claimer.address,
                    externalSignerERC1155.address,
                    voucher
                )
            ).to.be.revertedWith("Invalid nonce value");
        });

        it("Should fail to redeem an NFT with modified voucher", async function () {
            const {
                claimer,
                externalSigner,
                claimerContract,
                externalSignerContract,
                externalSignerERC1155,
            } = await deploy();

            await externalSignerERC1155.setApprovalForAll(externalSignerContract.address, true);

            const claimableVoucher = new ClaimableVoucher({
                contract: claimerContract,
                signer: claimer,
            });
            let voucher = await claimableVoucher.createVoucher(
                validTokenIds[0],
                balance,
                nonce,
                expiry + 1000
            );
            voucher.tokenId = 1;
            //check if event transfer is emitted
            await expect(
                claimerContract.externalClaim(
                    claimer.address,
                    externalSignerERC1155.address,
                    voucher
                )
            ).to.be.revertedWith("Authorization failed: Invalid signature");
        });
    });
});
