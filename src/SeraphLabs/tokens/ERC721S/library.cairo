// ---------------------------------------------------------------------------- #
//                slightly edited version of openzeppelin erc721                #
//                          to allow for batch minting                          #
//                  and more gas efficient mints and transfers                  #
// ---------------------------------------------------------------------------- #

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

from openzeppelin.token.erc721.IERC721Receiver import IERC721Receiver

from openzeppelin.introspection.ERC165.IERC165 import IERC165

// ---------------------------------- my libs --------------------------------- #
from SeraphLabs.utils.constants import (
    IERC721_ID,
    IERC721_RECEIVER_ID,
    IERC721_ENUMERABLE_ID,
    IACCOUNT_ID,
    OLD_ACCOUNT_ID,
)

from SeraphLabs.tokens.libs.scalarHandler import ScalarHandler, ScalarAsset, MAX_sequence, MAX_slot

from SeraphLabs.tokens.libs.tokenCounter import TokenCounter

from SeraphLabs.math.logicalOpr import LogicalOpr

from SeraphLabs.tokens.ERC721S.utils.ERC721S_OwnerEnumerable import OwnerEnum721S
// ---------------------------------------------------------------------------- #
//                                    Events                                    #
// ---------------------------------------------------------------------------- #

@event
func Transfer(from_: felt, to: felt, tokenId: Uint256) {
}

@event
func Approval(owner: felt, approved: felt, tokenId: Uint256) {
}

@event
func ApprovalForAll(owner: felt, operator: felt, approved: felt) {
}

// ---------------------------------------------------------------------------- #
//                                    storage                                   #
// ---------------------------------------------------------------------------- #

@storage_var
func ERC721S_name_() -> (name: felt) {
}

@storage_var
func ERC721S_symbol_() -> (symbol: felt) {
}

@storage_var
func ERC721S_tokenAsset(tokenId: Uint256) -> (sAsset: ScalarAsset) {
}

@storage_var
func ERC721S_balances(account: felt) -> (balance: Uint256) {
}

@storage_var
func ERC721S_token_approvals(tokenId: Uint256) -> (res: felt) {
}

@storage_var
func ERC721S_operator_approvals(owner: felt, operator: felt) -> (res: felt) {
}

// ---------------------------------------------------------------------------- #
//                                  Constructor                                 #
// ---------------------------------------------------------------------------- #

func ERC721S_initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    name: felt, symbol: felt
) {
    ERC721S_name_.write(name);
    ERC721S_symbol_.write(symbol);
    ERC165.register_interface(IERC721_ID);
    ERC165.register_interface(IERC721_ENUMERABLE_ID);
    return ();
}

// ---------------------------------------------------------------------------- #
//                                    Getters                                   #
// ---------------------------------------------------------------------------- #

func ERC721S_name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    name: felt
) {
    let (name) = ERC721S_name_.read();
    return (name,);
}

func ERC721S_symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    symbol: felt
) {
    let (symbol) = ERC721S_symbol_.read();
    return (symbol,);
}

func ERC721S_total_supply{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() -> (
    supply: Uint256
) {
    alloc_locals;
    let (burn_count: Uint256) = TokenCounter.currentBurnt();
    let (cur_index: Uint256) = TokenCounter.current();
    let (has_burn) = uint256_le(Uint256(1, 0), burn_count);
    if (has_burn == FALSE) {
        return (cur_index,);
    }
    let (calc_supply: Uint256) = SafeUint256.sub_le(cur_index, burn_count);
    return (calc_supply,);
}

func ERC721S_balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt
) -> (balance: Uint256) {
    with_attr error_message("ERC721S: balance query for the zero address") {
        assert_not_zero(owner);
    }
    let (balance: Uint256) = ERC721S_balances.read(owner);
    return (balance,);
}

