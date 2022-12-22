// SPDX-License-Identifier: MIT
// SeraphLabs Contracts for Cairo v0.3.0 (tokens/ERC3525/utils/slotSupplyHandler.cairo)
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_nn
from starkware.cairo.common.uint256 import Uint256, uint256_check, uint256_lt
from starkware.cairo.common.bool import TRUE, FALSE
from openzeppelin.security.safemath.library import SafeUint256

// ---------------------------------------------------------------------------- #
//                                    storage                                   #
// ---------------------------------------------------------------------------- #
@storage_var
func ERC3525_slotSupply(slot: Uint256) -> (supply: Uint256) {
}

namespace SlotSupplyHandler {
    func supply{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
        _slot: Uint256
    ) -> (balance: Uint256) {
        let (balance: Uint256) = ERC3525_slotSupply.read(_slot);
        return (balance,);
    }

    func increaseSupply{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
        _slot: Uint256, ammount: Uint256
    ) {
        alloc_locals;
        let (val) = ERC3525_slotSupply.read(_slot);
        let (local new_val: Uint256) = SafeUint256.add(val, ammount);
        ERC3525_slotSupply.write(slot=_slot, value=new_val);
        return ();
    }

    func decreaseSupply{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
        _slot: Uint256, ammount: Uint256
    ) {
        alloc_locals;
        let (local val: Uint256) = ERC3525_slotSupply.read(_slot);
        let (local is_valid) = uint256_lt(Uint256(0, 0), val);
        assert is_valid = TRUE;
        let (local new_val: Uint256) = SafeUint256.sub_le(val, ammount);
        ERC3525_slotSupply.write(slot=_slot, value=new_val);
        return ();
    }

    func _reset{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(_slot: Uint256) {
        ERC3525_slotSupply.write(slot=_slot, value=Uint256(0, 0));
        return ();
    }
}
