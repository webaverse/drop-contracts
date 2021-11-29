const { parseEther } = require("@ethersproject/units");
const { expect } = require("chai");
const { ethers } = require("hardhat");

const { ClaimableVoucher } = require("../lib");

async function deploy() {
    const [signer, claimer, externalSigner, _] = await ethers.getSigners();

    let WebaverseFactory = await ethers.getContractFactory("WebaverseERC20", signer);
    const Webaverse = await WebaverseFactory.deploy();
    await Webaverse.deployed();

    // the redeemerContract is an instance of the contract that's wired up to the redeemer's signing key
    const signerFactory = WebaverseFactory.connect(signer);
    const signerContract = signerFactory.attach(Webaverse.address);

    const claimerFactory = WebaverseFactory.connect(claimer);
    const claimerContract = claimerFactory.attach(Webaverse.address);

    const externalSignerFactory = WebaverseFactory.connect(externalSigner);
    const externalSignerContract = externalSignerFactory.attach(Webaverse.address);

    await signerContract.mint(signer.address, parseEther("100"));

    let ERC20Factory = await ethers.getContractFactory("ERC20Mock");
    const ERC20 = await ERC20Factory.deploy(
        "TEST",
        "test",
        externalSigner.address,
        parseEther("100")
    );
    await ERC20.deployed();

    const externalSignerFactoryERC20 = ERC20Factory.connect(externalSigner);
    const externalSignerERC20 = externalSignerFactoryERC20.attach(ERC20.address);

    const claimerFactoryERC20 = ERC20Factory.connect(claimer);
    const claimerERC20 = claimerFactoryERC20.attach(ERC20.address);

    return {
        signer,
        claimer,
        externalSigner,
        signerContract,
        claimerContract,
        externalSignerContract,
        externalSignerERC20,
        claimerERC20,
    };
}

describe("ERC20: Claim", async function () {
    var balance = parseEther("10");
    var nonce = ethers.BigNumber.from(ethers.utils.randomBytes(4)).toNumber();
    var expiry = ethers.BigNumber.from(Math.round(+new Date() / 1000)).toNumber();
    context("With valid signature, valid nonce, valid expiry", async function () {
        it("Should redeem ERC20 tokens from a signed voucher", async function () {
            const { signer, claimer, signerContract, claimerContract } = await deploy();
            const claimableVoucher = new ClaimableVoucher({
                contract: signerContract,
                signer: signer,
            });

            // check if event transfer is emitted
            const voucher = await claimableVoucher.createVoucher(0, balance, nonce, expiry + 10000);

            await expect(claimerContract.claim(claimer.address, voucher))
                .to.emit(claimerContract, "Transfer") // transfer from minter to redeemer
                .withArgs(signer.address, claimer.address, balance);
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
                0,
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
                0,
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
            let voucher = await claimableVoucher.createVoucher(0, balance, nonce, expiry + 1000);
            await claimerContract.claim(claimer.address, voucher);

            claimableVoucher = new ClaimableVoucher({
                contract: claimerContract,
                signer: claimer,
            });
            voucher = await claimableVoucher.createVoucher(0, balance, nonce, expiry + 1000);
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
                0,
                balance,
                nonce + 1,
                expiry + 1000
            );
            voucher.tokenId = 0;
            await expect(claimerContract.claim(claimer.address, voucher)).to.be.revertedWith(
                "Authorization failed: Invalid signature"
            );
        });
    });
});

