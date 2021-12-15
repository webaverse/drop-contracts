//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
pragma abicoder v2; // required to accept structs as function parameters

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../utils/WBVRSVoucher.sol";

contract WebaverseERC721 is WBVRSVoucher, ERC721Enumerable, Ownable {
    //Base URI of the collection for Webaverse
    string public baseURI;

    // mapping to store the URIs of all the NFTs
    mapping(uint256 => string) private _tokenURIs;

    uint256 public currentTokenId;

    event URI(uint256 id, string uri);
    event Claim(address signer, address claimer, uint256 indexed id);
    event ExternalClaim(
        address indexed externalContract,
        address signer,
        address claimer,
        uint256 indexed id
    );

    constructor() ERC721("WebaverseNFT", "WBVRS") {
        baseURI = "https://gateway.pinata.cloud/ipfs/";
    }

    // Update or change the Base URI of the collection for Webaverse NFTs
    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
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
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI;

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @notice Mints the a single NFT with given parameters.
     * @param account The address on which the NFT will be minted.
     * @param uri The URL of the NFT.
     * @notice 'tokenId' must be unique and must not overlap any existing tokenId.
     * @notice 'uri' should be a metadata json object stored on IPFS or HTTP server.
     **/
    function mint(address account, string memory uri) public returns (uint256) {
        uint256 tokenId = getNextTokenId();
        _mint(account, tokenId);
        setTokenURI(tokenId, uri);
        _incrementTokenId();
        return tokenId;
    }

    /**
     * @notice Mints the a single NFT with given parameters.
     * @param account The address on which the NFT will be minted.
     * @param cid The URL of the NFT.
     * @notice 'tokenId' must be unique and must not overlap any existing tokenId.
     * @notice 'uri' should be a metadata json object stored on IPFS or HTTP server.
     **/
    function mintBatch(
        address account,
        uint256 tokenCount,
        string memory cid
    ) public onlyOwner {
        uint256[] memory ids = new uint256[](tokenCount);
        string[] memory uris = new string[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            ids[i] = getNextTokenId();
            uris[i] = string(
                abi.encodePacked(cid, "/", Strings.toString(i + 1), ".json")
            );
            _mint(account, ids[i]);
            _incrementTokenId();
        }
        setBatchURI(ids, uris);
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
        emit Claim(signer, claimer, voucher.tokenId);
        return voucher.tokenId;
    }

    /**
     * @notice Redeems an NFTVoucher for an actual NFT, authorized by the owner from an external contract.
     * @param claimer The address of the account which will receive the NFT upon success.
     * @param externalContractAddress The address of the contract from which the token is being transferred
     * @param voucher A signed NFTVoucher that describes the NFT to be redeemed.
     * @dev Verification through ECDSA signature of 'typed' data.
     * @dev Voucher must contain valid signature, nonce, and expiry.
     **/
    function externalClaim(
        address claimer,
        address externalContractAddress,
        NFTVoucher calldata voucher
    ) public returns (uint256) {
        IERC721 externalContract = IERC721(externalContractAddress);
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
        emit ExternalClaim(
            externalContractAddress,
            signer,
            claimer,
            voucher.tokenId
        );
        return voucher.tokenId;
    }

    /**
     * @notice Use the mapping _tokenURIs for storing the URIs of NFTs.
     * @param tokenId The address of the account which will receive the NFT upon success.
     * @param uri The URL of the NFT, through which the content of the NFT can be accessed.
     * @dev Token must be minted before setting the URI.
     **/
    function setTokenURI(uint256 tokenId, string memory uri) public {
        require(
            _msgSender() == owner() || _msgSender() == ownerOf(tokenId),
            "ERC721: Caller is not the owner"
        );
        require(_exists(tokenId), "ERC721: Setting URI for non-existent token");
        require(bytes(uri).length > 2, "ERC721: Invalid URI provided");
        _tokenURIs[tokenId] = uri;
        emit URI(tokenId, string(abi.encodePacked(baseURI, uri)));
    }

    function setBatchURI(uint256[] memory ids, string[] memory uris) public {
        for (uint256 i = 0; i < ids.length; i++) {
            setTokenURI(ids[i], uris[i]);
            emit URI(ids[i], uris[i]);
        }
    }

    function getNextTokenId() public view returns (uint256) {
        return currentTokenId + 1;
    }

    /**
     * @dev increments the value of _currentTokenId
     */
    function _incrementTokenId() internal {
        currentTokenId++;
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
        override(ERC721Enumerable)
        returns (bool)
    {
        return ERC721.supportsInterface(interfaceId);
    }
}
