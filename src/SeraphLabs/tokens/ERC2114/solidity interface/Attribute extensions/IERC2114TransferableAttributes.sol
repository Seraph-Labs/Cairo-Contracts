// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC2114TransferableAttributes {
    /**
     * @dev Emitted when attribute type `attrId` of a token `tokenId`
     * is approved or unapproved for transfer by `operator`
     */
    event AttributeApproval(
        address indexed operator,
        uint256 tokenId,
        uint256 attrId,
        uint256 to
    );

    /**
     * @dev Emitted when all attribute types of a token `tokenId`
     * is approved or unapproved for transfer by `operator`
     */
    event AttributeApprovalForAll(
        address indexed operator,
        uint256 tokenId,
        uint256 to
    );

    /**
     * @dev Emitted when attribute type `attrId` and is corresponding value/ammount
     * is transfered from `tokenId` to `to` token
     */
    event TransferAttribute(
        address indexed operator,
        uint256 tokenId,
        uint256 indexed attrId,
        uint256 to,
        string value,
        uint256 ammount
    );

    /**
     * @dev if attribute type `attrId` of `tokenId` is approved to token `to` from token `tokenId` return TRUE
     */
    function isApproved(
        uint256 tokenId,
        uint256 attrId,
        uint256 to
    ) external view returns (bool);

    /**
     * @dev if all attribute types of `tokenId` is approved to token `to` from token `tokenId` return TRUE
     */
    function isApprovedForAll(uint256 tokenId, uint256 to)
        external
        view
        returns (bool);

    /**
     * @dev Approve the transfer of attribute type `attrId` from token `tokenId` to token `to`
     * called by `tokenId` owner/approved operator
     * @notice emits AttributeApproval event.
     */
    function approve(
        uint256 tokenId,
        uint256 attrId,
        uint256 to
    ) external;

    /**
     * @dev Approve the transfer of all attribute types  from token `tokenId` to token `to`
     * called by `tokenId` owner/approved operator
     * @notice emits AttributeApprovalForAll event.
     */
    function setApprovalForAll(
        uint256 tokenId,
        uint256 to,
        bool approved
    ) external;

    /**
     * @dev transfer attribute type `attrId` of token `tokenId` to token `to`
     * called by `tokenId` owner/approved operator
     * @notice emits TransferAttribute event.
     */
    function attributeTransferFrom(
        uint256 tokenId,
        uint256 attrId,
        uint256 to
    ) external;

    /**
     * @dev transfer all attribute types of token `tokenId` to token `to`
     * called by `tokenId` owner/approved operator
     * @notice emits TransferAttribute event.
     */
    function attributeTransferAllFrom(uint256 tokenId, uint256 to) external;
}
