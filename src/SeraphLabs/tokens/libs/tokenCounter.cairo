%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_nn
from starkware.cairo.common.uint256 import Uint256, uint256_check, uint256_lt
from starkware.cairo.common.bool import TRUE, FALSE
from openzeppelin.security.safemath.library import SafeUint256

// ---------------------------------------------------------------------------- #
//                                    structs                                   #
// ---------------------------------------------------------------------------- #
struct TokenCountVal {
    tokenId: Uint256,
    burnt: felt,
}
// ---------------------------------------------------------------------------- #
//                                    storage                                   #
// ---------------------------------------------------------------------------- #
@storage_var
func _tokenCounters_value() -> (tokenId: Uint256) {
}
@storage_var
func _tokenCounters_burnt() -> (val: Uint256) {
}

namespace TokenCounter {
    func current{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() -> (
        counter: Uint256
    ) {
        let (counter: Uint256) = _tokenCounters_value.read();

        return (counter,);
    }

    func currentBurnt{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() -> (
        burn_val: Uint256
    ) {
        let (burn_val: Uint256) = _tokenCounters_burnt.read();

        return (burn_val,);
    }

    func increment{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
        alloc_locals;
        let (val) = _tokenCounters_value.read();
        let (local new_val: Uint256) = SafeUint256.add(val, Uint256(1, 0));
        _tokenCounters_value.write(value=new_val);
        return ();
    }

    func incrementBy{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
        ammount: Uint256
    ) {
        alloc_locals;
        let (val) = _tokenCounters_value.read();
        let (local new_val: Uint256) = SafeUint256.add(val, ammount);
        _tokenCounters_value.write(value=new_val);
        return ();
    }

    func burnIncrement{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
        alloc_locals;
        let (local val) = _tokenCounters_burnt.read();
        let (local new_val: Uint256) = SafeUint256.add(val, Uint256(1, 0));
        _tokenCounters_burnt.write(value=new_val);
        return ();
    }

    func burnIncrementBy{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
        ammount: Uint256
    ) {
        alloc_locals;
        let (local val: Uint256) = _tokenCounters_burnt.read();
        let (local new_val: Uint256) = SafeUint256.add(val, ammount);
        _tokenCounters_burnt.write(value=new_val);
        return ();
    }

    func decrement{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
        alloc_locals;
        let (local val: Uint256) = _tokenCounters_value.read();
        let (local is_valid) = uint256_lt(Uint256(0, 0), val);
        assert is_valid = TRUE;
        let (local new_val: Uint256) = SafeUint256.sub_le(val, Uint256(1, 0));
        _tokenCounters_value.write(value=new_val);
        return ();
    }

    func _reset{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
        _tokenCounters_value.write(value=Uint256(0, 0));
        return ();
    }
}
