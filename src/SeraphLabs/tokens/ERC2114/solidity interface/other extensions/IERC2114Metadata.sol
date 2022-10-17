// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC2114MetaData is IERC2114 {
    /**
     * @dev Returns the name of the attribute type.
     */
    function name(uint256 attrId) external view returns (string memory);

    /**
     * @dev Returns the attributes URI.
     */
    function attrURI(uint256 attrId) external view returns (string memory);
}
