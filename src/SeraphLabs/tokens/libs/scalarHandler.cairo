%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_not_equal, assert_le
from starkware.cairo.common.math_cmp import is_not_zero, is_le
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import Uint256, uint256_check
from starkware.cairo.common.math import unsigned_div_rem, assert_nn_le, split_felt
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.alloc import alloc

from openzeppelin.security.safemath.library import SafeUint256
from SeraphLabs.math.simple_checks import is_uint_valid

// ---------------------------------------------------------------------------- #
//                                   constants                                  #
// ---------------------------------------------------------------------------- #

// ------------------------ Constants for packing data ------------------------ #
const MAX_bool = 2 ** 65;
const MAX_sequence = 2 ** 120;
const SHIFT_DATA_1 = 2 ** 65;
const SHIFT_DATA_2 = 2 ** 130;
const MASK_DATA_0 = 2 ** 65 - 1;
const MASK_DATA_1 = 2 ** 130 - 2 ** 65;
const MASK_DATA_2 = 2 ** 250 - 2 ** 130;
// ------------------------ constants for packing slot ------------------------ #
const MAX_slot = 2 ** 128 - 1;
const SHIFT_SLOT_1 = 2 ** 128;
const MASK_SLOT_0 = 2 ** 128 - 1;
const MASK_SLOT_1 = 2 ** 250 - 2 ** 128;
// -------------------------- constants for division -------------------------- #
const DIV_2 = 2 ** 2;
const DIV_10 = 2 ** 10;
const DIV_20 = 2 ** 20;
const DIV_65 = 2 ** 65;
const DIV_100 = 2 ** 100;
const DIV_120 = 2 ** 120;
// ---------------------------------------------------------------------------- #
//                                    structs                                   #
// ---------------------------------------------------------------------------- #

struct ScalarAsset {
    owner: felt,
    slot: felt,
    units: Uint256,
    data: felt,
}
// ---------------------------------------------------------------------------- #
//                                 documentation                                #
// ---------------------------------------------------------------------------- #
// slot
// [xxxx xxxx]
//   |   |
//  |    ----> slot_seq : for slot iteration [120 bits]
//  ---------> slot_id : [128 bits]
// ----------------------------------------------------------------------------- #
// data
// [XX  XX  XXXXX]
//  |   |    |
//  |   |     -------> next_seq : used for iteration [120 bits]
//  |   -------------> is_parent : a boolean to check if token has children [65 bits]
//   ----------------> not_valid: a bolean check if token is burnt [65 bits]
// ----------------------------------------------------------------------------- #
//  safe check vs check on not_valid
//     - unsafe checks on data assumes that when not_valid is set to TRUE
//     - all other data variables is set to 0 thus data will just equal TRUE
//     - due to not_valid being the lowest end of bits in the packed data
//     - only use unsafe check if your contract burning mechanism garauntees
//     - that all packed data variables will be set to zero except not_valid
//     - benefit of using unsafe checks is to save gas on computation
//     - as unpacking data uses bitwise operations which are supposedly relatively expensive
// ---------------------------------------------------------------------------- #

namespace ScalarHandler {
    // ---------------------------------------------------------------------------- #
    //                                     view                                     #
    // ---------------------------------------------------------------------------- #

    func safe_check_not_valid{
        bitwise_ptr: BitwiseBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr,
        pedersen_ptr: HashBuiltin*,
    }(_asset: ScalarAsset) -> (res: felt) {
        let (not_valid) = _safe_check_not_valid(_asset);
        return (not_valid,);
    }

    func safe_check_is_valid{
        bitwise_ptr: BitwiseBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr,
        pedersen_ptr: HashBuiltin*,
    }(_asset: ScalarAsset) -> (res: felt) {
        let (not_valid) = _safe_check_not_valid(_asset);
        if (not_valid == TRUE) {
            return (FALSE,);
        }
        return (TRUE,);
    }

