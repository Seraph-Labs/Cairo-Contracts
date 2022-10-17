// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title extension interface for ERC-2114 to add attributes to slot
 * @dev this erc214 extension is an extension of erc3525
 * Note: the ERC-165 identifier for this interface is : [undecided]
 */
interface IERC2114SlotAttributes is IERC2114Metadata {
    /**
     * @dev Emitted when an attribute `attrId` has been set
     * by `operator` on a slot `slotId`
     */
    event SlotAttributeSet(
        address indexed operator,
        uint256 slotId,
        uint256 indexed attrId,
        string value,
        uint256 ammount
    );

    /**
     * @dev Returns all attributes assigned to slot `slotId`
     */
    function slotAttributesOf(uint256 slotId)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Returns the ammount of attributes assigned to `slotId`.
     */
    function slotAttributeCount(uint256 slotId) external view returns (uint256);

    /**
     * @dev Returns the ammount of a specific attribute `attrId` assigned to a `slotId`.
     */
    function slotAttributeAmmount(uint256 slotId, uint256 attrId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the value of a specific attribute `attrId` assigned a `slotId`.
     */
    function slotAttributeValue(uint256 slotId, uint256 attrId)
        external
        view
        returns (string memory);

    /**
     * @dev Set attribute `attrId` for slot `slotId`.
     * @notice emits SlotAttributeSet event
     */
    function setSlotAttribute(
        uint256 slotId,
        uint256 attrId,
        string memory value,
        uint256 ammount
    ) external;

    /**
     * @dev Batched version of {setSlotAttribute}.
     * @notice emits SlotAttributeSet event
     */
    function batchSetSlotAttribute(
        uint256 slotId,
        uint256[] calldata attrIds,
        string[] calldata values,
        uint256[] calldata amounts
    ) external;
}
