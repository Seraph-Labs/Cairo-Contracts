//
// library for logical operators
//
%lang starknet
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math_cmp import is_le

namespace LogicalOpr {
    func AND{range_check_ptr}(a: felt, b: felt) -> (res: felt) {
        let res = a * b;
        return (res,);
    }

    func OR{range_check_ptr}(a: felt, b: felt) -> (res: felt) {
        if (a == TRUE) {
            return (TRUE,);
        }

        if (b == TRUE) {
            return (TRUE,);
        }
        return (FALSE,);
    }

    func NOT{range_check_ptr}(a: felt) -> (res: felt) {
        if (a == TRUE) {
            return (FALSE,);
        } else {
            return (TRUE,);
        }
    }

    func is_lt{range_check_ptr}(a: felt, b: felt) -> (res: felt) {
        if (a == b) {
            return (FALSE,);
        }
        let res = is_le(a, b);
        return (res,);
    }

    func is_equal{range_check_ptr}(a: felt, b: felt) -> (res: felt) {
        if (a == b) {
            return (TRUE,);
        }
        return (FALSE,);
    }

    func not_equal{range_check_ptr}(a: felt, b: felt) -> (res: felt) {
        if (a == b) {
            return (FALSE,);
        }
        return (TRUE,);
    }
}
