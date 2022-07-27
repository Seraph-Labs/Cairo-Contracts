%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.memcpy import memcpy

namespace Array:
    func create{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}() -> (
        arr_len : felt, arr : felt*
    ):
        let (arr_len, arr) = _new_array()
        return (arr_len, arr)
    end

    func create_asc{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}(
        arrLen : felt
    ) -> (arr_len : felt, arr : felt*):
        alloc_locals
        with_attr error_message("Array: length cannot be zero"):
            assert_not_zero(arrLen)
        end

        let (local arr : felt*) = alloc()
        _create_ascending_arr_recursion(0, arrLen, arr)
        return (arrLen, arr)
    end

    func create_desc{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}(
        arrLen : felt
    ) -> (arr_len : felt, arr : felt*):
        alloc_locals
        with_attr error_message("Array: length cannot be zero"):
            assert_not_zero(arrLen)
        end

        let (local arr : felt*) = alloc()
        _create_descending_arr_recursion(arrLen, arr)
        return (arrLen, arr)
    end

    func concat{range_check_ptr}(arr1_len : felt, arr1 : felt*, arr2_len : felt, arr2 : felt*) -> (
        arr_len : felt, arr : felt*
    ):
        alloc_locals
        let (local new_arr : felt*) = alloc()
        memcpy(new_arr, arr1, arr1_len)
        memcpy(new_arr + arr1_len, arr2, arr2_len)
        return (arr1_len + arr2_len, new_arr)
    end

    func reverse{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        arr_len : felt, arr : felt*
    ) -> (arr_len : felt, arr : felt*):
        alloc_locals
        let (local new_arr : felt*) = alloc()
        return _reverse_array_recursion(arr_len, arr, 0, new_arr)
    end

    func remove_array_of_items{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        arr_len : felt, arr : felt*, item_len : felt, item : felt*
    ) -> (arr_len : felt, arr : felt*):
        alloc_locals
        with_attr error_message("Array: array length cannot be zero"):
            assert_not_zero(arr_len * item_len)
        end

        let (new_arr_len, new_arr) = _new_array()
        return _remove_all_occurences_recursion(arr_len, arr, new_arr_len, new_arr, item_len, item)
    end
end

# ---------------------------------------------------------------------------- #
#                             internals dont export                            #
# ---------------------------------------------------------------------------- #

# ------------------------------ creating arrays ----------------------------- #
func _new_array{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    arr_len : felt, arr : felt*
):
    alloc_locals
    let (local arr : felt*) = alloc()
    return (0, arr)
end

func _create_ascending_arr_recursion{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}(l_index : felt, arr_len : felt, arr : felt*):
    if arr_len == 0:
        return ()
    end
    tempvar new_index = l_index + 1
    assert [arr] = new_index
    _create_ascending_arr_recursion(new_index, arr_len - 1, arr + 1)
    return ()
end

func _create_descending_arr_recursion{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}(h_index : felt, arr : felt*):
    if h_index == 0:
        return ()
    end
    assert [arr] = h_index
    _create_descending_arr_recursion(h_index - 1, arr + 1)
    return ()
end

# ----------------------------- reversing arrays ----------------------------- #
func _reverse_array_recursion{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    old_arr_len : felt, old_arr : felt*, new_arr_len : felt, new_arr : felt*
) -> (arr_len : felt, arr : felt*):
    if old_arr_len == 0:
        return (new_arr_len, new_arr)
    end
    assert new_arr[old_arr_len - 1] = [old_arr]
    return _reverse_array_recursion(old_arr_len - 1, &old_arr[1], new_arr_len + 1, new_arr)
end

# ---------------------------- removing occurences --------------------------- #

func _remove_all_occurences_recursion{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(
    old_arr_len : felt,
    old_arr : felt*,
    new_arr_len : felt,
    new_arr : felt*,
    item_len : felt,
    item : felt*,
) -> (arr_len : felt, arr : felt*):
    if old_arr_len == 0:
        return (new_arr_len, new_arr)
    end
    let (detected) = _detected_occurence_recursion([old_arr], item_len, item)
    if detected == TRUE:
        return _remove_all_occurences_recursion(
            old_arr_len - 1, &old_arr[1], new_arr_len, new_arr, item_len, item
        )
    end
    assert new_arr[new_arr_len] = [old_arr]
    return _remove_all_occurences_recursion(
        old_arr_len - 1, &old_arr[1], new_arr_len + 1, new_arr, item_len, item
    )
end

func _detected_occurence_recursion{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
}(target : felt, item_len : felt, item : felt*) -> (res : felt):
    if item_len == 0:
        return (FALSE)
    end

    if [item + item_len - 1] == target:
        return (TRUE)
    end

    return _detected_occurence_recursion(target, item_len - 1, item)
end