    func check_is_valid{
        bitwise_ptr: BitwiseBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr,
        pedersen_ptr: HashBuiltin*,
    }(_asset: ScalarAsset) -> (res: felt) {
        if (_asset.data == TRUE) {
            return (FALSE,);
        }
        return (TRUE,);
    }

    func check_is_parent{
        bitwise_ptr: BitwiseBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr,
        pedersen_ptr: HashBuiltin*,
    }(_asset: ScalarAsset) -> (res: felt) {
        let (is_parent) = _check_is_parent(_asset);
        return (is_parent,);
    }

    func safe_check_is_asset_owner{
        bitwise_ptr: BitwiseBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr,
        pedersen_ptr: HashBuiltin*,
    }(_asset: ScalarAsset, owner: felt) -> (res: felt) {
        let (is_burnt) = _safe_check_not_valid(_asset);
        if (is_burnt == TRUE) {
            return (FALSE,);
        }
        if (_asset.owner == owner) {
            return (TRUE,);
        }
        return (FALSE,);
    }

    // check if asset is owned by owner and that it is not burnt
    func check_is_asset_owner{
        bitwise_ptr: BitwiseBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr,
        pedersen_ptr: HashBuiltin*,
    }(_asset: ScalarAsset, owner: felt) -> (res: felt) {
        if (_asset.data == TRUE) {
            return (FALSE,);
        }
        if (_asset.owner == owner) {
            return (TRUE,);
        }
        return (FALSE,);
    }

    // use to check if asset has owner , not burned and has sequence
    // if not return false to skip to the next iteration
    func check_has_owner_seq_not_burnt{
        bitwise_ptr: BitwiseBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr,
        pedersen_ptr: HashBuiltin*,
    }(_asset: ScalarAsset) -> (res: felt) {
        alloc_locals;
        local is_valid_owner = is_not_zero(_asset.owner);
        // if owner is zero address return false
        if (is_valid_owner == FALSE) {
            return (FALSE,);
        }
        let (local is_burnt, _, local next_seq) = unpack_data(_asset.data);
        // if token is_burnt return false
        if (is_burnt == TRUE) {
            return (FALSE,);
        }
        // check if next_seq >= 1
        let res = is_le(1, next_seq);
        return (res,);
    }

    func get_next_seq{
        bitwise_ptr: BitwiseBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr,
        pedersen_ptr: HashBuiltin*,
    }(_asset: ScalarAsset) -> (res: felt) {
        alloc_locals;
        let (next_seq) = _get_next_seq(_asset);
        return (next_seq,);
    }

    func get_scalar_data{
        bitwise_ptr: BitwiseBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr,
        pedersen_ptr: HashBuiltin*,
    }(_asset: ScalarAsset) -> (is_burnt: felt, is_parent: felt, next_seq: felt) {
        alloc_locals;
        if (_asset.data == 0) {
            return (0, 0, 0);
        }
        let (is_burnt, is_parent, next_seq) = unpack_data(_asset.data);
        return (is_burnt, is_parent, next_seq);
    }

    func get_slot_id{
        bitwise_ptr: BitwiseBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr,
        pedersen_ptr: HashBuiltin*,
    }(_asset: ScalarAsset) -> (slot_id: felt) {
        alloc_locals;
        let (slot_id) = _get_slot_id(_asset);
        return (slot_id,);
    }

    func get_slot_seq{
        bitwise_ptr: BitwiseBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr,
        pedersen_ptr: HashBuiltin*,
    }(_asset: ScalarAsset) -> (slot_seq: felt) {
        alloc_locals;
        let (slot_seq) = _get_slot_seq(_asset);
        return (slot_seq,);
    }

    func get_scalar_slot{
        bitwise_ptr: BitwiseBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr,
        pedersen_ptr: HashBuiltin*,
    }(_asset: ScalarAsset) -> (slot_id: felt, slot_seq: felt) {
        alloc_locals;
        if (_asset.slot == 0) {
            return (0, 0);
        }
        let (slot_id, slot_seq) = unpack_slot(_asset.slot);
        return (slot_id, slot_seq);
    }

