// SPDX-License-Identifier: MIT
// SeraphLabs Contracts for Cairo v0.3.0 (arrays/UintArray.cairo)

%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.uint256 import Uint256, uint256_le, uint256_eq, uint256_check
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.memcpy import memcpy

namespace UintArray {
    func create{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() -> (
        arr_len: felt, arr: Uint256*
    ) {
        return _new_uint_array();
    }

    func concat{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
        arr1_len: felt, arr1: Uint256*, arr2_len: felt, arr2: Uint256*
    ) -> (arr_len: felt, arr: Uint256*) {
        alloc_locals;
        let (new_arr_len, new_arr) = _new_uint_array();
        let (temp_arr_len, temp_arr) = _concat_uint_array(new_arr_len, new_arr, arr1_len, arr1);
        return _concat_uint_array(temp_arr_len, temp_arr, arr2_len, arr2);
    }

    func reverse{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
        arr_len: felt, arr: Uint256*
    ) -> (arr_len: felt, arr: Uint256*) {
        alloc_locals;
        let (local new_arr: Uint256*) = alloc();
        return _reverse_uint_array_recursion(arr_len, arr, 0, new_arr);
    }

    func remove_array_of_uints{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
        arr_len: felt, arr: Uint256*, item_len: felt, item: Uint256*
    ) -> (arr_len: felt, arr: Uint256*) {
        alloc_locals;
        with_attr error_message("Array: array length cannot be zero") {
            assert_not_zero(arr_len * item_len);
        }

        let (new_arr_len, new_arr) = _new_uint_array();
        return _remove_all_uint_occurences_recursion(
            arr_len, arr, new_arr_len, new_arr, item_len, item
        );
    }
}

// ---------------------------------------------------------------------------- #
//                                   internals                                  #
// ---------------------------------------------------------------------------- #
// ------------------------------ creating arrays ----------------------------- #
func _new_uint_array{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() -> (
    arr_len: felt, arr: Uint256*
) {
    alloc_locals;
    let (local arr: Uint256*) = alloc();
    return (0, arr);
}

// ----------------------------- concating arrays ----------------------------- #
func _concat_uint_array{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    arr1_len: felt, arr1: Uint256*, arr2_len: felt, arr2: Uint256*
) -> (arr_len: felt, arr: Uint256*) {
    if (arr2_len == 0) {
        return (arr1_len, arr1);
    }
    assert arr1[arr1_len] = [arr2];
    return _concat_uint_array(arr1_len + 1, arr1, arr2_len - 1, arr2 + Uint256.SIZE);
}

// ----------------------------- reversing arrays ----------------------------- #
func _reverse_uint_array_recursion{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    old_arr_len: felt, old_arr: Uint256*, new_arr_len: felt, new_arr: Uint256*
) -> (arr_len: felt, arr: Uint256*) {
    if (old_arr_len == 0) {
        return (new_arr_len, new_arr);
    }
    assert new_arr[old_arr_len - 1] = [old_arr];
    return _reverse_uint_array_recursion(old_arr_len - 1, &old_arr[1], new_arr_len + 1, new_arr);
}

// ---------------------------- removing occurences --------------------------- #
func _remove_all_uint_occurences_recursion{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(
    old_arr_len: felt,
    old_arr: Uint256*,
    new_arr_len: felt,
    new_arr: Uint256*,
    item_len: felt,
    item: Uint256*,
) -> (arr_len: felt, arr: Uint256*) {
    if (old_arr_len == 0) {
        return (new_arr_len, new_arr);
    }
    let (detected) = _detected_uint_occurence_recursion([old_arr], item_len, item);
    if (detected == TRUE) {
        return _remove_all_uint_occurences_recursion(
            old_arr_len - 1, &old_arr[1], new_arr_len, new_arr, item_len, item
        );
    }
    assert new_arr[new_arr_len] = [old_arr];
    return _remove_all_uint_occurences_recursion(
        old_arr_len - 1, &old_arr[1], new_arr_len + 1, new_arr, item_len, item
    );
}

func _detected_uint_occurence_recursion{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(target: Uint256, item_len: felt, item: Uint256*) -> (res: felt) {
    if (item_len == 0) {
        return (FALSE,);
    }

    tempvar uint_len = item_len * Uint256.SIZE - Uint256.SIZE;
    let (is_same) = uint256_eq([item + uint_len], target);
    if (is_same == TRUE) {
        return (TRUE,);
    }

    return _detected_uint_occurence_recursion(target, item_len - 1, item);
}
