//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
pragma abicoder v2; // required to accept structs as function parameters

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../utils/WBVRSVoucher.sol";

contract WebaverseERC721 is WBVRSVoucher, ERC721, Ownable {
    // mapping to store the URIs of all the NFTs
    mapping(uint256 => string) private _tokenURIs;

    constructor() ERC721("WebaverseNFT", "WBVRS") {}

    /**
     * @notice Mints the a single NFT with given parameters.
     * @param account The address on which the NFT will be minted.
     * @param tokenId The integer id of the NFT.
     * @param uri The URL of the NFT.
     * @notice 'tokenId' must be unique and must not overlap any existing tokenId.
     * @notice 'uri' should be a metadata json object stored on IPFS or HTTP server.
     **/
    function mint(
        address account,
        uint256 tokenId,
        string memory uri
    ) public {
        require(!_exists(tokenId), "Error: Token already exists");
        _mint(account, tokenId);
        _setTokenURI(tokenId, uri);
    }

    /**
     * @notice View function that takes the unique tokenId and returns the uri against it.
     * @param tokenId The integer id of the NFT.
     * @dev The token being queried should already exist.
     * @dev URI of the token should already be set.
     * @return 'uri' URL of the the NFT against the given 'tokenId'.
     **/
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "tokenURI: Query for non existent token");
        require(
            bytes(_tokenURIs[tokenId]).length > 0,
            "Error: URI of this token is not set"
        );
        return _tokenURIs[tokenId];
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
        virtual
        returns (uint256)
    {
        // make sure signature is valid and get the address of the signer
        address signer = verifyVoucher(voucher);

        require(
            signer == ownerOf(voucher.tokenId),
            "Authorization failed: Invalid signature"
        );

        // set internal approval for the tokenId on the behalf of the signer
        _approve(address(this), voucher.tokenId);
        // transfer the token to the claimer
        _transfer(signer, claimer, voucher.tokenId);
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
        IERC721 externalContract = IERC721(contractAddress);
        // make sure signature is valid and get the address of the signer
        address signer = verifyVoucher(voucher);

        require(
            signer == externalContract.ownerOf(voucher.tokenId),
            "Authorization failed: Invalid signature"
        );
        require(
            externalContract.getApproved(voucher.tokenId) == address(this),
            "This contract has no approval for this token"
        );

        // transfer the token to the claimer
        externalContract.transferFrom(signer, claimer, voucher.tokenId);
        return voucher.tokenId;
    }

    /**
     * @notice Use the mapping _tokenURIs for storing the URIs of NFTs.
     * @param tokenId The address of the account which will receive the NFT upon success.
     * @param uri The URL of the NFT, through which the content of the NFT can be accessed.
     * @dev Token must be minted before setting the URI.
     **/
    function _setTokenURI(uint256 tokenId, string memory uri) internal virtual {
        require(
            _exists(tokenId),
            "Setting URI for non-existent token not allowed"
        );
        require(
            bytes(_tokenURIs[tokenId]).length == 0,
            "This token's URI already exists"
        );
        _tokenURIs[tokenId] = uri;
    }

    /**
     * @notice Using low level assembly call to fetch the chain id of the blockchain.
     * @return Returns the chain id of the current blockchain.
     **/
    function getChainID() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
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
