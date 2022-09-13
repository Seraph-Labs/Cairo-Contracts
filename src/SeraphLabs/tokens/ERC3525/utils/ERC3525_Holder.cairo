%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.introspection.ERC165.library import ERC165

from SeraphLabs.utils.constants import IERC3525_RECEIVER_ID

@view
func onERC3525Received(
    operator: felt, from_: felt, tokenId: Uint256, units: Uint256, data_len: felt, data: felt
) -> (selector: felt) {
    return (IERC3525_RECEIVER_ID,);
}

@view
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    interfaceId: felt
) -> (success: felt) {
    let (success) = ERC165.supports_interface(interfaceId);
    return (success,);
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    ERC165.register_interface(IERC3525_RECEIVER_ID);
    return ();
}
