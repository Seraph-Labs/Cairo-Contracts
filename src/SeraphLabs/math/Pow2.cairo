%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.registers import get_label_location
from SeraphLabs.math.BitsData import get_bit_data
//
// Compute power of 2
// taken from Warp's src
// https://github.com/NethermindEth/warp/blob/develop/src/warp/cairo-src/evm/pow2.cairo
// input range: 0~250
//
func pow2(i: felt) -> (res: felt) {
    let (data_address) = get_bit_data();
    return (data_address[i],);
}
