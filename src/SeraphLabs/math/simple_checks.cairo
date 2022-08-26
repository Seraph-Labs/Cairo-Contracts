%lang starknet
from starkware.cairo.common.math_cmp import is_le

func is_lt{range_check_ptr}(a : felt, b : felt) -> (res : felt):
    if a == b:
        return (0)
    end
    let (res) = is_le(a, b)
    return (res)
end

func is_equal{range_check_ptr}(a : felt, b : felt) -> (res : felt):
    if a == b:
        return (1)
    end
    return (0)
end

func not_equal{range_check_ptr}(a : felt, b : felt) -> (res : felt):
    if a == b:
        return (0)
    end
    return (1)
end

func true_and_false{range_check_ptr}(a : felt, b : felt) -> (res : felt):
    if a == 0:
        return (0)
    end
    if b == 1:
        return (0)
    end
    return (1)
end
