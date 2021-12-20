//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
pragma abicoder v2; // required to accept structs as function parameters

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../utils/WBVRSVoucher.sol";

contract WebaverseERC721 is WBVRSVoucher, ERC721Enumerable, Ownable {
    // Mapping of white listed minters
    mapping(address => bool) private _whitelistedMinters;

    // Base URI of the collection for Webaverse
    string private _WebaBaseURI;

    // Mapping to store the URIs of all the NFTs
    mapping(uint256 => string) private _tokenURIs;

    // State variable for storing the latest minted token id
    uint256 public currentTokenId;

    // Event occuring when a token's URI is added or changed
    event URI(uint256 id, string uri);

    // Event occuring when a token is redeemed by a user in the webaverse world for the native smart contract
    event Claim(address signer, address claimer, uint256 indexed id);

    // Event occuring when a token is redeemed by a user in the webaverse world for the external smart contract
    event ExternalClaim(
        address indexed externalContract,
        address signer,
        address claimer,
        uint256 indexed id
    );

    modifier onlyMinter() {
        require(
            isAllowedMinter(_msgSender()),
            "ERC721: Only white listed minters are allowed to mint"
        );
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI_
    ) ERC721(name, symbol) {
        setBaseURI(baseURI_);
        addMinter(msg.sender);
    }

    /**
     * @return Returns the base URI of the host to fetch the metadata from (default empty).
     */
    function baseURI() public view returns (string memory) {
        return _WebaBaseURI;
    }

    /**
     * @dev Update or change the Base URI of the collection for Webaverse NFTs
     * @param baseURI_ The base URI of the host to fetch the metadata from e.g. https://ipfs.io/ipfs/.
     */
    function setBaseURI(string memory baseURI_) public onlyOwner {
        _WebaBaseURI = baseURI_;
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
        string memory base = baseURI();

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
    function mint(address account, string memory uri)
        public
        onlyMinter
        returns (uint256)
    {
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
    ) public onlyMinter {
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
    function setTokenURI(uint256 tokenId, string memory uri) public onlyMinter {
        require(_exists(tokenId), "ERC721: Setting URI for non-existent token");
        require(bytes(uri).length > 0, "ERC721: Invalid URI provided");
        _tokenURIs[tokenId] = uri;
        emit URI(tokenId, string(abi.encodePacked(baseURI(), uri)));
    }

    /**
     * @dev Sets the URIs for more than 1 tokens in a single batch.
     * @param ids An array of addresses for which the URIs need to be set.
     * @param uris An array of URLs of the NFT, through which the content of the NFT can be accessed.
     * @notice Token must be minted before setting the URI.
     **/
    function setBatchURI(uint256[] memory ids, string[] memory uris) public onlyMinter {
        for (uint256 i = 0; i < ids.length; i++) {
            setTokenURI(ids[i], uris[i]);
            emit URI(ids[i], uris[i]);
        }
    }

    /**
     * @dev Checks if an address is allowed to mint ERC20 tokens
     * @param account address to check for the white listing for
     * @return true if address is allowed to mint
     */
    function isAllowedMinter(address account) public view returns (bool) {
        return _whitelistedMinters[account];
    }

    /**
     * @dev Add an account to the list of accounts allowed to create ERC20 tokens
     * @param minter address to whitelist
     */
    function addMinter(address minter) public onlyOwner {
        require(!isAllowedMinter(minter), "ERC20: Minter already added");
        _whitelistedMinters[minter] = true;
    }

    /**
     * @dev Remove an account from the list of accounts allowed to create ERC20 tokens
     * @param minter address to remove from whitelist
     */
    function removeMinter(address minter) public onlyOwner {
        require(isAllowedMinter(minter), "ERC20: Minter does not exist");
        _whitelistedMinters[minter] = false;
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

    /**@dev Helper function to convert a uint to a string
     * @param _i uint to convert
     * @return _uintAsString string converted from uint
     */
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
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
