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
from SeraphLabs.arrays.ReverseArray import reverse_array
from SeraphLabs.models.StringObject import StrObj, StrObj_check

# ---------------------------------------------------------------------------- #
#                  converts a shortstring into an ascii array                  #
# ---------------------------------------------------------------------------- #

func word_to_ascii{bitwise_ptr : BitwiseBuiltin*, range_check_ptr}(Str : StrObj) -> (
    strArr_len : felt, strArr : felt*
):
    alloc_locals
    StrObj_check(Str)

    tempvar multiplier = 8 * Str.len
    let (local strArr : felt*) = alloc()
    _create_word_ascii_array(arr=strArr, word=Str.val, charIndex=Str.len, N=multiplier)
    return (Str.len, strArr)
end

func uint256_to_ascii{
    bitwise_ptr : BitwiseBuiltin*, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(num : Uint256) -> (arr_len : felt, arr : felt*):
    alloc_locals
    uint256_check(num)

    let (local new_arr : felt*) = alloc()

    let (is_one_digit) = uint256_le(num, Uint256(9, 0))
    if is_one_digit == TRUE:
        assert [new_arr] = num.low + 48
        return (1, new_arr)
    end
    let (local new_arr_len) = _create_uint_ascii_array(arr=new_arr, inum=num, index=0)
    let (r_arr_len, r_arr) = reverse_array(new_arr_len, new_arr)
    return (r_arr_len, r_arr)
end

func concat_word_with_uint{
    bitwise_ptr : BitwiseBuiltin*, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(Str : StrObj, uint : Uint256) -> (arr_len : felt, arr : felt*):
    alloc_locals
    let (new_arr_len, new_arr) = word_to_ascii(Str)
    let (uint_arr_len, uint_arr) = uint256_to_ascii(uint)
    memcpy(new_arr + new_arr_len, uint_arr, uint_arr_len)
    return (new_arr_len + uint_arr_len, new_arr)
end
# ---------------------------------------------------------------------------- #
#                                   internals                                  #
# ---------------------------------------------------------------------------- #
func _create_word_ascii_array{bitwise_ptr : BitwiseBuiltin*, range_check_ptr}(
    arr : felt*, word : felt, charIndex : felt, N : felt
):
    alloc_locals
    if charIndex == 0:
        return ()
    end

    tempvar n1 = N - 8

    if charIndex == 1:
        let (num) = bitwise_and(word, 2 ** 8 - 1)
        assert [arr] = num
        tempvar bitwise_ptr = bitwise_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        let (num) = _get_ascii_num(word, N, n1)
        assert [arr] = num
        tempvar bitwise_ptr = bitwise_ptr
        tempvar range_check_ptr = range_check_ptr
    end
    _create_word_ascii_array(arr=arr + 1, word=word, charIndex=charIndex - 1, N=n1)
    return ()
end

func _create_uint_ascii_array{bitwise_ptr : BitwiseBuiltin*, range_check_ptr}(
    arr : felt*, inum : Uint256, index : felt
) -> (len : felt):
    alloc_locals
    let (is_zero) = uint256_le(inum, Uint256(0, 0))
    if is_zero == TRUE:
        return (index)
    end

    let (quotient, rem) = uint256_unsigned_div_rem(inum, Uint256(10, 0))
    assert [arr] = rem.low + 48
    let new_index = index + 1
    let (i) = _create_uint_ascii_array(arr=arr + 1, inum=quotient, index=new_index)
    return (i)
end

func _get_ascii_num{bitwise_ptr : BitwiseBuiltin*, range_check_ptr}(
    _val : felt, multi1 : felt, multi2 : felt
) -> (res : felt):
    alloc_locals

    assert_not_zero(multi1 * multi2)
    assert_not_equal(multi1, multi2)
    let (is_smaller) = is_le(multi2, multi1)
    assert is_smaller = TRUE

    let (is_bigNum) = is_le(128, multi2)
    let (local mask_val1) = pow2(multi1)
    let (local mask_val2) = pow2(multi2)

    if multi2 == 128:
        let (tres) = bitwise_and(_val, mask_val1 - mask_val2)
        let (res, _) = split_felt(tres)
        return (res)
    end

    if is_bigNum == TRUE:
        tempvar tmulti = multi2 - 128
        let (new_div) = pow2(tmulti)

        let (tres1) = bitwise_and(_val, mask_val1 - mask_val2)
        let (tres2, _) = split_felt(tres1)
        let (res, _) = unsigned_div_rem(tres2, new_div)
        return (res)
    end
    let (tres) = bitwise_and(_val, mask_val1 - mask_val2)
    let (res, _) = unsigned_div_rem(tres, mask_val2)
    return (res)
end