describe("ERC20: externalClaim", async function () {
    let balance = 1;
    var nonce = ethers.BigNumber.from(ethers.utils.randomBytes(4)).toNumber();
    var expiry = ethers.BigNumber.from(Math.round(+new Date() / 1000)).toNumber();
    context("With valid signature, valid nonce, valid expiry", async function () {
        it("Should redeem an NFT from a signed voucher", async function () {
            const {
                claimer,
                externalSigner,
                claimerContract,
                externalSignerContract,
                externalSignerERC20,
            } = await deploy();

            await externalSignerERC20.approve(externalSignerContract.address, parseEther("10"));

            const claimableVoucher = new ClaimableVoucher({
                contract: externalSignerContract,
                signer: externalSigner,
            });
            const voucher = await claimableVoucher.createVoucher(0, balance, nonce, expiry + 1000);

            //check if event transfer is emitted
            const logs = await claimerContract.externalClaim(
                claimer.address,
                externalSignerERC20.address,
                voucher
            );
            const claimerBalance = await externalSignerERC20.balanceOf(claimer.address);
            await expect(claimerBalance >= voucher.balance);
        });
    });

    context("With invalid signature, invalid nonce, invalid expiry", async function () {
        it("Should fail to redeem an NFT with invalid signature", async function () {
            const {
                claimer,
                externalSigner,
                claimerContract,
                externalSignerContract,
                externalSignerERC20,
            } = await deploy();

            await externalSignerERC20.approve(externalSignerContract.address, parseEther("10"));

            const claimableVoucher = new ClaimableVoucher({
                contract: claimerContract,
                signer: claimer,
            });
            const voucher = await claimableVoucher.createVoucher(0, balance, nonce, expiry + 1000);

            //check if event transfer is emitted
            await expect(
                claimerContract.externalClaim(claimer.address, externalSignerERC20.address, voucher)
            ).to.be.revertedWith("Authorization failed: Invalid signature");
        });

        it("Should fail to redeem an NFT after the expiry has passed", async function () {
            const {
                claimer,
                externalSigner,
                claimerContract,
                externalSignerContract,
                externalSignerERC20,
            } = await deploy();

            await externalSignerERC20.approve(externalSignerContract.address, parseEther("10"));

            const claimableVoucher = new ClaimableVoucher({
                contract: externalSignerContract,
                signer: externalSigner,
            });
            const voucher = await claimableVoucher.createVoucher(0, balance, nonce, expiry - 50);

            //check if event transfer is emitted
            await expect(
                claimerContract.externalClaim(claimer.address, externalSignerERC20.address, voucher)
            ).to.be.revertedWith("Voucher has already expired");
        });

        it("Should fail to redeem an NFT with already used nonce", async function () {
            const {
                claimer,
                externalSigner,
                claimerContract,
                externalSignerContract,
                externalSignerERC20,
                claimerERC20,
            } = await deploy();

            await externalSignerERC20.approve(externalSignerContract.address, parseEther("10"));

            let claimableVoucher = new ClaimableVoucher({
                contract: externalSignerContract,
                signer: externalSigner,
            });
            let voucher = await claimableVoucher.createVoucher(0, balance, nonce, expiry + 1000);
            await claimerContract.externalClaim(
                claimer.address,
                externalSignerERC20.address,
                voucher
            );

            await externalSignerERC20.approve(externalSignerContract.address, parseEther("10"));

            claimableVoucher = new ClaimableVoucher({
                contract: claimerContract,
                signer: claimer,
            });
            voucher = await claimableVoucher.createVoucher(0, balance, nonce, expiry + 1000);

            //check if event transfer is emitted
            await expect(
                claimerContract.externalClaim(claimer.address, externalSignerERC20.address, voucher)
            ).to.be.revertedWith("Invalid nonce value");
        });

        it("Should fail to redeem an NFT with modified voucher", async function () {
            const {
                claimer,
                externalSigner,
                claimerContract,
                externalSignerContract,
                externalSignerERC20,
            } = await deploy();

            await externalSignerERC20.approve(externalSignerContract.address, parseEther("10"));

            const claimableVoucher = new ClaimableVoucher({
                contract: claimerContract,
                signer: claimer,
            });
            let voucher = await claimableVoucher.createVoucher(0, balance, nonce, expiry + 1000);
            voucher.tokenId = 1;
            //check if event transfer is emitted
            await expect(
                claimerContract.externalClaim(claimer.address, externalSignerERC20.address, voucher)
            ).to.be.revertedWith("Authorization failed: Invalid signature");
        });
    });
});
