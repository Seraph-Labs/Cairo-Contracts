%lang starknet
%builtins pedersen range_check bitwise

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256
from SeraphLabs.arrays.UintArray import UintArray

@view
func createArr{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}(
    num : Uint256
) -> (arr_len : felt, arr : Uint256*):
    alloc_locals
    let (temp_arr_len, temp_arr) = UintArray.create()
    assert temp_arr[temp_arr_len] = num
    return (temp_arr_len + 1, temp_arr)
end

@view
func concatUints{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}(
    arr1_len : felt, arr1 : Uint256*, arr2_len : felt, arr2 : Uint256*
) -> (arr_len : felt, arr : Uint256*):
    alloc_locals
    let (arr_len, arr) = UintArray.concat(arr1_len, arr1, arr2_len, arr2)
    return (arr_len, arr)
end

@view
func reverseUints{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}(
    arr1_len : felt, arr1 : Uint256*
) -> (arr_len : felt, arr : Uint256*):
    let (arr_len, arr) = UintArray.reverse(arr1_len, arr1)
    return (arr_len, arr)
end

@view
func removeArrayOfUints{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}(
    arr1_len : felt, arr1 : Uint256*, item_len : felt, item : Uint256*
) -> (arr_len : felt, arr : Uint256*):
    let (arr_len, arr) = UintArray.remove_array_of_uints(arr1_len, arr1, item_len, item)
    return (arr_len, arr)
end
