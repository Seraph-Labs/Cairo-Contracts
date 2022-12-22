// SPDX-License-Identifier: MIT
// SeraphLabs Contracts for Cairo v0.3.0 (tokens/ERC3525/interfaces/IERC3525.cairo)
%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC3525 {
    func slotOf(tokenId: Uint256) -> (slot: Uint256) {
    }

    func supplyOfSlot(slot: Uint256) -> (supply: Uint256) {
    }

    func tokenOfSlotByIndex(slot: Uint256, index: Uint256) -> (tokenId: Uint256) {
    }

    func unitsInToken(tokenId: Uint256) -> (units: Uint256) {
    }

    func allowance(tokenId: Uint256, spender: felt) -> (units: Uint256) {
    }

    func slotURI(slot: Uint256) -> (arr_len: felt, arr: felt*) {
    }

    func unitApprove(to: felt, tokenId: Uint256, units: Uint256) {
    }

    func unitTransferFrom(
        from_: felt, to: felt, tokenId: Uint256, targetTokenId: Uint256, units: Uint256
    ) {
    }

    func safeUnitTransferFrom(
        from_: felt,
        to: felt,
        tokenId: Uint256,
        targetTokenId: Uint256,
        units: Uint256,
        data_len: felt,
        data: felt*,
    ) {
    }

    func split(tokenId: Uint256, units_arr_len: felt, units_arr: Uint256*) -> (
        tokenIds_len: felt, tokenIds: Uint256*
    ) {
    }

    func merge(tokenIds_len: felt, tokenIds: Uint256*, targetTokenId: Uint256) {
    }
}
