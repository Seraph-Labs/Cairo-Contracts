// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title required interface for ERC-2114
 * @dev erc214 is an extension of erc3525 and erc721
 * Note: the ERC-165 identifier for this interface is : [undecided]
 */
interface ERC2114 {
    /**
     * @dev Emitted when `tokenId` is transfered by operator `from`
     * to a `to` tokenId within this contract.
     */
    event ScalarTransfer(address indexed from, uint256 tokenId, uint256 to);

    /**
     * @dev Emitted when `tokenId` is transfered out of a tokenId
     * back to an address
     */
    event ScalarRemove(
        uint256 indexed from,
        uint256 indexed tokenId,
        address indexed to
    );

    /**
     * @dev Emitted when an attribute type `attrId` is created
     */
    event AttributeCreated(uint256 indexed attrId, string name, string uri);

    /**
     * @dev Emitted when an attribute `attrId` together with its corresponding`value`/`ammount` is added to a `tokenId`
     */
    event AttributeAdded(
        uint256 indexed tokenId,
        uint256 indexed attrId,
        string value,
        uint256 ammount
    );

    /**
     * @dev Returns the token which owns`tokenId`
     */
    function tokenOf(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Returns the number of tokens owned by `tokenId`
     */
    function tokenBalanceOf(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Returns all attributes owned by `tokenId`.
     */
    function attributesOf(uint256 tokenId)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Returns the ammount of attributes owned by `tokenId`.
     */
    function attributeCount(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Returns the ammount of a specific attribute `attrId` owned by a `tokenId`.
     */
    function attributeAmmount(uint256 tokenId, uint256 attrId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the value of a specific attribute `attrId` owned by a `tokenId`.
     */
    function attributeValue(uint256 tokenId, uint256 attrId)
        external
        view
        returns (string memory);

    /**
     * @dev transfers ownership of token to another token
     * in this state the owned address of transfered token will be set to contract or an arbitrary address
     * @notice emits ScalarTransfer event
     */
    function scalarTransferFrom(
        address from,
        uint256 tokenId,
        uint256 to
    ) external;

    /**
     * @dev removes ownership of a token back to the address that is owns the `from` tokenId
     * @notice emits ScalarRemove event
     */
    function scalarRemoveFrom(uint256 from, uint256 tokenId) external;

    /**
     * @dev creates an attribute type and sets it name(optional) and uri(optional).
     * @notice emits AttributeCreated event
     */
    function createAttribute(
        uint256 attrId,
        string calldata name,
        string calldata uri
    ) external;

    /**
     * @dev Batched version of {createAttribute}.
     * @notice emits AttributeCreated event
     */
    function batchCreateAttribute(
        uint256[] calldata attrIds,
        string[] calldata names,
        string[] calldata uris
    ) external;

    /**
     * @dev adds a single attribute type `attrId` to `tokenId` with a corresponding value/ammount.
     * @notice emits AttributeAdded event
     */
    function addAttribute(
        uint256 tokenId,
        uint256 attrId,
        string memory value,
        uint256 amount
    ) external;

    /**
     * @dev Batched version of {addAttribute}.
     * @notice emits AttributeAdded event
     */
    function batchAddAttribute(
        uint256 tokenId,
        uint256[] calldata attrIds,
        string[] calldata values,
        uint256[] calldata amounts
    ) external;
}