    // ---------------------------------------------------------------------------- #
    //                                     logic                                    #
    // ---------------------------------------------------------------------------- #

    // ----------------------------------- merge ---------------------------------- #
    func asset_merge_units{
        bitwise_ptr: BitwiseBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr,
        pedersen_ptr: HashBuiltin*,
    }(_assets_len: felt, _assets: ScalarAsset*, target_asset: ScalarAsset) -> (asset: ScalarAsset) {
        let (sum_units: Uint256) = _merge_units_loop(_assets_len, _assets);
        let (new_sum: Uint256) = SafeUint256.add(target_asset.units, sum_units);
        return (
            ScalarAsset(owner=target_asset.owner, slot=target_asset.slot, units=new_sum, data=target_asset.data),
        );
    }

    // ----------------------------------- slot ----------------------------------- #
    func update_slot_id{
        bitwise_ptr: BitwiseBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr,
        pedersen_ptr: HashBuiltin*,
    }(_asset: ScalarAsset, _slot_id: felt) -> (asset: ScalarAsset) {
        alloc_locals;
        let (slot_id, slot_seq) = unpack_slot(_asset.slot);
        if (slot_id == _slot_id) {
            return (_asset,);
        }
        let (_slot) = pack_slot(_slot_id, slot_seq);
        return (ScalarAsset(owner=_asset.owner, slot=_slot, units=_asset.units, data=_asset.data),);
    }

    func update_slot_seq{
        bitwise_ptr: BitwiseBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr,
        pedersen_ptr: HashBuiltin*,
    }(_asset: ScalarAsset, _slot_seq: felt) -> (asset: ScalarAsset) {
        alloc_locals;
        let (slot_id, slot_seq) = unpack_slot(_asset.slot);
        if (slot_seq == _slot_seq) {
            return (_asset,);
        }
        let (_slot) = pack_slot(slot_id, _slot_seq);
        return (ScalarAsset(owner=_asset.owner, slot=_slot, units=_asset.units, data=_asset.data),);
    }

    func update_slot{
        bitwise_ptr: BitwiseBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr,
        pedersen_ptr: HashBuiltin*,
    }(_asset: ScalarAsset, _slot_id: felt, _slot_seq: felt) -> (asset: ScalarAsset) {
        alloc_locals;
        let (_slot) = pack_slot(_slot_id, _slot_seq);
        return (ScalarAsset(owner=_asset.owner, slot=_slot, units=_asset.units, data=_asset.data),);
    }

    // ----------------------------------- units ---------------------------------- #
    func unit_add{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
        _asset: ScalarAsset, _unit: Uint256
    ) -> (asset: ScalarAsset) {
        let (is_uintValid) = is_uint_valid(_unit);
        assert is_uintValid = TRUE;
        let (new_unit: Uint256) = SafeUint256.add(_asset.units, _unit);
        return (
            ScalarAsset(owner=_asset.owner, slot=_asset.slot, units=new_unit, data=_asset.data),
        );
    }

    func unit_sub{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
        _asset: ScalarAsset, _unit: Uint256
    ) -> (asset: ScalarAsset) {
        let (is_uintValid) = is_uint_valid(_unit);
        assert is_uintValid = TRUE;
        let (new_unit: Uint256) = SafeUint256.sub_le(_asset.units, _unit);
        return (
            ScalarAsset(owner=_asset.owner, slot=_asset.slot, units=new_unit, data=_asset.data),
        );
    }

    // --------------------------------- data --------------------------------- #
    func update_validity{
        bitwise_ptr: BitwiseBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr,
        pedersen_ptr: HashBuiltin*,
    }(_asset: ScalarAsset, _not_valid: felt) -> (asset: ScalarAsset) {
        alloc_locals;
        with_attr error_message("ScalarHandler: _not_valid has to be 0 or 1") {
            assert (_not_valid - 1) * (_not_valid - 0) = 0;
        }

        let data_pack = _asset.data;
        let (not_valid, is_parent, next_seq) = unpack_data(data_pack);
        if (not_valid == _not_valid) {
            return (_asset,);
        }
        let (new_data) = pack_data(_not_valid, is_parent, next_seq);
        return (
            ScalarAsset(owner=_asset.owner, slot=_asset.slot, units=_asset.units, data=new_data),
        );
    }

