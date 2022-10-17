// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Interface for enumerating token to token ownership.
 */
interface IERC2114Enumerable {
    /**
     * @dev Returns the owned tokens of `tokenId` from `fromContract` at `index`
     */
    function tokenOfTokenByIndex(
        uint256 tokenId,
        address fromContract,
        uint256 index
    ) external view returns (uint256);
}
