from starkware.cairo.common.math import assert_le, assert_not_zero
# represents a 31 char string
struct StrObj:
    # the felt represented string etc 'foo'
    member val : felt
    # the length of the string etc 'foo' -> 3
    member len : felt
end

# Verifies that the given string is valid
func StrObj_check{range_check_ptr}(a : StrObj):
    assert_not_zero(a.val)
    assert_not_zero(a.len)
    assert_le(a.len, 31)
    return ()
end

func StrObj_is_equal{range_check_ptr}(a : StrObj, b : StrObj) -> (res : felt):
    StrObj_check(a)
    StrObj_check(b)
    if a.val == b.val:
        if a.len == b.len:
            return (1)
        end
        return (0)
    end
    return (0)
end