    func update_isParent{
        bitwise_ptr: BitwiseBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr,
        pedersen_ptr: HashBuiltin*,
    }(_asset: ScalarAsset, _is_parent: felt) -> (asset: ScalarAsset) {
        alloc_locals;
        with_attr error_message("ScalarHandler: _is_parent has to be 0 or 1") {
            assert (_is_parent - 1) * (_is_parent - 0) = 0;
        }

        let data_pack = _asset.data;
        let (not_valid, is_parent, next_seq) = unpack_data(data_pack);
        if (is_parent == _is_parent) {
            return (_asset,);
        }
        let (new_data) = pack_data(not_valid, _is_parent, next_seq);
        return (
            ScalarAsset(owner=_asset.owner, slot=_asset.slot, units=_asset.units, data=new_data),
        );
    }

    func update_next_seq{
        bitwise_ptr: BitwiseBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr,
        pedersen_ptr: HashBuiltin*,
    }(_asset: ScalarAsset, _num: felt) -> (asset: ScalarAsset) {
        alloc_locals;
        let data_pack = _asset.data;
        let (not_valid, is_parent, next_seq) = unpack_data(data_pack);
        if (_num == next_seq) {
            return (_asset,);
        }
        let (new_data) = pack_data(not_valid, is_parent, _num);
        return (
            ScalarAsset(owner=_asset.owner, slot=_asset.slot, units=_asset.units, data=new_data),
        );
    }

    func add_next_seq{
        bitwise_ptr: BitwiseBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr,
        pedersen_ptr: HashBuiltin*,
    }(_asset: ScalarAsset, _num: felt) -> (asset: ScalarAsset) {
        alloc_locals;
        let data_pack = _asset.data;
        let (not_valid, is_parent, next_seq) = unpack_data(data_pack);
        if (_num == 0) {
            return (_asset,);
        }
        tempvar new_seq = next_seq + _num;
        let (new_data) = pack_data(not_valid, is_parent, new_seq);
        return (
            ScalarAsset(owner=_asset.owner, slot=_asset.slot, units=_asset.units, data=new_data),
        );
    }

    func sub_next_seq{
        bitwise_ptr: BitwiseBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr,
        pedersen_ptr: HashBuiltin*,
    }(_asset: ScalarAsset, _num: felt) -> (asset: ScalarAsset) {
        alloc_locals;
        let data_pack = _asset.data;
        let (not_valid, is_parent, next_seq) = unpack_data(data_pack);
        if (next_seq == 0) {
            return (_asset,);
        }
        assert_le(_num, next_seq);
        tempvar new_seq = next_seq - _num;
        let (new_data) = pack_data(not_valid, is_parent, new_seq);
        return (
            ScalarAsset(owner=_asset.owner, slot=_asset.slot, units=_asset.units, data=new_data),
        );
    }
}

// ---------------------------------------------------------------------------- #
//                        internals (not to be imported)                        #
// ---------------------------------------------------------------------------- #

