// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../utils/WBVRSVoucher.sol";

contract WebaverseERC20 is ERC20, WBVRSVoucher, Ownable {
    constructor() ERC20("WebaverseERC20", "WBVRS") {}

    /**
     * @notice Redeems an NFTVoucher for an actual NFT, authorized by the owner.
     * @param claimer The address of the account which will receive the NFT upon success.
     * @param voucher A signed NFTVoucher that describes the NFT to be redeemed.
     * @dev Verification through ECDSA signature of 'typed' data.
     * @dev Voucher must contain valid signature, nonce, and expiry.
     **/
    function claim(address claimer, NFTVoucher calldata voucher)
        public
        virtual
        returns (uint256)
    {
        // make sure signature is valid and get the address of the signer
        address signer = verifyVoucher(voucher);

        require(
            balanceOf(signer) != 0,
            "WBVRS: Authorization failed: Invalid signature"
        );

        // transfer the token to the claimer
        _transfer(signer, claimer, voucher.balance);
        return voucher.balance;
    }

    /**
     * @notice Redeems an Voucher for actual ERC20 tokens, authorized by the owner from an external contract.
     * @param claimer The address of the account which will receive the balance upon success.
     * @param contractAddress The address of the contract from which the token is being transferred
     * @param voucher A signed Voucher that describes the ERC20 tokens to be redeemed.
     * @dev Verification through ECDSA signature of 'typed' data.
     * @dev Voucher must contain valid signature, nonce, and expiry.
     **/
    function externalClaim(
        address claimer,
        address contractAddress,
        NFTVoucher calldata voucher
    ) public returns (uint256) {
        IERC20 externalContract = IERC20(contractAddress);
        // make sure signature is valid and get the address of the signer
        address signer = verifyVoucher(voucher);

        require(
            externalContract.balanceOf(signer) != 0,
            "WBVRS: Authorization failed: Invalid signature"
        );
        require(
            externalContract.allowance(signer, address(this)) > 0,
            "WBVRS: Aprroval not set for WebaverseERC20"
        );

        // transfer the token to the claimer
        externalContract.transferFrom(signer, claimer, voucher.balance);
        return voucher.balance;
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }
}
