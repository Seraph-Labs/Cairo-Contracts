%lang starknet

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