func _merge_units_loop{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(_assets_len: felt, _assets: ScalarAsset*) -> (sum: Uint256) {
    alloc_locals;
    if (_assets_len == 0) {
        return (sum=Uint256(0, 0));
    }
    let (local current_sum: Uint256) = _merge_units_loop(
        _assets_len=_assets_len - 1, _assets=_assets + ScalarAsset.SIZE
    );
    _check_mergingAsset([_assets]);
    let (sum: Uint256) = SafeUint256.add([_assets].units, current_sum);
    return (sum,);
}

func _check_mergingAsset{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(_asset: ScalarAsset) {
    let data_pack = _asset.data;
    let (not_valid, is_parent, _) = unpack_data(data_pack);
    with_attr error_message("ScalarHandler: cant merge as asset is parent, or not valid") {
        assert not_valid = TRUE;
        assert is_parent = FALSE;
    }
    return ();
}

// ---------------------------------------------------------------------------- #
//                               packing data                               #
// ---------------------------------------------------------------------------- #
func pack_data{range_check_ptr}(not_valid: felt, is_parent: felt, next_seq: felt) -> (num: felt) {
    alloc_locals;
    // Checking that the numbers are within the valid range
    assert_nn_le(not_valid, MAX_bool);
    assert_nn_le(is_parent, MAX_bool);
    assert_nn_le(next_seq, MAX_sequence);

    // Shifting via multiplication
    tempvar t1 = is_parent * SHIFT_DATA_1;
    tempvar t2 = next_seq * SHIFT_DATA_2;
    tempvar num = t2 + t1 + not_valid;
    // packedData.write(t1 + num0)
    return (num,);
}

func unpack_data{bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(num: felt) -> (
    not_valid: felt, is_parent: felt, next_seq: felt
) {
    alloc_locals;
    // Masking out each number
    let (not_valid) = bitwise_and(num, MASK_DATA_0);
    let (t1) = bitwise_and(num, MASK_DATA_1);
    let (t2) = bitwise_and(num, MASK_DATA_2);

    // Shifting via division
    let (is_parent, _) = unsigned_div_rem(t1, DIV_65);
    let (t2, _) = split_felt(t2);
    let (next_seq, _) = unsigned_div_rem(t2, DIV_2);

    return (not_valid, is_parent, next_seq);
}

func _safe_check_not_valid{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(_asset: ScalarAsset) -> (res: felt) {
    let data_pack = _asset.data;
    let (not_valid) = bitwise_and(data_pack, MASK_DATA_0);
    return (not_valid,);
}

func _check_is_parent{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(_asset: ScalarAsset) -> (res: felt) {
    let data_pack = _asset.data;
    let (t1) = bitwise_and(data_pack, MASK_DATA_1);
    let (is_parent, _) = unsigned_div_rem(t1, DIV_65);
    return (is_parent,);
}

func _get_next_seq{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(_asset: ScalarAsset) -> (res: felt) {
    let data_pack = _asset.data;
    let (t2) = bitwise_and(data_pack, MASK_DATA_2);
    let (t2, _) = split_felt(t2);
    let (next_seq, _) = unsigned_div_rem(t2, DIV_2);
    return (next_seq,);
}
// ---------------------------------------------------------------------------- #
//                                 packing slot                                 #
// ---------------------------------------------------------------------------- #
func pack_slot{range_check_ptr}(slot_id: felt, slot_seq: felt) -> (num: felt) {
    alloc_locals;
    // Checking that the numbers are within the valid range
    assert_nn_le(slot_id, MAX_slot);
    assert_nn_le(slot_seq, MAX_sequence);

    // Shifting via multiplication
    tempvar t1 = slot_seq * SHIFT_SLOT_1;
    tempvar num = t1 + slot_id;
    // packedData.write(t1 + num0)
    return (num,);
}

func unpack_slot{bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(num: felt) -> (
    slot_id: felt, slot_seq: felt
) {
    alloc_locals;
    // Masking out each number
    let (slot_id) = bitwise_and(num, MASK_SLOT_0);
    let (t1) = bitwise_and(num, MASK_SLOT_1);

    // Shifting via division
    let (slot_seq, _) = split_felt(t1);

    return (slot_id, slot_seq);
}

func _get_slot_id{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(_asset: ScalarAsset) -> (res: felt) {
    let (slot_id) = bitwise_and(_asset.slot, MASK_SLOT_0);
    return (slot_id,);
}

func _get_slot_seq{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(_asset: ScalarAsset) -> (res: felt) {
    let (t1) = bitwise_and(_asset.slot, MASK_SLOT_1);
    let (slot_seq, _) = split_felt(t1);
    return (slot_seq,);
}
