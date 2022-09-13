%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.memcpy import memcpy

func reverse_array{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    arr_len: felt, arr: felt*
) -> (arr_len: felt, arr: felt*) {
    alloc_locals;
    let (local new_arr: felt*) = alloc();
    return reverse_array_loop(arr_len, arr, 0, new_arr);
}

func reverse_array_loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    old_arr_len: felt, old_arr: felt*, new_arr_len: felt, new_arr: felt*
) -> (arr_len: felt, arr: felt*) {
    if (old_arr_len == 0) {
        return (new_arr_len, new_arr);
    }
    assert new_arr[old_arr_len - 1] = [old_arr];
    return reverse_array_loop(old_arr_len - 1, &old_arr[1], new_arr_len + 1, new_arr);
}
