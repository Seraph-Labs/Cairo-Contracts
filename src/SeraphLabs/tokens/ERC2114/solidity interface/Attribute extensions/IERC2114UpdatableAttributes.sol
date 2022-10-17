// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC2114UpdatableAttributes {
    /**
     * @dev Emitted when `tokenId` attribute type `attrId` value/ammount is changed
     */
    event AttributeUpdated(
        uint256 indexed tokenId,
        uint256 indexed attrId,
        string value,
        uint256 ammount
    );

    /**
     * @dev updates the value of `tokenId` attribute type `attrId`
     * @notice emits AttributeUpdated event
     */
    function changeAttrValue(
        uint256 tokenId,
        uint256 attrId,
        string memory value
    ) external;

    /**
     * @dev updates the ammount of `tokenId` attribute type `attrId`
     * @notice emits AttributeUpdated event
     */
    function changeAttrAmmount(
        uint256 tokenId,
        uint256 attrId,
        uint256 ammount
    ) external;

    /**
     * @dev renoves attribute `attrId` from `tokenId`
     * essentially setting its balance to 0
     * @notice emits AttributeUpdated event
     */
    function removeAttribute(uint256 tokenId, uint256 attrId) external;
}
