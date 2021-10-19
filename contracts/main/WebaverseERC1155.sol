// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../utils/WBVRSVoucher.sol";

contract WebaverseERC1155 is ERC1155, WBVRSVoucher, Ownable {
    /*
     * Map for storing URIs of NFTs
     */
    mapping(uint256 => string) private _tokenURIs;

    /*
     * State variable for storing the latest minted toke id
     */
    uint256 public currentTokenID = 0;

    constructor() ERC1155("https://gateway.pinata.cloud/ipfs") {}

    function uri(uint256 _id) public view override returns (string memory) {
        return _tokenURIs[_id];
    }

    function _setTokenURI(uint256 _tokenId, string memory _uri) internal {
        _tokenURIs[_tokenId] = _uri;
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
            balanceOf(signer, voucher.tokenId) != 0,
            "WBVRS: Authorization failed: Invalid signature"
        );

        // transfer the token to the claimer
        _safeTransferFrom(
            signer,
            claimer,
            voucher.tokenId,
            voucher.balance,
            "0x01"
        );
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
        IERC1155 externalContract = IERC1155(contractAddress);
        // make sure signature is valid and get the address of the signer
        address signer = verifyVoucher(voucher);

        require(
            externalContract.balanceOf(signer, voucher.tokenId) != 0,
            "WBVRS: Authorization failed: Invalid signature"
        );
        require(
            externalContract.isApprovedForAll(signer, address(this)),
            "WBVRS: Aprroval not set for WebaverseERC1155"
        );

        // transfer the token to the claimer
        externalContract.safeTransferFrom(
            signer,
            claimer,
            voucher.tokenId,
            voucher.balance,
            "0X01"
        );
        return voucher.tokenId;
    }

    function mint(
        address account,
        uint256 tokenId,
        uint256 amount,
        string memory _uri,
        bytes memory data
    ) public {
        _mint(account, tokenId, amount, data);
        _setTokenURI(tokenId, _uri);
    }

    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] memory values,
        string[] memory uris,
        bytes memory data
    ) public {
        require(
            ids.length == values.length,
            "WBVRSERC1155: Ids and values length mismatch"
        );
        require(
            ids.length == uris.length,
            "WBVRSERC1155: Ids and URIs length mismatch"
        );
        _mintBatch(to, ids, values, data);
        for (uint256 i = 0; i < ids.length; i++) {
            _setTokenURI(ids[i], uris[i]);
        }
    }

    function safeTransfer(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public {
        safeTransferFrom(_msgSender(), to, id, amount, data);
    }

    function burn(
        address owner,
        uint256 id,
        uint256 value
    ) public onlyOwner {
        _burn(owner, id, value);
    }

    function burnBatch(
        address owner,
        uint256[] memory ids,
        uint256[] memory values
    ) public onlyOwner {
        _burnBatch(owner, ids, values);
    }

    /**
     * @dev increments the value of _currentTokenID
     */
    function _incrementTokenId() private {
        currentTokenID++;
    }
}
