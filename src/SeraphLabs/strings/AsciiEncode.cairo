// -------------------------------------------------------------------------- //
//                        library for converting values                       //
//                       into a single ascii encoded felt                     //
// -------------------------------------------------------------------------- //
%lang starknet
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.math import (
    unsigned_div_rem,
    split_felt,
    assert_not_zero,
    assert_not_equal,
)
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_unsigned_div_rem,
    uint256_check,
    uint256_lt,
    uint256_le,
)
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.memcpy import memcpy

from SeraphLabs.math.Pow2 import pow2
from SeraphLabs.arrays.Array import Array
from SeraphLabs.models.StringObject import StrObj, StrObj_check

func interger_to_ascii{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(num: felt) -> (res: felt) {
    alloc_locals;

    let (local new_arr: felt*) = alloc();

    let is_one_digit = is_le(num, 9);
    if (is_one_digit == TRUE) {
        tempvar new_int = num + 48;
        return (48,);
    }
    // will reurn an array of ascii encoded digits in reverse
    let (local new_arr_len) = _create_interger_ascii_array(arr=new_arr, inum=num, index=0);
    let (res) = _create_ascii_interger_from_inverse_asciiArray(0, new_arr_len, new_arr, 0);
    return (res,);
}
// -------------------------------------------------------------------------- //
//                                  internals                                 //
// -------------------------------------------------------------------------- //
func _create_interger_ascii_array{bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    arr: felt*, inum: felt, index: felt
) -> (len: felt) {
    alloc_locals;
    if (inum == 0) {
        return (index,);
    }

    let (quotient, rem) = unsigned_div_rem(inum, 10);
    assert [arr] = rem + 48;
    let new_index = index + 1;
    let (i) = _create_interger_ascii_array(arr=arr + 1, inum=quotient, index=new_index);
    return (i,);
}

func _create_ascii_interger_from_inverse_asciiArray{range_check_ptr}(
    ascii: felt, arr_len: felt, arr: felt*, index: felt
) -> (res: felt) {
    if (arr_len == index) {
        return (ascii,);
    }

    tempvar next_ascii = ascii * 256 + arr[arr_len - index - 1];
    return _create_ascii_interger_from_inverse_asciiArray(
        ascii=next_ascii, arr_len=arr_len, arr=arr, index=index + 1
    );
}
