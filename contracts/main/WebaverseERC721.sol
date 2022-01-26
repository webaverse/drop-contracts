//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
pragma abicoder v2; // required to accept structs as function parameters

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "../utils/WebaverseVoucher.sol";

contract WebaverseERC721 is
    WebaverseVoucher,
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    mapping(address => bool) private _whitelistedMinters; // Mapping of white listed minters
    string private _WebaBaseURI; // Base URI of the collection for Webaverse
    uint256 public currentTokenId; // State variable for storing the latest minted token id
    bool internal isPublicallyMintable; // whether anyone can mint tokens in this copy of the contract
    mapping(uint256 => string) internal tokenIdToHash; // map of token id to hash it represents
    mapping(string => uint256) internal hashToTokenId; // map of hash to token id it represents
    mapping(string => Metadata[]) internal hashToMetadata; // map of hash to metadata key-value store
    mapping(uint256 => address) internal minters; // map of tokens to minters
    mapping(uint256 => Metadata[]) internal tokenIdToMetadata; // map of token id to metadata key-value store

    struct Metadata {
        string key;
        string value;
    }

    struct Token {
        uint256 id;
        string hash;
        string name;
        string ext;
        address minter;
        address owner;
    }

    event MetadataSet(string hash, string key, string value);
    event SingleMetadataSet(uint256 tokenId, string key, string value);
    event HashUpdate(string oldHash, string newHash);
    event Claim(address signer, address claimer, uint256 indexed id);
    event ExternalClaim(
        address indexed externalContract,
        address signer,
        address claimer,
        uint256 indexed id
    );

    modifier onlyMinter() {
        require(
            isPublicallyMintable || isAllowedMinter(msg.sender),
            "ERC721: unauthorized call"
        );
        _;
    }

    function initialize(
        string memory name,
        string memory symbol,
        string memory baseURI_
    ) public initializer {
        __Ownable_init_unchained();
        __ERC721_init(name, symbol);
        _webaverse_voucher_init();
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
     * @notice Mints a single NFT with given parameters.
     * @param to The address on which the NFT will be minted.
     * @param hash The URL of the NFT.
     * @param name The name of the NFT.
     * @param ext The name of the NFT.
     * @param description The description of the NFT.
     **/
    function mint(
        address to,
        string memory hash,
        string memory name,
        string memory ext,
        string memory description
    ) public onlyMinter returns (uint256) {
        require(hashToTokenId[hash] == 0, "ERC721: token already minted");
        uint256 tokenId = getNextTokenId();
        _mint(to, tokenId);
        setMetadata(hash, "name", name);
        setMetadata(hash, "ext", ext);
        setMetadata(hash, "description", description);
        minters[tokenId] = to;
        tokenIdToHash[tokenId] = hash;
        hashToTokenId[hash] = tokenId;
        _incrementTokenId();
        return tokenId;
    }

    /**
     * @notice Mints the a single NFT with given parameters.
     * @param to The address on which the NFT will be minted.
     * @param hash The IPFS hash of the NFT.
     * @param name The name of the NFT.
     * @param ext The ext of the NFT e.g '.jpeg', '.gif'.
     * @param description The IPFS hash of the NFT.
     **/
    function mintBatch(
        address to,
        string[] memory hash,
        string[] memory name,
        string[] memory ext,
        string[] memory description,
        uint256 tokenCount
    ) public onlyMinter {
        for (uint256 i = 0; i < tokenCount; i++) {
            mint(to, hash[i], name[i], ext[i], description[i]);
        }
    }

    /**
     * @dev Get metadata for the token. Metadata is a key-value store that can be set by owners and collaborators
     * @param hash Token hash to query for metadata
     * @param key Key to query for a value
     * @return Value corresponding to metadata key
     */
    function getMetadata(string memory hash, string memory key)
        public
        view
        returns (string memory)
    {
        for (uint256 i = 0; i < hashToMetadata[hash].length; i++) {
            if (streq(hashToMetadata[hash][i].key, key)) {
                return hashToMetadata[hash][i].value;
            }
        }
        return "";
    }

    /**
     * @dev Set metadata for the token. Metadata is a key-value store that can be set by owners and collaborators
     * @param hash Token hash to add metadata to
     * @param key Key to store value at
     * @param value Value to store
     */
    function setMetadata(
        string memory hash,
        string memory key,
        string memory value
    ) public onlyMinter {
        require(bytes(hash).length > 0, "hash cannot be empty"); // Hash cannot be empty (minting null items)
        bool keyFound = false;
        for (uint256 i = 0; i < hashToMetadata[hash].length; i++) {
            if (streq(hashToMetadata[hash][i].key, key)) {
                hashToMetadata[hash][i].value = value;
                keyFound = true;
                break;
            }
        }
        if (!keyFound) {
            hashToMetadata[hash].push(Metadata(key, value));
        }

        emit MetadataSet(hash, key, value);
    }

    /**
     * @dev Get metadata for a single token (non-hashed)
     * @param tokenId Token hash to add metadata to
     * @param key Key to retrieve value for
     * @return Returns the value stored for the key
     */
    function getSingleMetadata(uint256 tokenId, string memory key)
        public
        view
        returns (string memory)
    {
        for (uint256 i = 0; i < tokenIdToMetadata[tokenId].length; i++) {
            if (streq(tokenIdToMetadata[tokenId][i].key, key)) {
                return tokenIdToMetadata[tokenId][i].value;
            }
        }
        return "";
    }

    /**
     * @dev Set metadata for a single token (non-hashed)
     * @param tokenId Token hash to add metadata to
     * @param key Key to store value at
     * @param value Value to store
     */
    function setSingleMetadata(
        uint256 tokenId,
        string memory key,
        string memory value
    ) public onlyMinter {
        bool keyFound = false;
        for (uint256 i = 0; i < tokenIdToMetadata[tokenId].length; i++) {
            if (streq(tokenIdToMetadata[tokenId][i].key, key)) {
                tokenIdToMetadata[tokenId][i].value = value;
                keyFound = true;
                break;
            }
        }
        if (!keyFound) {
            tokenIdToMetadata[tokenId].push(Metadata(key, value));
        }

        emit SingleMetadataSet(tokenId, key, value);
    }

    /**
     * @notice Get token id from hash
     */
    function getTokenIdFromHash(string memory hash)
        public
        view
        returns (uint256)
    {
        return hashToTokenId[hash];
    }

    /**
     * @notice Get token id from hash
     */
    function getHashFromTokenId(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return tokenIdToHash[tokenId];
    }

    /**
     * @dev Update token hash with a new hash
     * @param oldHash Old hash to query
     * @param newHash New hash to set
     */
    function updateHash(string memory oldHash, string memory newHash)
        public
        onlyMinter
    {
        require(hashToTokenId[oldHash] != 0, "ERC721: hash does not exist");
        uint256 tokenId = hashToTokenId[oldHash];
        hashToTokenId[newHash] = hashToTokenId[oldHash];
        tokenIdToHash[tokenId] = newHash;
        hashToMetadata[newHash] = hashToMetadata[oldHash];
        delete hashToTokenId[oldHash];
        delete hashToMetadata[oldHash];
        emit HashUpdate(oldHash, newHash);
    }

    /**
     * @dev List the tokens IDs owned by an account
     * @param owner Address to query
     * @return Array of token IDs
     */
    function getTokenIdsOf(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 count = balanceOf(owner);
        uint256[] memory ids = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            ids[i] = tokenOfOwnerByIndex(owner, i);
        }
        return ids;
    }

    /**
     * @dev Get the complete information for a token from it's ID
     * @param tokenId Token ID to query
     * @return Token struct containing token data
     */
    function tokenByIdFull(uint256 tokenId) public view returns (Token memory) {
        string memory hash;
        string memory name;
        string memory ext;
        hash = tokenIdToHash[tokenId];
        name = getMetadata(hash, "name");
        ext = getMetadata(hash, "ext");

        address minter = minters[tokenId];
        address owner = _exists(tokenId) ? ownerOf(tokenId) : address(0);
        return Token(tokenId, hash, name, ext, minter, owner);
    }

    /**
     * @dev Get the full Token struct from an owner address at a specific index
     * @param owner Owner to query
     * @param index Index in owner's balance to query
     * @return Token struct containing token data
     */
    function tokenOfOwnerByIndexFull(address owner, uint256 index)
        public
        view
        returns (Token memory)
    {
        uint256 tokenId = tokenOfOwnerByIndex(owner, index);
        string memory hash;
        string memory name;
        string memory ext;
        hash = tokenIdToHash[tokenId];
        name = getMetadata(hash, "name");
        ext = getMetadata(hash, "ext");
        address minter = minters[tokenId];
        return Token(tokenId, hash, name, ext, minter, owner);
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
        IERC721Upgradeable externalContract = IERC721Upgradeable(
            externalContractAddress
        );
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
     * @dev Check if two strings are equal
     * @param a First string to compare
     * @param b Second string to compare
     * @return Returns true if strings are equal
     */
    function streq(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
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
        override(ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return ERC721Upgradeable.supportsInterface(interfaceId);
    }
}
