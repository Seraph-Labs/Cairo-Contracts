%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_not_zero, assert_not_equal, assert_nn_le
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_check,
    uint256_le,
    uint256_lt,
    uint256_eq,
)
from starkware.cairo.common.math_cmp import is_not_zero, is_le

from openzeppelin.security.safemath.library import SafeUint256

from openzeppelin.introspection.ERC165.library import ERC165

from openzeppelin.introspection.ERC165.IERC165 import IERC165

from SeraphLabs.tokens.ERC3525.interfaces.IERC3525_Receiver import IERC3525_Receiver

// ---------------------------------- my libs --------------------------------- //
from SeraphLabs.utils.constants import (
    IERC3525_ID,
    IERC3525_RECEIVER_ID,
    IACCOUNT_ID,
    OLD_ACCOUNT_ID,
)

from SeraphLabs.tokens.libs.scalarHandler import ScalarHandler, ScalarAsset

from SeraphLabs.math.simple_checks import true_and_false

from SeraphLabs.tokens.libs.tokenCounter import TokenCounter

from SeraphLabs.tokens.ERC3525.utils.slotSupplyHandler import SlotSupplyHandler

from SeraphLabs.tokens.ERC721S.library import (
    ERC721S_initializer,
    ERC721S_exist,
    ERC721S_ownerOf,
    ERC721S_isApprovedForAll,
    ERC721S_scalarMint,
    ERC721S_scalarBurn,
    ERC721S_getTokenAsset,
    ERC721S_changeTokenAsset,
    ERC721S_balanceOf,
    ERC721S_changeOwnerBalance,
)
// ---------------------------------------------------------------------------- #
//                                    structs                                   #
// ---------------------------------------------------------------------------- #
struct UnitApprovedOperator {
    units: Uint256,
    operator: felt,
}
// ---------------------------------------------------------------------------- #
//                                    events                                    #
// ---------------------------------------------------------------------------- #
@event
func TransferUnits(
    from_: felt, to: felt, tokenId: Uint256, targetTokenId: Uint256, transferUnits: Uint256
) {
}

@event
func Split(owner: felt, tokenId: Uint256, newTokenId: Uint256, splitUnits: Uint256) {
}

@event
func Merge(owner: felt, tokenId: Uint256, targetTokenId: Uint256, mergeUnits: Uint256) {
}

@event
func ApprovalUnits(owner: felt, approved: felt, tokenId: Uint256, approvalUnits: Uint256) {
}

// ---------------------------------------------------------------------------- #
//                                    storage                                   #
// ---------------------------------------------------------------------------- #
@storage_var
func ERC3525_units_approval(tokenId: Uint256, index: felt) -> (
    unit_approval: UnitApprovedOperator
) {
}

@storage_var
func ERC3525_units_approval_len(tokenId: Uint256) -> (len: felt) {
}

// ---------------------------------------------------------------------------- #
//                                  constructor                                 #
// ---------------------------------------------------------------------------- #
func ERC3525_initializer{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    ERC165.register_interface(IERC3525_ID);
    return ();
}
// ---------------------------------------------------------------------------- #
//                                view functions                                #
// ---------------------------------------------------------------------------- #
func ERC3525_slotOf{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256) -> (slot: Uint256) {
    // ------------------ 1. check if tokenId is a valid Uint256 ------------------ #
    with_attr error_message("ERC3525: tokenId is not a valid Uint256") {
        uint256_check(tokenId);
    }
    // -------------------------- 2. check if token exist ------------------------- #
    with_attr error_message("ERC3525: tokenId does not exist") {
        let (is_exist) = ERC721S_exist(tokenId);
        assert is_exist = TRUE;
    }
    let (slot, _) = _slot_of(tokenId);
    return (slot,);
}

func ERC3525_supplyOfSlot{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    slot: Uint256
) -> (supply: Uint256) {
    let (supply: Uint256) = SlotSupplyHandler.supply(slot);
    return (supply,);
}

