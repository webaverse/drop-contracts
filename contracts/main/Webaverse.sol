// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./WebaverseERC721.sol";
import "./WebaverseERC20.sol";

contract Webaverse is OwnableUpgradeable {
    WebaverseERC721 private _erc721;
    WebaverseERC20 private _erc20;
    uint256 private _mintFee; // ERC20 fee to mint ERC721
    address private _treasuryAddress;

    /**
     * @dev Creates the Upgradeable Webaverse contract
     * @param _erc721Address WebaverseERC721 contract address for Non-fungible tokens
     * @param _erc20Address WebaverseERC20 contract address for fungible tokens
     * @param mintFee_ The amount of WebaverseERC20 tokens required to mint a single NFT
     * @param treasuryAddress_ Address of the treasury account
     */
    function initialize(
        address _erc721Address,
        address _erc20Address,
        uint256 mintFee_,
        address treasuryAddress_
    ) public initializer {
        __Ownable_init();
        setERC721(_erc721Address);
        setERC20(_erc20Address);
        setMintFee(mintFee_);
        setTreasuryAddress(treasuryAddress_);
    }

    // constructor(
    //     address _erc721Address,
    //     address _erc20Address,
    //     uint256 mintFee_
    // ) {
    //     setERC721(_erc721Address);
    //     setERC20(_erc20Address);
    //     setMintFee(mintFee_);
    // }

    /**
     * @return The amount of ERC20 tokens required to mint the ERC721 NFT
     */
    function mintFee() public view returns (uint256) {
        return _mintFee;
    }

    /**
     * @return The address of Webaverse ERC721 contract
     */
    function ERC721Address() public view returns (address) {
        return address(_erc721);
    }

    /**
     * @return The address of Webaverse ERC20 contract
     */
    function ERC20Address() public view returns (address) {
        return address(_erc20);
    }

    /**
     * @dev Set the contract instance for ERC721
     * @param _erc721Address The address of the ERC721 contract that needs to be set
     */
    function setERC721(address _erc721Address) public onlyOwner {
        _erc721 = WebaverseERC721(_erc721Address);
    }

    /**
     * @dev Set the contract instance for ERC20
     * @param _erc20Address The address of the ERC20 contract that needs to be set
     */
    function setERC20(address _erc20Address) public onlyOwner {
        _erc20 = WebaverseERC20(_erc20Address);
    }

    /**
     * @dev Set the price to mint
     * @param mintFee_ Minting fee, default is 10 FT
     */
    function setMintFee(uint256 mintFee_) public onlyOwner {
        _mintFee = mintFee_;
    }

    /**
     * @return The address that is used for receiving mint fee (ERC20 tokens)
     */
    function treasuryAddress() public view returns (address) {
        return _treasuryAddress;
    }

    /**
     * @dev Set the treasury address
     * @param treasuryAddress_ Account address of the treasurer
     */
    function setTreasuryAddress(address treasuryAddress_) public onlyOwner {
        _treasuryAddress = treasuryAddress_;
    }

    /**
     * @notice Mints the a single NFT with given parameters.
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
    ) public {
        if (mintFee() != 0) {
            require(
                _erc20.transferFrom(msg.sender, treasuryAddress(), mintFee()),
                "Webaverse: Mint transfer failed"
            );
        }
        _erc721.mint(to, hash, name, ext, description);
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
    ) public {
        uint256 tokenId = _erc721.getTokenIdFromHash(hash);
        require(
            _erc721.ownerOf(tokenId) == msg.sender,
            "Webaverse: setURI can only be called by the owner of the NFT"
        );
        _erc721.setMetadata(hash, key, value);
    }
}
