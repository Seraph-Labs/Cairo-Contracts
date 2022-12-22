// SPDX-License-Identifier: MIT
// SeraphLabs Contracts for Cairo v0.3.0 (models/StringObject.cairo)
from starkware.cairo.common.math import assert_le, assert_not_zero
// represents a 31 char string
struct StrObj {
    // the felt represented string etc 'foo'
    val: felt,
    // the length of the string etc 'foo' -> 3
    len: felt,
}

// Verifies that the given string is valid
func StrObj_check{range_check_ptr}(a: StrObj) {
    assert_not_zero(a.val);
    assert_not_zero(a.len);
    assert_le(a.len, 31);
    return ();
}

// Verifies that the given string is valid and accounts for empty strings as valid StrObj
func assert_valid_StrObj{range_check_ptr}(a: StrObj) {
    if (a.val == 0) {
        assert_le(a.len, 31);
        return ();
    }
    StrObj_check(a);
    return ();
}

func StrObj_is_equal{range_check_ptr}(a: StrObj, b: StrObj) -> (res: felt) {
    StrObj_check(a);
    StrObj_check(b);
    if (a.val == b.val) {
        if (a.len == b.len) {
            return (1,);
        }
        return (0,);
    }
    return (0,);
}
