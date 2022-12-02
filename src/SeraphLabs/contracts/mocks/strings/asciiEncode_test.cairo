%lang starknet
%builtins pedersen range_check bitwise
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import Uint256, uint256_check
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from SeraphLabs.strings.AsciiEncode import interger_to_ascii

@view
func return_ascii_interger{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(num: felt) -> (res: felt) {
    let (res) = interger_to_ascii(num);
    return (res,);
}
