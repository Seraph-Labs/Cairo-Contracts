// SPDX-License-Identifier: MIT
// SeraphLabs Contracts for Cairo v0.3.0 (math/simple_checks.cairo)
%lang starknet
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_lt,
    uint256_add,
    uint256_check,
    uint256_eq,
)

func is_lt{range_check_ptr}(a: felt, b: felt) -> (res: felt) {
    if (a == b) {
        return (0,);
    }
    let res = is_le(a, b);
    return (res,);
}

func is_equal{range_check_ptr}(a: felt, b: felt) -> (res: felt) {
    if (a == b) {
        return (1,);
    }
    return (0,);
}

func not_equal{range_check_ptr}(a: felt, b: felt) -> (res: felt) {
    if (a == b) {
        return (0,);
    }
    return (1,);
}

func true_and_false{range_check_ptr}(a: felt, b: felt) -> (res: felt) {
    if (a == 0) {
        return (0,);
    }
    if (b == 1) {
        return (0,);
    }
    return (1,);
}

func is_uint_valid{range_check_ptr}(a: Uint256) -> (res: felt) {
    uint256_check(a);
    let (result) = uint256_lt(Uint256(0, 0), a);
    return (result,);
}
