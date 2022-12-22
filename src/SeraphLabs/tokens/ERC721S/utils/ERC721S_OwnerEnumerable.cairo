// SPDX-License-Identifier: MIT
// SeraphLabs Contracts for Cairo v0.3.0 (tokens/ERC721S/utils/ERC721S_OwnerEnumerable.cairo)
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_not_equal, assert_le
from starkware.cairo.common.math_cmp import is_not_zero, is_le
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import Uint256, uint256_check, uint256_le, uint256_eq
from starkware.cairo.common.alloc import alloc

from openzeppelin.security.safemath.library import SafeUint256
from SeraphLabs.math.simple_checks import is_uint_valid
from SeraphLabs.tokens.libs.scalarHandler import ScalarHandler, ScalarAsset, MAX_sequence, MAX_slot

@storage_var
func ERC721S_OwnerEnumeration(owner: felt, low_token: Uint256) -> (high_token: Uint256) {
}

namespace OwnerEnum721S {
    func get_next_token{
        bitwise_ptr: BitwiseBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr,
        pedersen_ptr: HashBuiltin*,
    }(owner: felt, tokenId: Uint256) -> (next_id: Uint256) {
        alloc_locals;
        let (next_id) = ERC721S_OwnerEnumeration.read(owner, tokenId);
        return (next_id,);
    }

    func add_to_enumeration{
        bitwise_ptr: BitwiseBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr,
        pedersen_ptr: HashBuiltin*,
    }(owner: felt, tokenId: Uint256) {
        alloc_locals;
        let (cur_lowest_id: Uint256) = ERC721S_OwnerEnumeration.read(owner, Uint256(0, 0));
        let (is_zero) = uint256_le(cur_lowest_id, Uint256(0, 0));
        // if there is no lowest_id
        if (is_zero == TRUE) {
            ERC721S_OwnerEnumeration.write(owner, Uint256(0, 0), tokenId);
            return ();
        }
        // if tokenId is a new lower
        let (is_lower) = uint256_le(tokenId, cur_lowest_id);
        if (is_lower == TRUE) {
            ERC721S_OwnerEnumeration.write(owner, Uint256(0, 0), tokenId);
            ERC721S_OwnerEnumeration.write(owner, tokenId, cur_lowest_id);
            return ();
        }
        let (new_low: Uint256, new_high: Uint256) = _get_owner_token_pos(
            owner, tokenId, cur_lowest_id
        );
        ERC721S_OwnerEnumeration.write(owner, new_low, tokenId);
        ERC721S_OwnerEnumeration.write(owner, tokenId, new_high);
        return ();
    }

    func not_in_batch_remove{
        bitwise_ptr: BitwiseBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr,
        pedersen_ptr: HashBuiltin*,
    }(owner: felt, tokenId: Uint256) {
        alloc_locals;
        let (cur_low: Uint256, cur_high: Uint256) = _get_owner_token_pos(
            owner, tokenId, Uint256(0, 0)
        );
        let (next_high_id: Uint256) = ERC721S_OwnerEnumeration.read(owner, tokenId);
        ERC721S_OwnerEnumeration.write(owner, cur_low, next_high_id);
        ERC721S_OwnerEnumeration.write(owner, tokenId, Uint256(0, 0));
        return ();
    }

    func start_of_batch_remove{
        bitwise_ptr: BitwiseBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr,
        pedersen_ptr: HashBuiltin*,
    }(owner: felt, tokenId: Uint256) {
        alloc_locals;
        let (cur_low: Uint256, cur_high: Uint256) = _get_owner_token_pos(
            owner, tokenId, Uint256(0, 0)
        );
        let (new_high_id: Uint256) = SafeUint256.add(tokenId, Uint256(1, 0));
        let (next_high_id: Uint256) = ERC721S_OwnerEnumeration.read(owner, tokenId);

        ERC721S_OwnerEnumeration.write(owner, cur_low, new_high_id);
        ERC721S_OwnerEnumeration.write(owner, new_high_id, next_high_id);
        ERC721S_OwnerEnumeration.write(owner, tokenId, Uint256(0, 0));
        return ();
    }

    func mid_of_batch_remove{
        bitwise_ptr: BitwiseBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr,
        pedersen_ptr: HashBuiltin*,
    }(owner: felt, tokenId: Uint256, tokenId_low: Uint256) {
        alloc_locals;
        let (new_high_id: Uint256) = SafeUint256.add(tokenId, Uint256(1, 0));
        let (next_high_id: Uint256) = ERC721S_OwnerEnumeration.read(owner, tokenId_low);

        ERC721S_OwnerEnumeration.write(owner, tokenId_low, new_high_id);
        ERC721S_OwnerEnumeration.write(owner, new_high_id, next_high_id);
        return ();
    }
}

func _get_owner_token_pos{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(owner: felt, tokenId: Uint256, startId: Uint256) -> (low: Uint256, high: Uint256) {
    alloc_locals;
    let (next_id: Uint256) = ERC721S_OwnerEnumeration.read(owner, startId);
    let (is_zero) = uint256_le(next_id, Uint256(0, 0));
    if (is_zero == TRUE) {
        return (startId, next_id);
    }

    let (is_between) = uint256_le(tokenId, next_id);
    if (is_between == TRUE) {
        return (startId, next_id);
    }
    return _get_owner_token_pos(owner=owner, tokenId=tokenId, startId=next_id);
}
