%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.memcpy import memcpy

// some functions ideas taken from
// https://github.com/gaetbout/starknet-array-manipulation#add_first

namespace Array {
    func create{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() -> (
        arr_len: felt, arr: felt*
    ) {
        let (arr_len, arr) = _new_array();
        return (arr_len, arr);
    }

    func create_asc{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
        arrLen: felt
    ) -> (arr_len: felt, arr: felt*) {
        alloc_locals;
        with_attr error_message("Array: length cannot be zero") {
            assert_not_zero(arrLen);
        }

        let (local arr: felt*) = alloc();
        _create_ascending_arr_recursion(0, arrLen, arr);
        return (arrLen, arr);
    }

    func create_desc{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
        arrLen: felt
    ) -> (arr_len: felt, arr: felt*) {
        alloc_locals;
        with_attr error_message("Array: length cannot be zero") {
            assert_not_zero(arrLen);
        }

        let (local arr: felt*) = alloc();
        _create_descending_arr_recursion(arrLen, arr);
        return (arrLen, arr);
    }

    func concat{range_check_ptr}(arr1_len: felt, arr1: felt*, arr2_len: felt, arr2: felt*) -> (
        arr_len: felt, arr: felt*
    ) {
        alloc_locals;
        let (local new_arr: felt*) = alloc();
        memcpy(new_arr, arr1, arr1_len);
        memcpy(new_arr + arr1_len, arr2, arr2_len);
        return (arr1_len + arr2_len, new_arr);
    }

    func reverse{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        arr_len: felt, arr: felt*
    ) -> (arr_len: felt, arr: felt*) {
        alloc_locals;
        let (local new_arr: felt*) = alloc();
        return _reverse_array_recursion(arr_len, arr, 0, new_arr);
    }

    func remove_array_of_items{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        arr_len: felt, arr: felt*, item_len: felt, item: felt*
    ) -> (arr_len: felt, arr: felt*) {
        alloc_locals;
        with_attr error_message("Array: array length cannot be zero") {
            assert_not_zero(arr_len * item_len);
        }

        let (new_arr_len, new_arr) = _new_array();
        return _remove_all_occurences_recursion(arr_len, arr, new_arr_len, new_arr, item_len, item);
    }

    func contains{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
        arr1_len: felt, arr1: felt*, arr2_len: felt, arr2: felt*
    ) -> (res: felt) {
        alloc_locals;
        if (arr1_len == 0) {
            return (FALSE,);
        }
        if (arr2_len == 0) {
            return (FALSE,);
        }
        let (res) = _check_contains(arr1_len, arr1, arr2_len, arr2);
        return (res,);
    }

    func contains_all{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
        arr1_len: felt, arr1: felt*, arr2_len: felt, arr2: felt*
    ) -> (res: felt) {
        alloc_locals;
        if (arr1_len == 0) {
            return (FALSE,);
        }
        if (arr2_len == 0) {
            return (FALSE,);
        }
        let (res) = _check_contains_all(arr1_len, arr1, arr2_len, arr2);
        return (res,);
    }
}

// ---------------------------------------------------------------------------- #
//                             internals dont export                            #
// ---------------------------------------------------------------------------- #

// ------------------------------ creating arrays ----------------------------- #
func _new_array{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    arr_len: felt, arr: felt*
) {
    alloc_locals;
    let (local arr: felt*) = alloc();
    return (0, arr);
}

func _create_ascending_arr_recursion{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(l_index: felt, arr_len: felt, arr: felt*) {
    if (arr_len == 0) {
        return ();
    }
    tempvar new_index = l_index + 1;
    assert [arr] = new_index;
    _create_ascending_arr_recursion(new_index, arr_len - 1, arr + 1);
    return ();
}

func _create_descending_arr_recursion{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(h_index: felt, arr: felt*) {
    if (h_index == 0) {
        return ();
    }
    assert [arr] = h_index;
    _create_descending_arr_recursion(h_index - 1, arr + 1);
    return ();
}

// ----------------------------- reversing arrays ----------------------------- #
func _reverse_array_recursion{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    old_arr_len: felt, old_arr: felt*, new_arr_len: felt, new_arr: felt*
) -> (arr_len: felt, arr: felt*) {
    if (old_arr_len == 0) {
        return (new_arr_len, new_arr);
    }
    assert new_arr[old_arr_len - 1] = [old_arr];
    return _reverse_array_recursion(old_arr_len - 1, &old_arr[1], new_arr_len + 1, new_arr);
}

// ---------------------------- removing occurences --------------------------- #

func _remove_all_occurences_recursion{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(
    old_arr_len: felt,
    old_arr: felt*,
    new_arr_len: felt,
    new_arr: felt*,
    item_len: felt,
    item: felt*,
) -> (arr_len: felt, arr: felt*) {
    if (old_arr_len == 0) {
        return (new_arr_len, new_arr);
    }
    let (detected) = _detected_occurence_recursion([old_arr], item_len, item);
    if (detected == TRUE) {
        return _remove_all_occurences_recursion(
            old_arr_len - 1, &old_arr[1], new_arr_len, new_arr, item_len, item
        );
    }
    assert new_arr[new_arr_len] = [old_arr];
    return _remove_all_occurences_recursion(
        old_arr_len - 1, &old_arr[1], new_arr_len + 1, new_arr, item_len, item
    );
}

func _detected_occurence_recursion{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    target: felt, item_len: felt, item: felt*
) -> (res: felt) {
    if (item_len == 0) {
        return (FALSE,);
    }

    if ([item + item_len - 1] == target) {
        return (TRUE,);
    }

    return _detected_occurence_recursion(target, item_len - 1, item);
}

// ------------------------------ check contains ------------------------------ #
func _check_contains{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    arr_len: felt, arr: felt*, item_len: felt, item: felt*
) -> (res: felt) {
    if (arr_len == 0) {
        return (FALSE,);
    }
    let (detected) = _detected_occurence_recursion([arr], item_len, item);
    if (detected == TRUE) {
        return (TRUE,);
    }
    return _check_contains(arr_len - 1, &arr[1], item_len, item);
}

func _check_contains_all{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    arr_len: felt, arr: felt*, item_len: felt, item: felt*
) -> (res: felt) {
    if (arr_len == 0) {
        return (TRUE,);
    }
    let (detected) = _detected_occurence_recursion([arr], item_len, item);
    if (detected == TRUE) {
        return _check_contains_all(arr_len - 1, &arr[1], item_len, item);
    }
    return (FALSE,);
}
