%lang starknet
%builtins pedersen range_check bitwise

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from SeraphLabs.math.Time import Time

@view
func format_DHMS{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(num: felt) -> (
    day: felt, hour: felt, min: felt, sec: felt
) {
    let (day, hour, min, sec) = Time.format_day_hour_min_sec(num);
    return (day, hour, min, sec);
}

@view
func format_Y{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(num: felt) -> (
    x: felt, y: felt
) {
    let (x, y) = Time.format_year(num);
    return (x, y);
}

@view
func format_M{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(num: felt) -> (
    x: felt, y: felt
) {
    let (x, y) = Time.format_month(num);
    return (x, y);
}

@view
func format_W{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(num: felt) -> (
    x: felt, y: felt
) {
    let (x, y) = Time.format_week(num);
    return (x, y);
}
