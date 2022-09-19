%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.math import unsigned_div_rem
from SeraphLabs.math.logicalOpr import LogicalOpr

namespace Time {
    func min{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(num: felt) -> (
        res: felt
    ) {
        let (sec) = _time_get_data(0);
        tempvar res = sec * num;
        return (res,);
    }

    func hour{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(num: felt) -> (
        res: felt
    ) {
        let (sec) = _time_get_data(1);
        tempvar res = sec * num;
        return (res,);
    }

    func day{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(num: felt) -> (
        res: felt
    ) {
        let (sec) = _time_get_data(2);
        tempvar res = sec * num;
        return (res,);
    }

    func week{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(num: felt) -> (
        res: felt
    ) {
        let (sec) = _time_get_data(3);
        tempvar res = sec * num;
        return (res,);
    }

    func month{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(num: felt) -> (
        res: felt
    ) {
        let (sec) = _time_get_data(4);
        tempvar res = sec * num;
        return (res,);
    }

    func year{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(num: felt) -> (
        res: felt
    ) {
        let (sec) = _time_get_data(5);
        tempvar res = sec * num;
        return (res,);
    }

    func format_year{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
        num: felt
    ) -> (year: felt, sec: felt) {
        alloc_locals;
        let (local x) = year(1);
        let (is_lesser) = LogicalOpr.is_lt(num, x);
        if (is_lesser == TRUE) {
            return (0, num);
        }
        let (q, r) = unsigned_div_rem(num, x);
        return (q, r);
    }

    func format_month{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
        num: felt
    ) -> (month: felt, sec: felt) {
        alloc_locals;
        let (local x) = month(1);
        let (is_lesser) = LogicalOpr.is_lt(num, x);
        if (is_lesser == TRUE) {
            return (0, num);
        }
        let (q, r) = unsigned_div_rem(num, x);
        return (q, r);
    }

    func format_week{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
        num: felt
    ) -> (week: felt, sec: felt) {
        alloc_locals;
        let (local x) = week(1);
        let (is_lesser) = LogicalOpr.is_lt(num, x);
        if (is_lesser == TRUE) {
            return (0, num);
        }
        let (q, r) = unsigned_div_rem(num, x);
        return (q, r);
    }

    func format_day{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(num: felt) -> (
        day: felt, sec: felt
    ) {
        alloc_locals;
        let (local x) = day(1);
        let (is_lesser) = LogicalOpr.is_lt(num, x);
        if (is_lesser == TRUE) {
            return (0, num);
        }
        let (q, r) = unsigned_div_rem(num, x);
        return (q, r);
    }

    func format_hour{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
        num: felt
    ) -> (hour: felt, sec: felt) {
        alloc_locals;
        let (local x) = hour(1);
        let (is_lesser) = LogicalOpr.is_lt(num, x);
        if (is_lesser == TRUE) {
            return (0, num);
        }
        let (q, r) = unsigned_div_rem(num, x);
        return (q, r);
    }

    func format_min{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(num: felt) -> (
        min: felt, sec: felt
    ) {
        alloc_locals;
        let (local x) = min(1);
        let (is_lesser) = LogicalOpr.is_lt(num, x);
        if (is_lesser == TRUE) {
            return (0, num);
        }
        let (q, r) = unsigned_div_rem(num, x);
        return (q, r);
    }

    func format_day_hour_min_sec{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
        num: felt
    ) -> (day: felt, hour: felt, min: felt, sec: felt) {
        alloc_locals;
        let (day, sec) = format_day(num);
        let (hour, sec) = format_hour(sec);
        let (min, sec) = format_min(sec);
        return (day, hour, min, sec);
    }
}

func _time_get_data(i) -> (time: felt) {
    let (time_addr) = get_label_location(data_time);
    return ([time_addr + i],);

    data_time:
    dw 60;  // min
    dw 3600;  // hour
    dw 86400;  // day
    dw 604800;  // week
    dw 2419200;  // month
    dw 29030400;  // year
}
