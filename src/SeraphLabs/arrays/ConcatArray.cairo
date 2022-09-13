from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256

func concat_array{range_check_ptr}(arr1_len: felt, arr1: felt*, arr2_len: felt, arr2: felt*) -> (
    arr_len: felt, arr: felt*
) {
    alloc_locals;
    let (local new_arr: felt*) = alloc();
    memcpy(new_arr, arr1, arr1_len);
    memcpy(new_arr + arr1_len, arr2, arr2_len);
    return (arr1_len + arr2_len, new_arr);
}
