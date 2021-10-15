//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.0;
pragma abicoder v2; // required to accept structs as function parameters

import "../utils/NFTVoucher.sol";

contract Webaverse is WebaverseVoucher {
    // mapping to store the URIs of all the NFTs
    mapping(uint256 => string) private _tokenURIs;

    constructor() WebaverseVoucher("WebaverseNFT", "WBVRS") {}

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
        _setURI(tokenId, uri);
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
     * @notice Use the mapping _tokenURIs for storing the URIs of NFTs.
     * @param tokenId The address of the account which will receive the NFT upon success.
     * @param uri The URL of the NFT, through which the content of the NFT can be accessed.
     * @dev Token must be minted before setting the URI.
     **/
    function _setURI(uint256 tokenId, string memory uri) internal virtual {
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
        override(WebaverseVoucher)
        returns (bool)
    {
        return ERC721.supportsInterface(interfaceId);
    }
}
