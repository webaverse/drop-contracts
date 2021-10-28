const { ClaimableVoucher } = require('../lib')
import { ethers } from "ethers";
import ABI from '../build/contracts/main/WebaversERC721.sol/WebaverseERC721.json';

declare let window: any;

window.onload = async () => {
    await window.ethereum.enable();
    const contractAddress = "0xb9c67E33f34c4BF882560417Da0D4E3A3E8D000d";
    const provider = new ethers.providers.Web3Provider((window as any).ethereum)
    const signer = provider.getSigner()
    let contract = new ethers.Contract(contractAddress, ABI.abi, signer);
    let voucher: any;

    async function claim(tokenId: number, voucher: any) {
        if (voucher.tokenId === tokenId) {
            try {
                await contract.claim(await signer.getAddress(), voucher);

                contract.on("Transfer", (from, to, tokenId) => {
                    console.log("From : ", from, "To :", to, "Token ID :", tokenId.toNumber());
                    (<HTMLInputElement>document.getElementById("claimText")).innerHTML = "Claimed !";
                });
            } catch (err: any) {
                console.log(err.error.message);
                (<HTMLInputElement>document.getElementById("claimText")).innerHTML = "Error !";
            }
        }
    }


    async function createVocuher(tokenId: number) {
        const claimableVoucher = new ClaimableVoucher({ contract: contract, signer: signer })

        let timestamp = Math.round(new Date().getTime() / 1000) + 1000;
        let nonce = await ethers.BigNumber.from(ethers.utils.randomBytes(4)).toNumber();
        let balance = 0;

        try {
            voucher = await claimableVoucher.createVoucher(tokenId, balance, nonce, timestamp);
            (<HTMLInputElement>document.getElementById("createText")).innerHTML = "Created !";
        } catch (err) {
            (<HTMLInputElement>document.getElementById("createText")).innerHTML = "Error !";
        }

        console.log(voucher)
    }

    document.getElementById("createBtn")?.addEventListener("click", (e) => {
        e.preventDefault()
        let tokenId = (<HTMLInputElement>document.getElementById("transferID")).value;
        createVocuher(parseInt(tokenId));
    })

    document.getElementById("claimBtn")?.addEventListener("click", (e) => {
        e.preventDefault()
        let tokenId = (<HTMLInputElement>document.getElementById("transferID")).value;
        claim(parseInt(tokenId), voucher);
    })
}