func ERC3525_tokenOfSlotByIndex{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(slot: Uint256, index: Uint256) -> (tokenId: Uint256) {
    alloc_locals;
    // --------------------- 1. ensure valid uint and slot > 0 -------------------- #
    with_attr error_message("ERC3525 : either slot or index is invalid uint256") {
        uint256_check(slot);
        uint256_check(index);
        let (valid_slot) = uint256_lt(Uint256(0, 0), slot);
        assert valid_slot = TRUE;
    }
    // ---------------------- 2. ensure index < slot_supply ---------------------- #
    let (local slot_supply: Uint256) = SlotSupplyHandler.supply(slot);
    with_attr error_message("ERC3525: index is out of bounds") {
        let (is_in_range) = uint256_lt(index, slot_supply);
        assert is_in_range = TRUE;
    }
    // -------------- 3. start iterating through tokens to find index ------------- #
    let (local max_id: Uint256) = TokenCounter.current();
    let (tokenId: Uint256) = _token_of_slot_index_loop(
        slot=slot, index=index, tokenId_idx=Uint256(1, 0), max_id=max_id
    );
    return (tokenId,);
}

func ERC3525_unitsInToken{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256) -> (units: Uint256) {
    alloc_locals;
    with_attr error_message("ERC3525: tokenId is not a valid Uint256") {
        uint256_check(tokenId);
    }

    with_attr error_message("ERC3525: tokenId does not exist") {
        let (is_exist) = ERC721S_exist(tokenId);
        assert is_exist = TRUE;
    }
    let (sAsset: ScalarAsset) = ERC721S_getTokenAsset(tokenId);
    return (sAsset.units,);
}

func ERC3525_allowance{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256, spender: felt) -> (allowed_units: Uint256) {
    alloc_locals;
    with_attr error_message("ERC3525: tokenId does not exist") {
        let (is_exist) = ERC721S_exist(tokenId);
        assert is_exist = TRUE;
    }

    let (local opr_len) = ERC3525_units_approval_len.read(tokenId);
    if (opr_len == 0) {
        return (Uint256(0, 0),);
    }
    let (local idx) = _find_unit_approve_index(tokenId, opr_len, spender);
    if (idx == 0) {
        return (Uint256(0, 0),);
    }
    let (unit_approve: UnitApprovedOperator) = ERC3525_units_approval.read(tokenId, idx);
    return (unit_approve.units,);
}

// ---------------------------------------------------------------------------- #
//                              external functions                              #
// ---------------------------------------------------------------------------- #
func ERC3525_mint{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(to: felt, _quantity: Uint256, _slotId: Uint256, _units: Uint256) {
    // 1. increase supply
    SlotSupplyHandler.increaseSupply(_slotId, _quantity);
    // 2. mint tokens
    ERC721S_scalarMint(to, _quantity, _slotId, _units);
    return ();
}

func ERC3525_safeMint{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(to: felt, _quantity: Uint256, _slotId: Uint256, _units: Uint256, data_len: felt, data: felt*) {
    alloc_locals;
    let (cur_id) = TokenCounter.current();
    let (local next_tokenId: Uint256) = SafeUint256.add(cur_id, Uint256(1, 0));
    ERC3525_mint(to, _quantity, _slotId, _units);
    _ERC3525_do_safe_transfer_acceptance_check_loop(
        from_=0,
        to=to,
        tokenId=next_tokenId,
        _units=_units,
        index=_quantity.low,
        data_len=data_len,
        data=data,
    );
    return ();
}

func ERC3525_burn{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256) {
    alloc_locals;
    let (local slot: Uint256) = ERC3525_slotOf(tokenId);
    _ERC3525_clear_unit_approvals(tokenId);
    TokenCounter.burnIncrement();
    SlotSupplyHandler.decreaseSupply(slot, Uint256(1, 0));
    ERC721S_scalarBurn(tokenId, FALSE);
    return ();
}

// @audit-check approve
func ERC3525_approve{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(to: felt, tokenId: Uint256, units: Uint256) {
    alloc_locals;
    // --------------------------- 1. do relevant checks -------------------------- #
    // 1.1 ensure that uints are valid
    with_attr error_message("ERC3525: tokenId or units is an invalid uint") {
        uint256_check(tokenId);
        uint256_check(units);
    }

    // 1.2 ensure that caller is not a zero address
    let (local caller) = get_caller_address();
    with_attr error_message("ERC3525: caller cannot be zero address") {
        assert_not_zero(caller);
    }

    // 1.3 ensure that caller does not equal to to address
    // ownerOf checks if token exists
    with_attr error_message("ERC3525: to address cannot be caller") {
        assert_not_equal(caller, to);
    }

    // 1.4 ensure that owner is not to address
    let (local owner) = ERC721S_ownerOf(tokenId);
    with_attr error_message("ERC3525: to address cannot be owner") {
        assert_not_equal(owner, to);
    }

    // 1.5 ensure that caller is owner of token or approved for all
    with_attr error_message("ERC3525: caller is not approved for all or not owner of token") {
        let (is_approved) = _ERC3525_is_owner_or_approvedForAll(owner, caller);
        assert is_approved = TRUE;
    }

    // ----------------------------- 2. approve units ----------------------------- #
    _ERC3525_approve(owner, to, tokenId, units);
    return ();
}

// @audit split
func ERC3525_split{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256, _units_arr_len: felt, _units_arr: Uint256*) -> (ids_len: felt, ids: Uint256*) {
    alloc_locals;
    // ------------------------ step 1: do relevant checks ------------------------ #
    // 1.1 ensure that array length is not 0
    with_attr error_message("ERC3525: array length has to be bigger than zero") {
        assert_not_zero(_units_arr_len);
    }

    // 1.2 ensure that caller address is not zero address
    let (local caller) = get_caller_address();
    with_attr error_message("ERC3525: caller cannot be zero address") {
        assert_not_zero(caller);
    }

    // 1.3 ensure that caller is either approved for all or owner of token
    let (local owner) = ERC721S_ownerOf(tokenId);
    with_attr error_message("ERC3525: caller is not approved for all or not owner of token") {
        let (is_approved) = _ERC3525_is_owner_or_approvedForAll(owner, caller);
        assert is_approved = TRUE;
    }

    // 1.4 ensure that token units > 0
    let (local sAsset: ScalarAsset) = ERC721S_getTokenAsset(tokenId);
    with_attr error_message("ERC3525: token has zero units") {
        let (has_units) = uint256_lt(Uint256(0, 0), sAsset.units);
        assert has_units = TRUE;
    }

    // 1.5 ensure that token units >= sum of units in array
    // _ERC3525_get_unit_arr_sum also ensures that all units in array are bigger than 0
    let (local total_sum: Uint256) = _ERC3525_get_unit_arr_sum(_units_arr_len, _units_arr);
    with_attr error_message("ERC3525: token does not have enough units") {
        let (has_sum) = uint256_le(total_sum, sAsset.units);
        assert has_sum = TRUE;
    }

    // 1.6 ensure that total unit sum > 0
    with_attr error_message("ERC3525: total units cannot be zero") {
        let (has_units) = uint256_lt(Uint256(0, 0), total_sum);
        assert has_units = TRUE;
    }

    // ---------------------- step 2: reduce units on tokenId --------------------- #
    let (local split_sAsset: ScalarAsset) = ScalarHandler.unit_sub(sAsset, total_sum);
    ERC721S_changeTokenAsset(tokenId, split_sAsset);

    // ------------------------ step 3: scalar mint tokens ------------------------ #
    let (max_token: Uint256) = TokenCounter.current();
    let (local next_token: Uint256) = SafeUint256.add(max_token, Uint256(1, 0));

    local qty: Uint256 = Uint256(_units_arr_len, 0);
    let (local token_slot: Uint256) = ERC3525_slotOf(tokenId);

    ERC3525_mint(owner, qty, token_slot, Uint256(0, 0));

    // ------------ step 4: create new token array and emit split event ----------- #
    let (local token_ids_arr: Uint256*) = alloc();
    _split_loop(
        units_arr_len=_units_arr_len,
        units_arr=_units_arr,
        id_arr=token_ids_arr,
        tokenId_idx=next_token,
        tokenId=tokenId,
        owner=owner,
    );
    return (ids_len=qty.low, ids=token_ids_arr);
}

// @audit merge
func ERC3525_Merge{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenIds_len: felt, tokenIds: Uint256*, targetTokenId: Uint256) {
    alloc_locals;
    // ------------------------ step 1: do relevant checks ------------------------ #
    // 1.1 ensure that array length is not 0
    with_attr error_message("ERC3525: array length has to be bigger than zero") {
        assert_not_zero(tokenIds_len);
    }

    // 1.2 ensure that tokenIds_len does not exceed 128 bits
    with_attr error_message("ERC3525: array length cannot exceed 128 bits") {
        assert_nn_le(tokenIds_len, 2 ** 128 - 1);
    }
    // 1.3 ensure that caller address is not zero address
    let (local caller) = get_caller_address();
    with_attr error_message("ERC3525: caller cannot be zero address") {
        assert_not_zero(caller);
    }

    // 1.4 ensure that caller is either approved for all or owner of token
    let (local owner) = ERC721S_ownerOf(targetTokenId);
    with_attr error_message("ERC3525: caller is not approved for all or not owner of token") {
        let (is_approved) = _ERC3525_is_owner_or_approvedForAll(owner, caller);
        assert is_approved = TRUE;
    }

    // 1.5 ensure that array length is < owner balance
    let (local owner_bal: Uint256) = ERC721S_balanceOf(owner);
    tempvar tokens_to_merge: Uint256 = Uint256(tokenIds_len, 0);
    with_attr error_message("ERC3525: owner does not have that many tokens to merge") {
        let (has_tokens) = uint256_lt(tokens_to_merge, owner_bal);
        assert has_tokens = TRUE;
    }

    // 1.6 ensure that array length < slotBalance
    let (local slot: Uint256) = ERC3525_slotOf(targetTokenId);
    let (local slot_supply: Uint256) = SlotSupplyHandler.supply(slot);
    with_attr error_message("ERC3525: slot does not have that many tokens to merge") {
        let (has_supply) = uint256_lt(tokens_to_merge, slot_supply);
        assert has_supply = TRUE;
    }

    // ----------------- step 2: start merging and burning tokens ----------------- #
    // 2.1 _merge_loop ensure that tokenIds in array
    // is not the same as target tokenId
    // is same slot as target tokenId have and have same owner
    let (local sum_units: Uint256) = _merge_loop(
        tokenIds_len, tokenIds, targetTokenId, slot, owner
    );

    // declare after merge_loop as sAsset data will change
    let (local sAsset: ScalarAsset) = ERC721S_getTokenAsset(targetTokenId);
    // ----------------------- step 3: increase burn counter ---------------------- #
    TokenCounter.burnIncrementBy(tokens_to_merge);
    // ------------------- step 4: decrease owner token balance ------------------- #
    let (new_owner_bal: Uint256) = SafeUint256.sub_lt(owner_bal, tokens_to_merge);
    ERC721S_changeOwnerBalance(owner, new_owner_bal);
    // ----------------------- step 5: decrease slot balance ---------------------- #
    SlotSupplyHandler.decreaseSupply(slot, tokens_to_merge);
    // ------------------- step 6: change units of targetTokenId ------------------ #
    let (new_sAsset: ScalarAsset) = ScalarHandler.unit_add(sAsset, sum_units);
    ERC721S_changeTokenAsset(targetTokenId, new_sAsset);
    return ();
}

func ERC3525_safeTransferFrom{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(
    from_: felt,
    to: felt,
    tokenId: Uint256,
    targetTokenId: Uint256,
    _units: Uint256,
    data_len: felt,
    data: felt*,
) {
    alloc_locals;
    ERC3525_transferFrom(from_, to, tokenId, targetTokenId, _units);
    _ERC3525_do_safe_transfer_acceptance_check(from_, to, tokenId, _units, data_len, data);
    return ();
}

// @audit transferFrom
func ERC3525_transferFrom{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(from_: felt, to: felt, tokenId: Uint256, targetTokenId: Uint256, _units: Uint256) {
    alloc_locals;
    // ------------------------ step 1: do relevant checks ------------------------ #
    // 1.1 ensure that from and to addres is not zero address
    with_attr error_message("ERC3525: either from or to address is zero") {
        assert_not_zero(from_ * to);
    }

    // 1.2 ensure that _units is valid
    with_attr error_message("ERC3525: units is not a valid uint") {
        uint256_check(_units);
        let (is_valid) = uint256_lt(Uint256(0, 0), _units);
        assert is_valid = TRUE;
    }

    // 1.3 ensure that caller is not zero address
    let (local caller) = get_caller_address();
    with_attr error_message("ERC3525: caller cannot be zero address") {
        assert_not_zero(caller);
    }

    // 1.4 ensure that targettokenId is not tokenId
    with_attr error_message("ERC3525: targetTokenId cannot be tokenId") {
        let (is_same) = uint256_eq(targetTokenId, tokenId);
        assert is_same = FALSE;
    }

    // 1.5 ensure correct owners
    let (local owner) = ERC721S_ownerOf(tokenId);
    let (local targetOwner) = ERC721S_ownerOf(targetTokenId);
    with_attr error_message("ERC3525: either from or to address does not own tokens") {
        assert owner = from_;
        assert targetOwner = to;
    }

    // 1.6 ensure that tokenId has enough units to transfer
    let (local sAsset: ScalarAsset) = ERC721S_getTokenAsset(tokenId);
    with_attr error_message("ERC3525: token does not have enough units to transfer") {
        let (has_enough) = uint256_le(_units, sAsset.units);
        assert has_enough = TRUE;
    }

    // 1.7 ensure that targetTokenId is the same slot as tokenId
    let (local slot: Uint256) = ERC3525_slotOf(tokenId);
    let (local targetSlot: Uint256) = ERC3525_slotOf(targetTokenId);
    with_attr error_message("ERC3525: tokens are not in the same slot") {
        let (is_same_slot) = uint256_eq(slot, targetSlot);
        assert is_same_slot = TRUE;
    }

    // 1.8 ensure that caller is either owner or approved
    let (local can_transfer) = _ERC3525_is_owner_or_approvedForAll(owner, caller);
    let (local allowed_units: Uint256) = ERC3525_allowance(tokenId, caller);
    if (can_transfer == FALSE) {
        // 1.8.1 if caller is neither owner nor approved for all
        // check if units exceed caller unit level approval
        with_attr error_message("ERC3525: units to transfer exceeds ammount approved") {
            let (has_approved_units) = uint256_le(_units, allowed_units);
            assert has_approved_units = TRUE;
        }

        // 1.8.2 reduce operators approved units
        let (new_approvedUnits: Uint256) = SafeUint256.sub_le(allowed_units, _units);
        _ERC3525_approve(owner, caller, tokenId, new_approvedUnits);

        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar bitwise_ptr = bitwise_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar bitwise_ptr = bitwise_ptr;
    }

    local bitwise_ptr: BitwiseBuiltin* = bitwise_ptr;
    // ----------------------- step 2: change tokenId units ----------------------- #
    let (new_sAsset) = ScalarHandler.unit_sub(sAsset, _units);
    ERC721S_changeTokenAsset(tokenId, new_sAsset);

    // -------------------- step 3: change targetTokenId units -------------------- #
    let (local targetAsset: ScalarAsset) = ERC721S_getTokenAsset(targetTokenId);
    let (new_sAsset) = ScalarHandler.unit_add(targetAsset, _units);
    ERC721S_changeTokenAsset(targetTokenId, new_sAsset);

    // ---------------------------- step 4: emit event ---------------------------- #
    TransferUnits.emit(from_, to, tokenId, targetTokenId, _units);
    return ();
}

// should only be used adter a regular 721S token transfer
func ERC3525_clearUnitApprovals{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256) {
    _ERC3525_clear_unit_approvals(tokenId);
    return ();
}

// ---------------------------------------------------------------------------- #
//                        internals (not to be exported)                        #
// ---------------------------------------------------------------------------- #
// @audit _token_of_slot_loop
func _token_of_slot_index_loop{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(slot: Uint256, index: Uint256, tokenId_idx: Uint256, max_id: Uint256) -> (tokenId: Uint256) {
    alloc_locals;
    // ---------------------------------- step 1 ---------------------------------- #
    // saftey check to ensure that tokenId is not out of bounds
    // ensure that tokenId_idx <= max_id
    with_attr error_message("ERC3525: failed to get token of slot by index") {
        let (has_not_exceed) = uint256_le(tokenId_idx, max_id);
        assert has_not_exceed = TRUE;
    }
    // ---------------------------------- step 2 ---------------------------------- #
    let (local sAsset: ScalarAsset) = ERC721S_getTokenAsset(tokenId_idx);
    let (local slot_id, local slot_seq) = ScalarHandler.get_scalar_slot(sAsset);
    // check if current tokenId is at the start of a slot batch
    local start_of_batch = is_not_zero(slot_id);
    // check if current tokenId slot = slot
    let (local is_slot) = uint256_eq(Uint256(slot_id, 0), slot);
    // check if current token is burnt
    let (local not_burnt) = ScalarHandler.check_is_valid(sAsset);
    // check if tokenId is on a different slot batch
    // start_of_batch == TRUE and is_slot == FALSE
    let (local diff_slot) = true_and_false(start_of_batch, is_slot);
    // ---------------------------------- step 3 ---------------------------------- #
    // if not_burnt ==TRUE && diff_slot == FALSE && index == 0
    // return tokenId
    let (is_idx_0) = uint256_eq(index, Uint256(0, 0));
    let (local is_valid) = true_and_false(not_burnt, diff_slot);
    if (is_valid + is_idx_0 == 2) {
        return (tokenId_idx,);
    }
    // ---------------------------------- step 4 ---------------------------------- #
    // increment tokenId_idx by 1 + (slot_seq * diff_slot)
    // decrease index by is_valid
    tempvar jmp_token = slot_seq * diff_slot;
    let (new_tokenId_idx: Uint256) = SafeUint256.add(tokenId_idx, Uint256(1 + jmp_token, 0));
    let (new_index: Uint256) = SafeUint256.sub_le(index, Uint256(is_valid, 0));
    let (token_Id: Uint256) = _token_of_slot_index_loop(
        slot=slot, index=new_index, tokenId_idx=new_tokenId_idx, max_id=max_id
    );
    return (token_Id,);
}

// @audit _slot_of
func _slot_of{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256) -> (slot: Uint256, f_tokenId: Uint256) {
    alloc_locals;
    // ------------------ 1. check if scalar asset stores a slot ------------------ #
    // if so return slotId
    let (local sAsset: ScalarAsset) = ERC721S_getTokenAsset(tokenId);
    let has_slot = is_not_zero(sAsset.slot);
    if (has_slot == TRUE) {
        let (slotId) = ScalarHandler.get_slot_id(sAsset);
        return (Uint256(slotId, 0), tokenId);
    }
    // ------------- 1. if no slot if found start iterating backwards ------------- #
    let (slot, f_tokenId) = _slot_of_loop(tokenId);
    return (slot, f_tokenId);
}

// @audit _slotOf_loop
func _slot_of_loop{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256) -> (slotId: Uint256, f_tokenid: Uint256) {
    alloc_locals;

    // ------------------------- 1. check if tokenId <= 1 ------------------------- #
    // revert for safety purposes means theres an error some where
    with_attr error_message("ERC3525: failed to get slot of ") {
        let (not_in_range) = uint256_le(tokenId, Uint256(1, 0));
        assert not_in_range = FALSE;
    }

    // ------------------------ 2. decrease tokenId by 1 ------------------------ //
    let (local new_tokenId: Uint256) = SafeUint256.sub_lt(tokenId, Uint256(1, 0));
    // ------------------------ 3. check if asset has slot ------------------------ #
    let (local temp_sAsset: ScalarAsset) = ERC721S_getTokenAsset(new_tokenId);
    let slot_exist = is_not_zero(temp_sAsset.slot);
    if (slot_exist == TRUE) {
        let (slotId, slot_seq) = ScalarHandler.get_scalar_slot(temp_sAsset);
        return (Uint256(slotId, 0), new_tokenId);
    }

    // ----------------- 4. if all fails got to the next iteration ---------------- #
    return _slot_of_loop(tokenId=new_tokenId);
}

// @audit _find_unit_approve
// finds which index _operator is on in units_approval array
// returns 0 if operator is not found
func _find_unit_approve_index{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    tokenId: Uint256, _approve_len: felt, _operator: felt
) -> (index: felt) {
    // 1. if operator is not in array return 0
    if (_approve_len == 0) {
        return (0,);
    }
    // 2. if operator is in array return its index
    let (unit_approved: UnitApprovedOperator) = ERC3525_units_approval.read(tokenId, _approve_len);
    if (unit_approved.operator == _operator) {
        return (_approve_len,);
    }
    let (index) = _find_unit_approve_index(
        tokenId=tokenId, _approve_len=_approve_len - 1, _operator=_operator
    );
    return (index,);
}

// @audit _approve
func _ERC3525_approve{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(owner: felt, to: felt, tokenId: Uint256, units: Uint256) {
    alloc_locals;
    // ------------------- 1. check if tokenId has any operators ------------------ #
    // if not set operator and units to index 1
    let (local approve_len) = ERC3525_units_approval_len.read(tokenId);
    if (approve_len == 0) {
        ERC3525_units_approval_len.write(tokenId=tokenId, value=1);
        ERC3525_units_approval.write(
            tokenId=tokenId, index=1, value=UnitApprovedOperator(units=units, operator=to)
        );
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        // ----------- 3. check to see if to address is already an operator ----------- #
        let (local idx) = _find_unit_approve_index(
            tokenId=tokenId, _approve_len=approve_len, _operator=to
        );
        if (idx == 0) {
            tempvar new_index = approve_len + 1;
            ERC3525_units_approval_len.write(tokenId=tokenId, value=new_index);
            ERC3525_units_approval.write(
                tokenId=tokenId,
                index=new_index,
                value=UnitApprovedOperator(units=units, operator=to),
            );
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        } else {
            // --------- 4. if index returned is > 0 means operator already exist --------- #
            ERC3525_units_approval.write(
                tokenId=tokenId, index=idx, value=UnitApprovedOperator(units=units, operator=to)
            );
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        }
    }
    ApprovalUnits.emit(owner=owner, approved=to, tokenId=tokenId, approvalUnits=units);
    return ();
}

// @audit clear-unit_approvals
func _ERC3525_clear_unit_approvals{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256) {
    alloc_locals;
    let (local opr_len) = ERC3525_units_approval_len.read(tokenId);
    if (opr_len == 0) {
        return ();
    }
    let (local owner) = ERC721S_ownerOf(tokenId);
    _clear_unit_approval_loop(tokenId, opr_len, owner);
    ERC3525_units_approval_len.write(tokenId, 0);
    return ();
}

func _clear_unit_approval_loop{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    tokenId: Uint256, _approve_len: felt, owner: felt
) {
    alloc_locals;
    if (_approve_len == 0) {
        return ();
    }
    let (local unit_approval: UnitApprovedOperator) = ERC3525_units_approval.read(
        tokenId, _approve_len
    );
    ERC3525_units_approval.write(
        tokenId, _approve_len, UnitApprovedOperator(units=Uint256(0, 0), operator=0)
    );
    ApprovalUnits.emit(owner, unit_approval.operator, tokenId, Uint256(0, 0));
    _clear_unit_approval_loop(tokenId=tokenId, _approve_len=_approve_len - 1, owner=owner);
    return ();
}

func _ERC3525_get_unit_arr_sum{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    _units_arr_len: felt, _units_arr: Uint256*
) -> (sum_units: Uint256) {
    alloc_locals;
    if (_units_arr_len == 0) {
        return (Uint256(0, 0),);
    }
    let (cur_sum: Uint256) = _ERC3525_get_unit_arr_sum(
        _units_arr_len=_units_arr_len - 1, _units_arr=_units_arr + Uint256.SIZE
    );
    // ensure that uint is bigger than zero
    with_attr error_message("ERC3525: units in array cannot be zero") {
        let (valid_unit) = uint256_lt(Uint256(0, 0), [_units_arr]);
        assert valid_unit = TRUE;
    }
    // safe math automatically checks if uint is valid
    let (sum_units: Uint256) = SafeUint256.add([_units_arr], cur_sum);
    return (sum_units,);
}

// @audit _split_loop
func _split_loop{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    units_arr_len: felt,
    units_arr: Uint256*,
    id_arr: Uint256*,
    tokenId_idx: Uint256,
    tokenId: Uint256,
    owner: felt,
) {
    if (units_arr_len == 0) {
        return ();
    }
    // ------------------ 1. change units on current token asset ------------------ #
    // 1.1 check if units > 1
    // if so skip changing asset as the token by default
    // represents 1 unit
    let (not_single_unit) = uint256_lt(Uint256(1, 0), [units_arr]);
    if (not_single_unit == TRUE) {
        let (subed_unit: Uint256) = SafeUint256.sub_le([units_arr], Uint256(1, 0));
        let (cur_sAsset: ScalarAsset) = ERC721S_getTokenAsset(tokenId_idx);
        let temp_sAsset: ScalarAsset = ScalarAsset(
            owner=cur_sAsset.owner, slot=cur_sAsset.slot, units=subed_unit, data=cur_sAsset.data
        );
        ERC721S_changeTokenAsset(tokenId_idx, temp_sAsset);

        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }
    // ------------------ 2. add current token id to array ------------------------- #
    assert [id_arr] = tokenId_idx;

    // ------------------ 3. emit split event -------------------------------------- #
    Split.emit(owner, tokenId, tokenId_idx, [units_arr]);

    // ------------------ 4. increase tokenId_idx ---------------------------------- #
    let (new_tokenId_idx: Uint256) = SafeUint256.add(tokenId_idx, Uint256(1, 0));
    _split_loop(
        units_arr_len=units_arr_len - 1,
        units_arr=units_arr + Uint256.SIZE,
        id_arr=id_arr + Uint256.SIZE,
        tokenId_idx=new_tokenId_idx,
        tokenId=tokenId,
        owner=owner,
    );
    return ();
}

// @audit merge_loop
func _merge_loop{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(
    tokenIds_len: felt,
    tokenIds: Uint256*,
    targetTokenId: Uint256,
    targetSlot: Uint256,
    targetOwner: felt,
) -> (sum_units: Uint256) {
    alloc_locals;
    if (tokenIds_len == 0) {
        return (Uint256(0, 0),);
    }
    let (cur_sum: Uint256) = _merge_loop(
        tokenIds_len=tokenIds_len - 1,
        tokenIds=tokenIds + Uint256.SIZE,
        targetTokenId=targetTokenId,
        targetSlot=targetSlot,
        targetOwner=targetOwner,
    );

    // ------------------------ step 1: do relevant checks ------------------------ #
    // 1.1 ensure that tokenId is not targetTokenId
    with_attr error_message("ERC3525: tokenIds in array cannot be targetTokenId") {
        let (is_equal) = uint256_eq([tokenIds], targetTokenId);
        assert is_equal = FALSE;
    }
    // 1.2 ensure that target owner is the same as current owner
    let (cur_owner) = ERC721S_ownerOf([tokenIds]);
    with_attr error_message("ERC3525: owner of target token has to be the same as tokenId") {
        assert cur_owner = targetOwner;
    }

    // 1.3 ensures that tokenId is in the same slot as targetTokenId
    let (cur_slot: Uint256) = ERC3525_slotOf([tokenIds]);
    with_attr error_message("ERC3525: only can merge tokens of the same slot") {
        let (same_slot) = uint256_eq(cur_slot, targetSlot);
        assert same_slot = TRUE;
    }

    // 1.4 ensure that current asset is not parent of any token
    let (cur_sAsset: ScalarAsset) = ERC721S_getTokenAsset([tokenIds]);
    with_attr error_message("ERC3525: tokenId cant be merged as it is Parent") {
        let (is_parent) = ScalarHandler.check_is_parent(cur_sAsset);
        assert is_parent = FALSE;
    }
    // ----------------------- step 2: clear unit approvals ----------------------- #
    _ERC3525_clear_unit_approvals([tokenIds]);

    // -------- step 3: get new unit sum, burn tokens and emit megre event -------- #
    // safe math automatically checks if uint is valid
    let (cur_units: Uint256) = SafeUint256.add(cur_sAsset.units, Uint256(1, 0));
    let (sum_units: Uint256) = SafeUint256.add(cur_units, cur_sum);

    ERC721S_scalarBurn([tokenIds], TRUE);
    Merge.emit(targetOwner, [tokenIds], targetTokenId, cur_units);
    return (sum_units,);
}

// @audit is_owner_or_approved
func _ERC3525_is_owner_or_approvedForAll{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(_owner: felt, _caller: felt) -> (res: felt) {
    if (_owner == _caller) {
        return (TRUE,);
    }
    let (is_approved) = ERC721S_isApprovedForAll(_owner, _caller);
    return (is_approved,);
}

// @audit acceptance check
func _ERC3525_do_safe_transfer_acceptance_check{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(from_: felt, to: felt, tokenId: Uint256, _units: Uint256, data_len: felt, data: felt*) {
    let (success) = _check_onERC3525Received(from_, to, tokenId, _units, data_len, data);
    with_attr error_message("ERC3525: transfer to non ERC3525 implementer") {
        assert_not_zero(success);
    }
    return ();
}

// @audit acceptance loop
func _ERC3525_do_safe_transfer_acceptance_check_loop{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(
    from_: felt,
    to: felt,
    tokenId: Uint256,
    _units: Uint256,
    index: felt,
    data_len: felt,
    data: felt*,
) {
    alloc_locals;
    if (index == 0) {
        return ();
    }
    _ERC3525_do_safe_transfer_acceptance_check(from_, to, tokenId, _units, data_len, data);
    let (temp_id) = SafeUint256.add(tokenId, Uint256(1, 0));
    let new_index = index - 1;

    _ERC3525_do_safe_transfer_acceptance_check_loop(
        from_=from_,
        to=to,
        tokenId=temp_id,
        _units=_units,
        index=new_index,
        data_len=data_len,
        data=data,
    );
    return ();
}

// @audit-check onRecieved
func _check_onERC3525Received{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    from_: felt, to: felt, tokenId: Uint256, units: Uint256, data_len: felt, data: felt*
) -> (success: felt) {
    let (caller) = get_caller_address();
    let (is_supported) = IERC165.supportsInterface(to, IERC3525_RECEIVER_ID);
    if (is_supported == TRUE) {
        let (selector) = IERC3525_Receiver.onERC3525Received(
            to, caller, from_, tokenId, units, data_len, data
        );

        with_attr error_message("ERC3525: transfer to non ERC3525Receiver implementer") {
            assert selector = IERC3525_RECEIVER_ID;
        }
        return (TRUE,);
    }

    let (is_account) = IERC165.supportsInterface(to, IACCOUNT_ID);
    if (is_account == FALSE) {
        let (is_old_account) = IERC165.supportsInterface(to, OLD_ACCOUNT_ID);
        return (is_old_account,);
    }
    return (is_account,);
}