// @audit-check ownerOf
func ERC721S_ownerOf{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(tokenId: Uint256) -> (owner: felt) {
    alloc_locals;
    // ------------------ 1. check if tokenId is a valid Uint256 ------------------ #
    with_attr error_message("ERC721S: tokenId is not a valid Uint256") {
        uint256_check(tokenId);
    }

    // ------------------- 2. check if token exist if not revert ------------------ #
    // _ERC721S_exist automatically checks if token is_burnt
    with_attr error_message("ERC721S: tokenId does not exist yet") {
        let (is_exist) = _ERC721S_exist(tokenId);
        assert is_exist = TRUE;
    }

    let (local sAsset: ScalarAsset) = ERC721S_tokenAsset.read(tokenId);

    // ------------------- 3. check if scalar asset stores owner ------------------ #
    // if so return asset owner
    let not_zero = is_not_zero(sAsset.owner);
    if (not_zero == TRUE) {
        return (sAsset.owner,);
    }

    // ------------ 4. if not start iterationg backwards to find owner ------------ #
    // find the closest asset that stores an owner
    // checks if is burnt or next_seq val equal to zero
    // if not return owner
    let (owner, _) = _ERC721S_owner_of_loop(tokenId, 0);
    return (owner,);
}

func ERC721S_getOwnerTokens{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(owner: felt) -> (arr_len: felt, arr: Uint256*) {
    alloc_locals;
    with_attr error_message("ERC721S: owner address cannot be 0 address") {
        assert_not_zero(owner);
    }
    let (local max_id: Uint256) = TokenCounter.current();
    let (local balance: Uint256) = ERC721S_balances.read(owner);
    let (local tokenIds: Uint256*) = alloc();

    let (has_none) = uint256_le(balance, Uint256(0, 0));
    if (has_none == TRUE) {
        return (0, tokenIds);
    }
    let (starting_token: Uint256) = OwnerEnum721S.get_next_token(owner, Uint256(0, 0));
    _ERC721S_getOwnerTokensLoop(owner, Uint256(0, 0), balance, starting_token, max_id, tokenIds);
    return (balance.low, tokenIds);
}

func ERC721S_tokenOfOwnerByIndex{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(owner: felt, index: Uint256) -> (tokenId: Uint256) {
    alloc_locals;
    with_attr error_message("ERC721S: owner address cannot be 0 address") {
        assert_not_zero(owner);
    }
    // 1. check if index >= user balance
    // if so revert
    let (usr_bal: Uint256) = ERC721S_balances.read(owner);
    let (not_within_bal) = uint256_le(usr_bal, index);
    with_attr error_message("ERC721S: index is out of bounds") {
        assert not_within_bal = FALSE;
    }

    // 2. if pass start with checking tokenId 1 owner and loop down
    let (local max_id: Uint256) = TokenCounter.current();
    let (starting_token: Uint256) = OwnerEnum721S.get_next_token(owner, Uint256(0, 0));

    let (tokenId: Uint256) = _ERC721S_tokenOwnerIndexLoop(
        owner=owner, index=index, tokenId_idx=starting_token, max_id=max_id
    );
    return (tokenId,);
}

// @audit-check tokenByIndex
func ERC721S_tokenByIndex{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(index: Uint256) -> (tokenId: Uint256) {
    alloc_locals;
    with_attr error_message("ERC721S: index is not a valid uint") {
        uint256_check(index);
    }

    let (supply: Uint256) = ERC721S_total_supply();
    let (is_lesser) = uint256_lt(index, supply);
    with_attr error_message("ERC721S: index is out of bounds") {
        assert is_lesser = TRUE;
    }
    let (local max_id: Uint256) = TokenCounter.current();

    let (is_equal) = uint256_eq(supply, max_id);
    if (is_equal == TRUE) {
        let (tokenId: Uint256) = SafeUint256.add(index, Uint256(1, 0));
        return (tokenId,);
    }

    let (tokenId: Uint256) = _ERC721S_token_by_index_loop(
        index=index, tokenId_idx=Uint256(1, 0), max_id=max_id
    );
    return (tokenId,);
}

func ERC721S_getApproved{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(tokenId: Uint256) -> (approved: felt) {
    alloc_locals;
    with_attr error_message("ERC721S: tokenId is not a valid Uint256") {
        uint256_check(tokenId);
    }

    let (local exists) = _ERC721S_exist(tokenId);
    with_attr error_message("ERC721S: approved query for nonexistent token") {
        assert exists = TRUE;
    }

    let (approved) = ERC721S_token_approvals.read(tokenId);
    return (approved,);
}

func ERC721S_isApprovedForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, operator: felt
) -> (is_approved: felt) {
    let (is_approved) = ERC721S_operator_approvals.read(owner=owner, operator=operator);
    return (is_approved,);
}

func ERC721S_getTokenAsset{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    tokenId: Uint256
) -> (sAsset: ScalarAsset) {
    let (sAsset) = ERC721S_tokenAsset.read(tokenId);
    return (sAsset,);
}

func ERC721S_exist{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256) -> (res: felt) {
    let (res) = _ERC721S_exist(tokenId);
    return (res,);
}

// ---------------------------------------------------------------------------- #
//                                   externals                                  #
// ---------------------------------------------------------------------------- #

func ERC721S_approve{
    bitwise_ptr: BitwiseBuiltin*, pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr
}(to: felt, tokenId: Uint256) {
    alloc_locals;
    with_attr error_mesage("ERC721S: tokenId is not a valid Uint256") {
        uint256_check(tokenId);
    }

    // Checks caller is not zero address
    let (local caller) = get_caller_address();
    with_attr error_message("ERC721S: cannot approve from the zero address") {
        assert_not_zero(caller);
    }

    // Ensures 'owner' does not equal 'to'
    // ERC721S_ownerOf automatically checks if tokenId exist
    let (local owner) = ERC721S_ownerOf(tokenId);
    with_attr error_message("ERC721S: approval to current owner") {
        assert_not_equal(owner, to);
    }

    // Checks that either caller equals owner or
    // caller isApprovedForAll on behalf of owner
    if (caller == owner) {
        _ERC721S_approve(to, tokenId);
        return ();
    } else {
        let (is_approved) = ERC721S_operator_approvals.read(owner, caller);
        with_attr error_message("ERC721S: approve caller is not owner nor approved for all") {
            assert_not_zero(is_approved);
        }
        _ERC721S_approve(to, tokenId);
        return ();
    }
}

func ERC721S_setApprovalForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    operator: felt, approved: felt
) {
    // Ensures caller is neither zero address nor operator
    let (caller) = get_caller_address();
    with_attr error_message("ERC721S: either the caller or operator is the zero address") {
        assert_not_zero(caller * operator);
    }
    // note this pattern as we'll frequently use it:
    //   instead of making an `assert_not_zero` call for each address
    //   we can always briefly write `assert_not_zero(a0 * a1 * ... * aN)`.
    //   This is because these addresses are field elements,
    //   meaning that a*0==0 for all a in the field,
    //   and a*b==0 implies that at least one of a,b are zero in the field
    with_attr error_message("ERC721S: approve to caller") {
        assert_not_equal(caller, operator);
    }

    // Make sure `approved` is a boolean (0 or 1)
    with_attr error_message("ERC721S: approved is not a Cairo boolean") {
        assert approved * (1 - approved) = 0;
    }

    ERC721S_operator_approvals.write(owner=caller, operator=operator, value=approved);
    ApprovalForAll.emit(caller, operator, approved);
    return ();
}

func ERC721S_transferFrom{
    bitwise_ptr: BitwiseBuiltin*, pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr
}(from_: felt, to: felt, tokenId: Uint256) {
    alloc_locals;
    with_attr error_message("ERC721S: tokenId is not a valid Uint256") {
        uint256_check(tokenId);
    }
    let (caller) = get_caller_address();
    let (is_approved) = _ERC721S_is_approved_or_owner(caller, tokenId);
    with_attr error_message("ERC721S: either is not approved or the caller is the zero address") {
        assert_not_zero(caller * is_approved);
    }
    // Note that if either `is_approved` or `caller` equals `0`,
    // then this method should fail.
    // The `caller` address and `is_approved` boolean are both field elements
    // meaning that a*0==0 for all a in the field,
    // therefore a*b==0 implies that at least one of a,b is zero in the field

    _ERC721S_transfer(from_, to, tokenId);
    return ();
}

func ERC721S_safeTransferFrom{
    bitwise_ptr: BitwiseBuiltin*, pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr
}(from_: felt, to: felt, tokenId: Uint256, data_len: felt, data: felt*) {
    alloc_locals;
    with_attr error_message("ERC721S: tokenId is not a valid Uint256") {
        uint256_check(tokenId);
    }
    let (caller) = get_caller_address();
    let (is_approved) = _ERC721S_is_approved_or_owner(caller, tokenId);
    with_attr error_message("ERC721S: either is not approved or the caller is the zero address") {
        assert_not_zero(caller * is_approved);
    }
    // Note that if either `is_approved` or `caller` equals `0`,
    // then this method should fail.
    // The `caller` address and `is_approved` boolean are both field elements
    // meaning that a*0==0 for all a in the field,
    // therefore a*b==0 implies that at least one of a,b is zero in the field

    _ERC721S_safe_transfer(from_, to, tokenId, data_len, data);
    return ();
}

func ERC721S_mint{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(to: felt, _quantity: Uint256) {
    ERC721S_scalarMint(to, _quantity, Uint256(0, 0), Uint256(0, 0));
    return ();
}

// @audit-check mint
func ERC721S_scalarMint{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(to: felt, _quantity: Uint256, _slotId: Uint256, _units: Uint256) {
    alloc_locals;
    // --------------------------- 1. do relevant checks -------------------------- #
    with_attr error_message("ERC721S: _quantity is not a valid Uint256") {
        uint256_check(_quantity);
        let (is_valid_uint) = uint256_lt(Uint256(0, 0), _quantity);
        assert is_valid_uint = TRUE;
    }

    with_attr error_message("ERC721S: quantity cannot exceed Uint256(2**120,0)") {
        assert_nn_le(_quantity.low, MAX_sequence);
        assert _quantity.high = 0;
    }

    with_attr error_message("ERC721S: units is not valid") {
        uint256_check(_units);
    }

    with_attr error_message("ERC721S: slotId cannot exceed 2**128 - 1") {
        assert_nn_le(_slotId.low, MAX_slot);
        assert _slotId.high = 0;
    }

    with_attr error_message("ERC721S: cannot mint to the zero address") {
        assert_not_zero(to);
    }

    // ------------------- 2. increase token Counter by quantity ------------------- #
    let (local cur_tokenId: Uint256) = TokenCounter.current();
    let (local new_tokenId: Uint256) = SafeUint256.add(cur_tokenId, Uint256(1, 0));
    TokenCounter.incrementBy(_quantity);
    // ---------------------- check if can add to next seq ---------------------- //
    let (add_tokenId, add_sAsset) = _check_can_add_to_seq(cur_tokenId, to, _quantity.low);
    let (local cant_add) = uint256_le(add_tokenId, Uint256(0, 0));

    if (cant_add == FALSE) {
        ERC721S_tokenAsset.write(add_tokenId, add_sAsset);

        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar bitwise_ptr = bitwise_ptr;
    } else {
        OwnerEnum721S.add_to_enumeration(to, new_tokenId);
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar bitwise_ptr = bitwise_ptr;
    }
    tempvar syscall_ptr = syscall_ptr;
    tempvar pedersen_ptr = pedersen_ptr;
    tempvar bitwise_ptr = bitwise_ptr;

    // ------------------- 3. change tokenId asset owner -------------------------- #
    local new_sAsset: ScalarAsset = ScalarAsset(owner=to * cant_add, slot=_slotId.low, units=_units, data=0);

    // ------------------- 4. change owner balance -------------------------------- #
    let (curr_bal) = ERC721S_balances.read(to);
    let (new_balance: Uint256) = SafeUint256.add(curr_bal, _quantity);
    ERC721S_balances.write(to, new_balance);
    // -----------------  5. check if quantity is only 1 -------------------------- #
    // if so emit event once and write asset to tokenId
    let (is_qty_one) = uint256_eq(_quantity, Uint256(1, 0));
    if (is_qty_one == TRUE) {
        ERC721S_tokenAsset.write(new_tokenId, new_sAsset);
        Transfer.emit(0, to, new_tokenId);
        return ();
    }
    // ------------------ 6. update tokenId next_seq ------------------------------ #
    // and recursively emit all newly minted tokenId transfer event
    tempvar asset_seq = _quantity.low - 1;
    let (local batched_sAsset: ScalarAsset) = ScalarHandler.add_next_seq(
        new_sAsset, asset_seq * cant_add
    );
    // ------------------- 7. check if slotId = 0 ---------------------------------- #
    // if 0 just write to storage without slot_seq
    if (_slotId.low == 0) {
        ERC721S_tokenAsset.write(new_tokenId, batched_sAsset);
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar bitwise_ptr = bitwise_ptr;
    } else {
        let (batched_sAsset_2: ScalarAsset) = ScalarHandler.update_slot_seq(
            batched_sAsset, asset_seq
        );
        ERC721S_tokenAsset.write(new_tokenId, batched_sAsset_2);
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar bitwise_ptr = bitwise_ptr;
    }

    local bitwise_ptr: BitwiseBuiltin* = bitwise_ptr;
    _transfer_event_loop(tokenId=new_tokenId, index=_quantity.low, to=to);
    return ();
}

// @audit-check safeMint
func ERC721S_safeMint{
    bitwise_ptr: BitwiseBuiltin*, pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr
}(to: felt, _quantity: Uint256, data_len: felt, data: felt*) {
    alloc_locals;
    let (cur_id) = TokenCounter.current();
    let (local next_tokenId: Uint256) = SafeUint256.add(cur_id, Uint256(1, 0));
    ERC721S_mint(to, _quantity);
    _ERC721S_do_safe_transfer_acceptance_check_loop(
        from_=0, to=to, tokenId=next_tokenId, index=_quantity.low, data_len=data_len, data=data
    );
    return ();
}

func ERC721S_burn{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256) {
    ERC721S_scalarBurn(tokenId, FALSE);
    TokenCounter.burnIncrement();
    return ();
}

// @audit-check burn
// scalarBurn allows you to skip the step of decreasing owner balance
// used when burning batches for cheaper writes
func ERC721S_scalarBurn{
    bitwise_ptr: BitwiseBuiltin*, pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr
}(tokenId: Uint256, skip: felt) {
    alloc_locals;

    // _get_owner_and_fId checks if token exist
    let (local _owner, local f_tokenId) = _get_owner_and_fId(tokenId);
    let (local owner_bal: Uint256) = ERC721S_balances.read(_owner);
    // ------------------------- 1. decrease owner balance ------------------------ #
    // 2.1 Decrease owner balance and increment burn counter
    // only if skip is false
    if (skip == FALSE) {
        let (new_balance: Uint256) = SafeUint256.sub_le(owner_bal, Uint256(1, 0));
        ERC721S_balances.write(_owner, new_balance);

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
    // -------------------------- 2. SCENARIO 1 ------------------------- #
    // scenario 1 = if current tokenId asset is not in a batch
    // asset must have owner and next_seq >= 1
    // if so change current asset owner and validity
    let (local sAsset: ScalarAsset) = ERC721S_tokenAsset.read(tokenId);
    let (local cur_next_seq) = ScalarHandler.get_next_seq(sAsset);

    local has_owner = is_not_zero(sAsset.owner);
    local has_next_seq = is_le(1, cur_next_seq);

    if (has_owner == TRUE and has_next_seq == FALSE) {
        // 1.1 clear approvals first
        _ERC721S_approve(0, tokenId);
        // 1.1.1 change owner lowest token
        OwnerEnum721S.not_in_batch_remove(_owner, tokenId);
        // 1.2 change tokenid asset owner and validity
        let burnt_sAsset: ScalarAsset = ScalarAsset(
            owner=0, slot=sAsset.slot, units=Uint256(0, 0), data=TRUE
        );
        ERC721S_tokenAsset.write(tokenId, burnt_sAsset);

        // 1.3 emit event
        Transfer.emit(_owner, 0, tokenId);
        return ();
    }

    // -------------------------- 3. SCENARIO 2 ------------------------- #
    // scenario 2 = current tokenId asset is first one in batch
    // asset must have owner and have seq
    // essentially if tokenId being transfered is the first one in the batch
    // if so change asset owner for current Id and next Id
    tempvar scenario_2 = has_owner * has_next_seq;
    if (scenario_2 == TRUE) {
        // 3.1 safety assertion if this fails that means theres a bug in the code
        // ensures that current tokenId is  first tokenId
        with_attr error_message("ERC721S: burn scenario 2 error") {
            let (is_the_first) = uint256_eq(tokenId, f_tokenId);
            assert is_the_first = TRUE;
        }

        // 3.2 clear approvals first
        _ERC721S_approve(0, tokenId);
        // 3.2.1 change owner lowest token
        OwnerEnum721S.start_of_batch_remove(_owner, tokenId);
        // 3.3 change current tokenId asset
        // owner = 0 and set its next_seq=0 and not_valid = TRUE
        // as not_valid is the last bits in data sequnce we can just set data = TRUE
        ERC721S_tokenAsset.write(
            tokenId, ScalarAsset(owner=0, slot=sAsset.slot, units=Uint256(0, 0), data=TRUE)
        );

        // 3.4 change next tokenId asset in seq
        // owner=_owner and next_seq=next_seq - 1
        let (local next_tokenId: Uint256) = SafeUint256.add(tokenId, Uint256(1, 0));
        let (next_sAsset) = ERC721S_tokenAsset.read(next_tokenId);
        let (next_sAsset: ScalarAsset) = ScalarHandler.update_next_seq(
            next_sAsset, cur_next_seq - 1
        );
        ERC721S_tokenAsset.write(
            next_tokenId,
            ScalarAsset(owner=_owner, slot=next_sAsset.slot, units=next_sAsset.units, data=next_sAsset.data),
        );

        // 3.5 emit event
        Transfer.emit(_owner, 0, tokenId);
        return ();
    }

    // -------------------------- 4. check for scenario 3 ------------------------- #
    // scenario 3 = current sAsset is last one in batch
    // asset must have no owner and no seq

    // 4.1 safety assertion if this fails that means theres a bug in the code
    // ensures that current tokenId is not first tokenId
    with_attr error_message("ERC721S: burn scenario 3 error") {
        let (is_the_first) = uint256_eq(tokenId, f_tokenId);
        assert is_the_first = FALSE;
    }

    // 4.2 check if cur tokenId is last Id in batch
    let (local f_sAsset: ScalarAsset) = ERC721S_tokenAsset.read(f_tokenId);
    let (local f_next_seq) = ScalarHandler.get_next_seq(f_sAsset);
    let (local l_tokenId: Uint256) = SafeUint256.add(f_tokenId, Uint256(f_next_seq, 0));
    local not_in_batch = has_owner + has_next_seq;

    let (is_last_id) = uint256_eq(tokenId, l_tokenId);
    if (is_last_id == TRUE) {
        // 4.3 safety assertion if this fails that means theres a bug in the code
        // ensures that current tokenId asset has no owner and no seq
        with_attr error_message("ERC721S: burn scenario 3 error") {
            assert not_in_batch = FALSE;
        }

        // 4.4 clear approvals first
        _ERC721S_approve(0, tokenId);

        // 4.5 change last tokenId asset
        // current sAsset will equal to last sAsset
        ERC721S_tokenAsset.write(
            tokenId, ScalarAsset(owner=0, slot=sAsset.slot, units=Uint256(0, 0), data=TRUE)
        );

        // 4.6 change first tokenId next seq - 1
        let (new_f_sAsset: ScalarAsset) = ScalarHandler.sub_next_seq(f_sAsset, 1);
        ERC721S_tokenAsset.write(f_tokenId, new_f_sAsset);

        // 4.7 emit event
        Transfer.emit(_owner, 0, tokenId);
        return ();
    }

    // -------------------------- 5. check for scenario 4 ------------------------- #
    // scenario 4 = current sAsset is in the middle of a batch
    // asset must have no owner and no seq

    // 5.1 safety assertion if this fails that means theres a bug in the code
    // ensures that current tokenId asset has no owner and no seq
    with_attr error_message("ERC721S: burn scenario 4 error") {
        assert not_in_batch = FALSE;
    }

    // 5.2 clear approvals first
    _ERC721S_approve(0, tokenId);

    // 5.3 change current asset owner and validity
    ERC721S_tokenAsset.write(
        tokenId, ScalarAsset(owner=0, slot=sAsset.slot, units=Uint256(0, 0), data=TRUE)
    );

    // 5.4 change first asset next_seq
    // next_seq = (current_id - first_id) - 1
    // ? assumes that the spread of current token and first token is not bigger than 120 bits
    let (temp_f_next_seq: Uint256) = SafeUint256.sub_lt(tokenId, f_tokenId);
    let (new_f_sAsset: ScalarAsset) = ScalarHandler.update_next_seq(
        f_sAsset, temp_f_next_seq.low - 1
    );
    ERC721S_tokenAsset.write(f_tokenId, new_f_sAsset);

    // 5.5 change next token asset owner and next_seq
    // owner = _owner
    // next seq = last id - next id
    let (local next_tokenId: Uint256) = SafeUint256.add(tokenId, Uint256(1, 0));
    let (local m_next_seq: Uint256) = SafeUint256.sub_le(l_tokenId, next_tokenId);
    let (temp_sAsset: ScalarAsset) = ERC721S_tokenAsset.read(next_tokenId);
    // ? assumes that the spread of last token and next token is not bigger than 120 bits
    let (local m_sAsset: ScalarAsset) = ScalarHandler.update_next_seq(temp_sAsset, m_next_seq.low);
    ERC721S_tokenAsset.write(
        next_tokenId,
        ScalarAsset(owner=_owner, slot=m_sAsset.slot, units=m_sAsset.units, data=m_sAsset.data),
    );

    // 5.6 change owner lowest token
    OwnerEnum721S.mid_of_batch_remove(_owner, tokenId, f_tokenId);
    // 5.7 emit event
    Transfer.emit(_owner, 0, tokenId);
    return ();
}

func ERC721S_only_token_owner{
    bitwise_ptr: BitwiseBuiltin*, pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr
}(tokenId: Uint256) {
    alloc_locals;
    uint256_check(tokenId);
    let (local caller) = get_caller_address();
    // ERC721S_ownerOf automatically checks if token exist
    let (local owner) = ERC721S_ownerOf(tokenId);

    with_attr error_message("ERC721S: owner is zero address") {
        assert_not_zero(owner);
    }

    with_attr error_message("ERC721S: caller is not the token owner") {
        assert caller = owner;
    }
    return ();
}

func ERC721S_changeTokenAsset{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    tokenId: Uint256, sAsset: ScalarAsset
) {
    alloc_locals;
    with_attr error_message("ERC721S: tokenId is not a valid Uint256") {
        uint256_check(tokenId);
        let (is_valid_uint) = uint256_lt(Uint256(0, 0), tokenId);
        assert is_valid_uint = TRUE;
    }
    ERC721S_tokenAsset.write(tokenId, sAsset);
    return ();
}

func ERC721S_changeOwnerBalance{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    _owner: felt, _bal: Uint256
) {
    ERC721S_balances.write(_owner, _bal);
    return ();
}
// ---------------------------------------------------------------------------- #
//                         internals not to be exported                         #
// ---------------------------------------------------------------------------- #

func _get_owner_and_fId{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256) -> (owner: felt, f_tokenId: Uint256) {
    alloc_locals;
    // ------------------ 1. check if tokenId is a valid Uint256 ------------------ #
    with_attr error_message("ERC721S: tokenId is not a valid Uint256") {
        uint256_check(tokenId);
    }

    // ------------------- 2. check if token exist if not revert ------------------ #
    // _ERC721S_exist automatically checks if token is_burnt
    with_attr error_message("ERC721S: tokenId does not exist yet") {
        let (is_exist) = _ERC721S_exist(tokenId);
        assert is_exist = TRUE;
    }

    let (local sAsset: ScalarAsset) = ERC721S_tokenAsset.read(tokenId);

    // ------------------- 3. check if scalar asset stores owner ------------------ #
    // if so return asset owner
    let not_zero = is_not_zero(sAsset.owner);
    if (not_zero == TRUE) {
        return (sAsset.owner, tokenId);
    }

    // ------------ 4. if not start iterationg backwards to find owner ------------ #
    // find the closest asset that stores an owner
    // checks if is burnt or next_seq val equal to zero
    // if not return owner
    let (owner, f_tokenId) = _ERC721S_owner_of_loop(tokenId, 0);
    return (owner, f_tokenId);
}

// checks if can add to next seq instead of storing new owner
// checks if last tokenId owner is the same as current
// if yes will return the first tokenId in the previous seq if not will return 0
// also checks if seq exceeds 50
func _check_can_add_to_seq{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(cur_tokenId: Uint256, owner: felt, num: felt) -> (f_tokenId: Uint256, sAsset: ScalarAsset) {
    alloc_locals;
    let (is_zero) = uint256_le(cur_tokenId, Uint256(0, 0));

    let (temp_sAsset: ScalarAsset) = ERC721S_tokenAsset.read(cur_tokenId);
    let (cant_add) = LogicalOpr.OR(is_zero, temp_sAsset.data);

    if (cant_add == TRUE) {
        return (Uint256(0, 0), ScalarAsset(owner=0, slot=0, units=Uint256(0, 0), data=0));
    }

    if (temp_sAsset.owner == owner) {
        let (sAsset: ScalarAsset) = ScalarHandler.add_next_seq(temp_sAsset, num);
        return (cur_tokenId, sAsset);
    }

    let (cur_owner, f_tokenId) = _get_owner_and_fId(cur_tokenId);

    if (cur_owner != owner) {
        return (Uint256(0, 0), ScalarAsset(owner=0, slot=0, units=Uint256(0, 0), data=0));
    }

    let (local new_sAsset: ScalarAsset) = ERC721S_tokenAsset.read(f_tokenId);
    let (next_seq) = ScalarHandler.get_next_seq(new_sAsset);

    tempvar temp_seq = num + next_seq;
    tempvar in_valid_seq = is_le(50, temp_seq);
    if (in_valid_seq == FALSE) {
        let (sAsset: ScalarAsset) = ScalarHandler.add_next_seq(new_sAsset, num);
        return (f_tokenId, sAsset);
    }
    return (Uint256(0, 0), ScalarAsset(owner=0, slot=0, units=Uint256(0, 0), data=0));
}
// @audit-check ownerLoop
// f_tokenId = the tokenId at the start of the batch
func _ERC721S_owner_of_loop{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256, itr_num: felt) -> (owner: felt, f_tokenId: Uint256) {
    alloc_locals;

    // ------------------------- 1. check if tokenId <= 1 ------------------------- #
    // revert for safety purposes means theres an error some where
    with_attr error_message("ERC721S: failed to get owner of ") {
        let (not_in_range) = uint256_le(tokenId, Uint256(1, 0));
        assert not_in_range = FALSE;
    }

    // --------- 2. decrease tokenId by 1 and increase iteration num by 1 --------- #
    let (local new_tokenId: Uint256) = SafeUint256.sub_lt(tokenId, Uint256(1, 0));
    tempvar new_itr_num = itr_num + 1;

    // ----- 3. check if asset has_owner && not_burnt && next_seq > 0 if TRUE ----- #
    // 3.1. check if iteration number <= to asset next_seq
    // if not revert for safety reasons means there is an error somewhere
    // if so return current asset owner
    let (local temp_sAsset: ScalarAsset) = ERC721S_tokenAsset.read(new_tokenId);
    let (has_found) = ScalarHandler.check_has_owner_seq_not_burnt(_asset=temp_sAsset);

    if (has_found == TRUE) {
        let (cur_next_seq) = ScalarHandler.get_next_seq(temp_sAsset);
        with_attr error_message("ERC721S: failed to get owner of ") {
            let is_valid_loop = is_le(new_itr_num, cur_next_seq);
            assert is_valid_loop = TRUE;
        }
        return (temp_sAsset.owner, new_tokenId);
    }

    // ----------------- 4. if all fails go to the next iteration ----------------- #
    let (_owner, f_id) = _ERC721S_owner_of_loop(tokenId=new_tokenId, itr_num=new_itr_num);
    return (_owner, f_id);
}

// @audit-check ownerIndexloop
// index -> decrease if owner is found / tokenId_idx = current token in recursion
func _ERC721S_tokenOwnerIndexLoop{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(owner: felt, index: Uint256, tokenId_idx: Uint256, max_id: Uint256) -> (tokenId: Uint256) {
    alloc_locals;
    // ----------- 1. check if tokenId_idx is out of total supply range ----------- #
    // tokenId_idx > max tokenId
    // if so revert
    with_attr error_message("ERC721S: cant find owner token by index") {
        let (is_exceeded) = uint256_lt(max_id, tokenId_idx);
        let (is_zero) = uint256_le(tokenId_idx, Uint256(0, 0));
        assert is_zero = FALSE;
        assert is_exceeded = FALSE;
    }

    let (local sAsset: ScalarAsset) = ERC721S_tokenAsset.read(tokenId_idx);

    // --------------- 2. check  if is_owner = TRUE and if index = 0 -------------- #
    // is_owner -> checks if owner = owner and is_burnt = FALSE
    // if so return token id
    // is owner checks if token is burnt if it is returns false
    let (local is_owner) = ScalarHandler.check_is_asset_owner(sAsset, owner);
    let (local is_lastIdx) = uint256_eq(index, Uint256(0, 0));

    tempvar two_bool = is_owner + is_lastIdx;
    if (two_bool == 2) {
        return (tokenId_idx,);
    }

    // ---------------- 3. if is_owner = TRUE and index <= next_seq --------------- #
    // return tokenId = tokenId_idx + index
    let (local next_seq) = ScalarHandler.get_next_seq(sAsset);
    let (le_Seq) = uint256_le(index, Uint256(next_seq, 0));

    if (le_Seq + is_owner == 2) {
        let (new_token_id: Uint256) = SafeUint256.add(tokenId_idx, index);
        return (new_token_id,);
    }

    // ---------------- 4. if index > next_seq ---------------- #
    // 4.1 get new index base on is_owner
    // new_index = index - val_x
    // val_x = (next_seq + 1)
    tempvar val_x_1 = next_seq + 1;

    // 4.2 jump tokenId_idx based on not_burnt
    // jump token by 1 + next_seq

    let (new_tokenId_idx: Uint256) = OwnerEnum721S.get_next_token(owner, tokenId_idx);
    let (new_index: Uint256) = SafeUint256.sub_le(index, Uint256(val_x_1, 0));

    let (token_id: Uint256) = _ERC721S_tokenOwnerIndexLoop(
        owner=owner, index=new_index, tokenId_idx=new_tokenId_idx, max_id=max_id
    );
    return (token_id,);
}

func _ERC721S_token_by_index_loop{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(index: Uint256, tokenId_idx: Uint256, max_id: Uint256) -> (tokenId: Uint256) {
    alloc_locals;
    // ----------- 1. check if tokenId_idx is out of total supply range ----------- #
    // tokenId_idx > max tokenId
    // if so revert
    with_attr error_message("ERC721S: cant find owner token by index") {
        let (is_exceeded) = uint256_lt(max_id, tokenId_idx);
        assert is_exceeded = FALSE;
    }

    let (local sAsset: ScalarAsset) = ERC721S_tokenAsset.read(tokenId_idx);

    // --------------------- 2. check if not_burnt == False --------------------- //
    // if so skip to the next tokenId
    let (local not_burnt) = ScalarHandler.check_is_valid(sAsset);
    if (not_burnt == FALSE) {
        let (temp_token_idx: Uint256) = SafeUint256.add(tokenId_idx, Uint256(1, 0));
        return _ERC721S_token_by_index_loop(index=index, tokenId_idx=temp_token_idx, max_id=max_id);
    }
    // --------------- 3. check if token not_burnt = TRUE and if index = 0 -------------- #
    // if so return token id
    let (local is_lastIdx) = uint256_eq(index, Uint256(0, 0));

    if (is_lastIdx == TRUE) {
        return (tokenId_idx,);
    }

    // ---------------- 3. if not_burnt = TRUE and index <= next_seq --------------- #
    // return tokenId = tokenId_idx + index
    let (local next_seq) = ScalarHandler.get_next_seq(sAsset);
    let (le_Seq) = uint256_le(index, Uint256(next_seq, 0));

    if (le_Seq == TRUE) {
        let (new_token_id: Uint256) = SafeUint256.add(tokenId_idx, index);
        return (new_token_id,);
    }

    // ---------------- 4. if index > next_seq ---------------- #
    tempvar val_x = next_seq + 1;

    let (new_tokenId_idx: Uint256) = SafeUint256.add(tokenId_idx, Uint256(val_x, 0));
    let (new_index: Uint256) = SafeUint256.sub_le(index, Uint256(val_x, 0));

    let (token_id: Uint256) = _ERC721S_token_by_index_loop(
        index=new_index, tokenId_idx=new_tokenId_idx, max_id=max_id
    );
    return (token_id,);
}

func _ERC721S_getOwnerTokensLoop{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(
    owner: felt,
    index: Uint256,
    max_bal: Uint256,
    tokenId_idx: Uint256,
    max_id: Uint256,
    tokenIds: Uint256*,
) {
    alloc_locals;

    let (is_equal) = uint256_eq(index, max_bal);
    if (is_equal == TRUE) {
        return ();
    }

    with_attr error_message("ERC721S: cant find owner token by index") {
        let (is_exceeded) = uint256_lt(max_id, tokenId_idx);
        let (is_zero) = uint256_le(tokenId_idx, Uint256(0, 0));
        assert is_zero = FALSE;
        assert is_exceeded = FALSE;
    }

    let (local sAsset: ScalarAsset) = ERC721S_tokenAsset.read(tokenId_idx);

    let (local is_owner) = ScalarHandler.check_is_asset_owner(sAsset, owner);
    let (local next_seq) = ScalarHandler.get_next_seq(sAsset);

    // ---------------- 4. if index > next_seq ---------------- #
    // 4.1 get new index base on is_owner
    // new_index = index - val_x
    // val_x = (is_owner * (next_seq + 1))
    // if is_owner = False -> val_x = (0 * (next_seq + 1)) = 0
    tempvar val_x_1 = next_seq + 1;
    tempvar val_x = is_owner * val_x_1;

    // 4.2 jump tokenId_idx based on not_burnt
    // jump token by 1 + jmp_val
    // jmp_val = (next_seq * not_burnt))
    // if not_burnt = FALSE -> jmp_val = (next_seq * 0) = 0
    let (local not_burnt) = ScalarHandler.check_is_valid(sAsset);

    _ERC721S_append_tokenIds(tokenIds, tokenId_idx, val_x);
    let (new_tokenId_idx: Uint256) = OwnerEnum721S.get_next_token(owner, tokenId_idx);
    let (new_index: Uint256) = SafeUint256.add(index, Uint256(val_x, 0));
    tempvar size_jump = Uint256.SIZE * val_x;

    _ERC721S_getOwnerTokensLoop(
        owner=owner,
        index=new_index,
        max_bal=max_bal,
        tokenId_idx=new_tokenId_idx,
        max_id=max_id,
        tokenIds=tokenIds + size_jump,
    );
    return ();
}

func _ERC721S_append_tokenIds{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenIds: Uint256*, tokenId: Uint256, jump_value: felt) {
    alloc_locals;
    if (jump_value == 0) {
        return ();
    }
    assert [tokenIds] = tokenId;
    tempvar new_jump_value = jump_value - 1;
    let (next_tokenId: Uint256) = SafeUint256.add(tokenId, Uint256(1, 0));
    _ERC721S_append_tokenIds(
        tokenIds=tokenIds + Uint256.SIZE, tokenId=next_tokenId, jump_value=new_jump_value
    );
    return ();
}

func _ERC721S_approve{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(to: felt, tokenId: Uint256) {
    alloc_locals;
    ERC721S_token_approvals.write(tokenId, to);
    let (local owner) = ERC721S_ownerOf(tokenId);
    Approval.emit(owner, to, tokenId);
    return ();
}

func _ERC721S_is_approved_or_owner{
    bitwise_ptr: BitwiseBuiltin*, pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr
}(spender: felt, tokenId: Uint256) -> (res: felt) {
    alloc_locals;

    let (local owner) = ERC721S_ownerOf(tokenId);
    if (owner == spender) {
        return (TRUE,);
    }

    let (approved_addr) = ERC721S_getApproved(tokenId);
    if (approved_addr == spender) {
        return (TRUE,);
    }

    let (is_operator) = ERC721S_isApprovedForAll(owner, spender);
    if (is_operator == TRUE) {
        return (TRUE,);
    }

    return (FALSE,);
}

// @audit-check _exist function
func _ERC721S_exist{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(tokenId: Uint256) -> (res: felt) {
    alloc_locals;
    // 1. check if tokenId is greater than zero
    with_attr error_message("ERC721S: tokenId cannot be zero or lesser than zero") {
        let (is_token_valid) = uint256_lt(Uint256(0, 0), tokenId);
        assert is_token_valid = TRUE;
    }

    let (sAsset: ScalarAsset) = ERC721S_tokenAsset.read(tokenId);
    // 2. check if token is burnt
    // if it is return False
    let (is_burnt) = ScalarHandler.safe_check_not_valid(sAsset);
    if (is_burnt == TRUE) {
        return (FALSE,);
    }

    // 3. checks if tokenId is smaller than or equal to current token index
    // if it is return false if not return TRUE
    let (cur_index: Uint256) = TokenCounter.current();
    let (res) = uint256_le(tokenId, cur_index);
    return (res,);
}

// @audit-check _ERC721S_transfer function
func _ERC721S_transfer{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(from_: felt, to: felt, tokenId: Uint256) {
    alloc_locals;

    // --------------------------- 1. do relavant checks -------------------------- #
    // 1.1 check if from_ and to address is not zero address if it is revert
    with_attr error_message("ERC721S: from_ or to address cannot be zero address") {
        assert_not_zero(from_ * to);
    }

    // 1.2 check if from_ address owns token
    // _get_owner_and_fId checks if tokenId exist
    let (local _owner, local f_tokenId) = _get_owner_and_fId(tokenId);
    with_attr error_message("ERC721S: transfer from incorrect owner") {
        assert _owner = from_;
    }

    // 1.3 check previous tokenId
    let (local p_tokenId: Uint256) = SafeUint256.sub_le(tokenId, Uint256(1, 0));
    // --------------------- 2. Decrease and Increase balances -------------------- #
    // 2.1 Decrease owner balance
    let (local owner_bal) = ERC721S_balances.read(from_);
    let (new_balance: Uint256) = SafeUint256.sub_le(owner_bal, Uint256(1, 0));
    ERC721S_balances.write(from_, new_balance);
    // 2.2 Increase receiver balance
    let (receiver_bal) = ERC721S_balances.read(to);
    let (new_balance: Uint256) = SafeUint256.add(receiver_bal, Uint256(1, 0));
    ERC721S_balances.write(to, new_balance);
    // -------------------------- 3. SCENARIO 1 ------------------------- #
    // scenario 1 = if current tokenId asset is not in a batch
    // asset must have owner and next_seq >= 1
    // if so change asset owner
    let (local sAsset: ScalarAsset) = ERC721S_tokenAsset.read(tokenId);
    let (local cur_next_seq) = ScalarHandler.get_next_seq(sAsset);

    local has_owner = is_not_zero(sAsset.owner);
    local has_next_seq = is_le(1, cur_next_seq);

    if (has_owner == TRUE and has_next_seq == FALSE) {
        let (add_tokenId, add_sAsset) = _check_can_add_to_seq(p_tokenId, to, 1);
        let (cant_add) = uint256_le(add_tokenId, Uint256(0, 0));

        // 0.1 change owner lowest token
        OwnerEnum721S.not_in_batch_remove(from_, tokenId);
        // 1.1 change tokenid asset owner
        tempvar new_sAsset: ScalarAsset = ScalarAsset(owner=to * cant_add, slot=sAsset.slot, units=sAsset.units, data=sAsset.data);
        ERC721S_tokenAsset.write(tokenId, new_sAsset);

        if (cant_add == FALSE) {
            ERC721S_tokenAsset.write(add_tokenId, add_sAsset);

            _ERC721S_approve(0, tokenId);
            Transfer.emit(from_, to, tokenId);
            return ();
        }
        // 1.1.1 change reciver lowest token
        OwnerEnum721S.add_to_enumeration(to, tokenId);
        // 1.2 clear approvals and emit event
        _ERC721S_approve(0, tokenId);
        Transfer.emit(from_, to, tokenId);
        return ();
    }

    // -------------------------- 4. SCENARIO 2 ------------------------- #
    // scenario 2 = current tokenId asset is first one in batch
    // asset must have owner and have seq
    // essentially if tokenId being transfered is the first one in the batch
    // if so change asset owner for current Id and next Id
    tempvar scenario_2 = has_owner * has_next_seq;
    if (scenario_2 == TRUE) {
        // 4.1 safety assertion if this fails that means theres a bug in the code
        // ensures that current tokenId is  first tokenId
        with_attr error_message("ERC721S: transfer scenario 2 error") {
            let (is_the_first) = uint256_eq(tokenId, f_tokenId);
            assert is_the_first = TRUE;
        }

        // 4.1.1 change owner and reciver lowest token

        // check if can add next_seq to previous token
        let (add_tokenId, add_sAsset) = _check_can_add_to_seq(p_tokenId, to, 1);
        let (cant_add) = uint256_le(add_tokenId, Uint256(0, 0));

        // 4.2 change current tokenId asset
        // owner = to * cant_add and set its next_seq=0
        // if cant_add = FALSE owner will be set to zero and next seq will be added on the previous token
        let (temp_sAsset: ScalarAsset) = ScalarHandler.update_next_seq(sAsset, 0);
        ERC721S_tokenAsset.write(
            tokenId,
            ScalarAsset(owner=to * cant_add, slot=temp_sAsset.slot, units=temp_sAsset.units, data=temp_sAsset.data),
        );

        // 4.3 change next tokenId asset in seq
        // owner=from_ and next_seq=next_seq - 1
        let (local next_tokenId: Uint256) = SafeUint256.add(tokenId, Uint256(1, 0));
        let (next_sAsset: ScalarAsset) = ERC721S_tokenAsset.read(next_tokenId);
        let (next_sAsset: ScalarAsset) = ScalarHandler.update_next_seq(
            next_sAsset, cur_next_seq - 1
        );
        ERC721S_tokenAsset.write(
            next_tokenId,
            ScalarAsset(owner=from_, slot=next_sAsset.slot, units=next_sAsset.units, data=next_sAsset.data),
        );

        // 4.3.1 change owner lowest token
        OwnerEnum721S.start_of_batch_remove(from_, tokenId);
        // if can_add == TRUE
        // change prev token next seq
        if (cant_add == FALSE) {
            ERC721S_tokenAsset.write(add_tokenId, add_sAsset);

            _ERC721S_approve(0, tokenId);
            Transfer.emit(from_, to, tokenId);
            return ();
        }
        // 4.3.2 change reciver lowest token
        OwnerEnum721S.add_to_enumeration(to, tokenId);
        // 4.4 clear approvals and emit event
        _ERC721S_approve(0, tokenId);
        Transfer.emit(from_, to, tokenId);
        return ();
    }

    // -------------------------- 5. check for scenario 3 ------------------------- #
    // scenario 3 = current sAsset is last one in batch
    // asset must have no owner and no seq

    // 5.1 safety assertion if this fails that means theres a bug in the code
    // ensures that current tokenId is not first tokenId
    with_attr error_message("ERC721S: transfer scenario 3 error") {
        let (is_the_first) = uint256_eq(tokenId, f_tokenId);
        assert is_the_first = FALSE;
    }

    // 5.2 check if cur tokenId is last Id in batch
    let (local f_sAsset: ScalarAsset) = ERC721S_tokenAsset.read(f_tokenId);
    let (local f_next_seq) = ScalarHandler.get_next_seq(f_sAsset);
    let (local l_tokenId: Uint256) = SafeUint256.add(f_tokenId, Uint256(f_next_seq, 0));
    local not_in_batch = has_owner + has_next_seq;

    let (is_last_id) = uint256_eq(tokenId, l_tokenId);
    if (is_last_id == TRUE) {
        // 5.3 safety assertion if this fails that means theres a bug in the code
        // ensures that current tokenId asset has no owner and no seq
        with_attr error_message("ERC721S: transfer scenario 3 error") {
            assert not_in_batch = FALSE;
        }

        // 5.4 change last tokenId asset
        // current sAsset will equal to last sAsset
        let (l_sAsset: ScalarAsset) = ScalarHandler.update_next_seq(_asset=sAsset, _num=0);
        ERC721S_tokenAsset.write(
            tokenId,
            ScalarAsset(owner=to, slot=l_sAsset.slot, units=l_sAsset.units, data=l_sAsset.data),
        );

        // 5.5 change first tokenId next seq - 1
        let (new_f_sAsset: ScalarAsset) = ScalarHandler.sub_next_seq(_asset=f_sAsset, _num=1);
        ERC721S_tokenAsset.write(f_tokenId, new_f_sAsset);

        // 5.6 change reciver last tokenId
        OwnerEnum721S.add_to_enumeration(to, tokenId);
        // 5.7 Clear approvals and emit event
        _ERC721S_approve(0, tokenId);
        Transfer.emit(from_, to, tokenId);
        return ();
    }

    // -------------------------- 6. check for scenario 4 ------------------------- #
    // scenario 4 = current sAsset is in the middle of a batch
    // asset must have no owner and no seq

    // 6.1 safety assertion if this fails that means theres a bug in the code
    // ensures that current tokenId asset has no owner and no seq
    with_attr error_message("ERC721S: transfer scenario 4 error") {
        assert not_in_batch = FALSE;
    }

    // 6.2 change current asset owner
    ERC721S_tokenAsset.write(
        tokenId, ScalarAsset(owner=to, slot=sAsset.slot, units=sAsset.units, data=sAsset.data)
    );

    // 6.3 change first asset next_seq
    // next_seq = (current_id - first_id) - 1
    // ? assumes that the spread of current token and first token is not bigger than 120 bits
    let (temp_f_next_seq: Uint256) = SafeUint256.sub_lt(tokenId, f_tokenId);
    let (new_f_sAsset: ScalarAsset) = ScalarHandler.update_next_seq(
        f_sAsset, temp_f_next_seq.low - 1
    );
    ERC721S_tokenAsset.write(f_tokenId, new_f_sAsset);

    // 6.4 change next token asset owner and next_seq
    // owner = from_
    // next seq = last id - next id
    let (local next_tokenId: Uint256) = SafeUint256.add(tokenId, Uint256(1, 0));
    let (local m_next_seq: Uint256) = SafeUint256.sub_le(l_tokenId, next_tokenId);
    let (temp_sAsset: ScalarAsset) = ERC721S_tokenAsset.read(next_tokenId);
    // ? assumes that the spread of last token and next token is not bigger than 120 bits
    let (local m_sAsset: ScalarAsset) = ScalarHandler.update_next_seq(
        _asset=temp_sAsset, _num=m_next_seq.low
    );
    ERC721S_tokenAsset.write(
        next_tokenId,
        ScalarAsset(owner=from_, slot=m_sAsset.slot, units=m_sAsset.units, data=m_sAsset.data),
    );
    // 6.5 add and remove last tokenId from owner and reciver
    OwnerEnum721S.mid_of_batch_remove(from_, tokenId, f_tokenId);
    OwnerEnum721S.add_to_enumeration(to, tokenId);
    // 6.5 Clear approvals and emit event
    _ERC721S_approve(0, tokenId);
    Transfer.emit(from_, to, tokenId);
    return ();
}

func _ERC721S_safe_transfer{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(from_: felt, to: felt, tokenId: Uint256, data_len: felt, data: felt*) {
    alloc_locals;
    _ERC721S_transfer(from_, to, tokenId);
    _ERC721S_do_safe_transfer_acceptance_check(from_, to, tokenId, data_len, data);
    return ();
}

func _transfer_event_loop{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    tokenId: Uint256, index: felt, to: felt
) {
    alloc_locals;
    if (index == 0) {
        return ();
    }
    Transfer.emit(0, to, tokenId);
    let (new_id) = SafeUint256.add(tokenId, Uint256(1, 0));
    let new_index = index - 1;
    _transfer_event_loop(tokenId=new_id, index=new_index, to=to);
    return ();
}

// @audit-check acceptance check
func _ERC721S_do_safe_transfer_acceptance_check{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(from_: felt, to: felt, tokenId: Uint256, data_len: felt, data: felt*) {
    let (success) = _check_onERC721Received(from_, to, tokenId, data_len, data);
    with_attr error_message("ERC721S: transfer to non ERC721Receiver implementer") {
        assert_not_zero(success);
    }
    return ();
}

// @audit-check acceptance loop
func _ERC721S_do_safe_transfer_acceptance_check_loop{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(from_: felt, to: felt, tokenId: Uint256, index: felt, data_len: felt, data: felt*) {
    alloc_locals;
    if (index == 0) {
        return ();
    }
    _ERC721S_do_safe_transfer_acceptance_check(from_, to, tokenId, data_len, data);
    let (temp_id) = SafeUint256.add(tokenId, Uint256(1, 0));
    let new_index = index - 1;
    _ERC721S_do_safe_transfer_acceptance_check_loop(
        from_=from_, to=to, tokenId=temp_id, index=new_index, data_len=data_len, data=data
    );
    return ();
}

// @audit-check onReceived
func _check_onERC721Received{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    from_: felt, to: felt, tokenId: Uint256, data_len: felt, data: felt*
) -> (success: felt) {
    let (caller) = get_caller_address();
    let (is_supported) = IERC165.supportsInterface(to, IERC721_RECEIVER_ID);
    if (is_supported == TRUE) {
        let (selector) = IERC721Receiver.onERC721Received(
            to, caller, from_, tokenId, data_len, data
        );

        with_attr error_message("ERC721S: transfer to non ERC721Receiver implementer") {
            assert selector = IERC721_RECEIVER_ID;
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
