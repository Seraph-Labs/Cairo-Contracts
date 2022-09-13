%lang starknet
%builtins pedersen range_check bitwise

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from SeraphLabs.arrays.Array import Array

@view
func getAscendingArray{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    arrLen: felt
) -> (arr_len: felt, arr: felt*) {
    let (arr_len, arr) = Array.create_asc(arrLen);
    return (arr_len, arr);
}

@view
func getDescendingArray{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    arrLen: felt
) -> (arr_len: felt, arr: felt*) {
    let (arr_len, arr) = Array.create_desc(arrLen);
    return (arr_len, arr);
}

@view
func removeArrayOfItems{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    arr1_len: felt, arr1: felt*, item_len: felt, item: felt*
) -> (arr_len: felt, arr: felt*) {
    let (arr_len, arr) = Array.remove_array_of_items(arr1_len, arr1, item_len, item);
    return (arr_len, arr);
}

@view
func contains{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    arr1_len: felt, arr1: felt*, item_len: felt, item: felt*
) -> (res: felt) {
    let (res) = Array.contains(arr1_len, arr1, item_len, item);
    return (res,);
}

@view
func containsAll{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    arr1_len: felt, arr1: felt*, item_len: felt, item: felt*
) -> (res: felt) {
    let (res) = Array.contains_all(arr1_len, arr1, item_len, item);
    return (res,);
}
