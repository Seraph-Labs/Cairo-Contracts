// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Interface for the optional function that allows tokens to own tokens from different contracts.
 */
interface IERC2114ExternalTokenOwnership {
    /**
     * @dev Emitted when `tokenId` is transfered by operator `from`
     * to a `to` tokenId in `toContract` contract.
     */
    event ExternalScalarTransfer(
        address indexed from,
        uint256 tokenId,
        uint256 to,
        address toContract
    );

    /**
     * @dev Emitted when an externally owned `tokenId` is transfered out of a token `from`
     * back to an address
     */
    event ExternalScalarRemove(
        uint256 indexed from,
        address fromContract,
        uint256 indexed tokenId,
        address indexed to
    );

    /**
     * @dev Returns the token and its contract address which owns `tokenId`
     */
    function tokenOf(uint256 tokenId) external view returns (uint256, address);

    /**
     * @dev transfers ownership of token to another token `to` that is from `toContract`
     * in this state the owned address of transfered token will be set to contract or an arbitrary address
     * @notice emits ExternalScalarTransfer event
     */
    function externalScalarTransferFrom(
        address from,
        uint256 tokenId,
        uint256 to,
        address toContract
    ) external;

    /**
     * @dev removes ownership of a token back to the address that is owns the `from` tokenId
     * @notice emits ExternalScalarRemove event
     */
    function externalScalarRemoveFrom(
        uint256 from,
        address fromContract,
        uint256 tokenId
    ) external;
}
