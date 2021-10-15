//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.0;
pragma abicoder v2; // required to accept structs as function parameters

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract WebaverseVoucher is ERC721URIStorage, EIP712 {
    string private constant SIGNING_DOMAIN = "Webaverse-voucher";
    string private constant SIGNATURE_VERSION = "1";

    // mapping to store the bunred nonces for the signers to prevent replay attacks
    mapping(uint256 => bool) public burnedNonces;

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION)
    {}

    // Represents a schema to claim an NFT, which has already been minted on blockchain. A signed voucher can be redeemed for a real NFT using the claim function.
    struct NFTVoucher {
        // The id of the token to be redeemed. Must be unique - if another token with this ID already exists, the claim function will revert.
        uint256 tokenId;
        // The valid nonce value of the NFT creator, fetched through _nonces mapping.
        uint256 nonce;
        // The time period for which the voucher is valid.
        uint256 expiry;
        // The EIP-712 signature of all other fields in the NFTVoucher struct. For a voucher to be valid, it must be signed by the owner account.
        bytes signature;
    }

    /**
     * @notice Redeems an NFTVoucher for an actual NFT, authorized by the owner.
     * @param claimer The address of the account which will receive the NFT upon success.
     * @param voucher A signed NFTVoucher that describes the NFT to be redeemed.
     * @dev Verification through ECDSA signature of 'typed' data.
     * @dev Voucher must contain valid signature, nonce, and expiry.
     **/
    function claim(address claimer, NFTVoucher calldata voucher)
        public
        returns (uint256)
    {
        // make sure signature is valid and get the address of the signer
        address signer = _verify(voucher);

        require(
            signer == ownerOf(voucher.tokenId),
            "Authorization failed: Invalid signature"
        );

        require(
            block.timestamp <= voucher.expiry,
            "Voucher has already expired"
        );

        require(burnedNonces[voucher.nonce] == false, "Invalid nonce value");
        // transfer the token to the claimer
        _transfer(signer, claimer, voucher.tokenId);
        burnedNonces[voucher.nonce] = true;
        return voucher.tokenId;
    }

    /**
     * @notice Redeems an NFTVoucher for an actual NFT, authorized by the owner from an external contract.
     * @param claimer The address of the account which will receive the NFT upon success.
     * @param contractAddress The address of the contract from which the token is being transferred
     * @param voucher A signed NFTVoucher that describes the NFT to be redeemed.
     * @dev Verification through ECDSA signature of 'typed' data.
     * @dev Voucher must contain valid signature, nonce, and expiry.
     **/
    function externalClaim(
        address claimer,
        address contractAddress,
        NFTVoucher calldata voucher
    ) public returns (uint256) {
        IERC721 externalContractAddress = IERC721(contractAddress);
        // make sure signature is valid and get the address of the signer
        address signer = _verify(voucher);

        require(
            signer == externalContractAddress.ownerOf(voucher.tokenId),
            "Authorization failed: Invalid signature"
        );
        require(
            externalContractAddress.getApproved(voucher.tokenId) ==
                address(this),
            "This contract has no approval for this token"
        );
        require(
            block.timestamp <= voucher.expiry,
            "Voucher has already expired"
        );
        require(!burnedNonces[voucher.nonce], "Invalid nonce value");

        // transfer the token to the claimer
        externalContractAddress.transferFrom(signer, claimer, voucher.tokenId);
        burnedNonces[voucher.nonce] = true;
        return voucher.tokenId;
    }

    /**
     * @notice Returns a hash of the given NFTVoucher, prepared using EIP712 typed data hashing rules.
     * @param voucher An NFTVoucher to hash.
     * @return bytes32 digest of the voucher used for the verification of the signature.
     **/
    function _hash(NFTVoucher calldata voucher)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "NFTVoucher(uint256 tokenId,uint256 nonce,uint256 expiry)"
                        ),
                        voucher.tokenId,
                        voucher.nonce,
                        voucher.expiry
                    )
                )
            );
    }

    /**
     * @notice Verifies the signature for a given NFTVoucher, returning the address of the signer.
     * @param voucher An NFTVoucher describing an NFT.
     * @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
     * @return returns the address of the signer on succesful verification.
     **/
    function _verify(NFTVoucher calldata voucher)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hash(voucher);
        return ECDSA.recover(digest, voucher.signature);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721)
        returns (bool)
    {
        return ERC721.supportsInterface(interfaceId);
    }
}
