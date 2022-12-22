// SPDX-License-Identifier: MIT
// SeraphLabs Contracts for Cairo v0.3.0 (tokens/ERC3525/interfaces/IERC3525_Reciever.cairo)
%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC3525_Receiver {
    func onERC3525Received(
        operator: felt, from_: felt, tokenId: Uint256, units: Uint256, data_len: felt, data: felt*
    ) -> (selector: felt) {
    }
}
