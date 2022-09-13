%lang starknet
%builtins pedersen range_check bitwise

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.uint256 import Uint256

from SeraphLabs.tokens.ERC721S.library import (
    ERC721S_initializer,
    ERC721S_name,
    ERC721S_symbol,
    ERC721S_total_supply,
    ERC721S_balanceOf,
    ERC721S_ownerOf,
    ERC721S_tokenOfOwnerByIndex,
    ERC721S_tokenByIndex,
    ERC721S_transferFrom,
    ERC721S_getOwnerTokens,
)

from SeraphLabs.tokens.ERC3525.library import (
    ERC3525_initalizer,
    ERC3525_slotOf,
    ERC3525_supplyOfSlot,
    ERC3525_tokenOfSlotByIndex,
    ERC3525_unitsInToken,
    ERC3525_allowance,
    ERC3525_safeMint,
    ERC3525_burn,
    ERC3525_approve,
    ERC3525_split,
    ERC3525_Merge,
    ERC3525_transferFrom,
    ERC3525_clearUnitApprovals,
)

@constructor
func constructor{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    name: felt, symbol: felt
) {
    ERC721S_initializer(name, symbol);
    ERC3525_initalizer();
    return ();
}

// ---------------------------------------------------------------------------- #
//                            ERC721S view functions                            #
// ---------------------------------------------------------------------------- #

@view
func name{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() -> (name: felt) {
    let (name) = ERC721S_name();
    return (name,);
}

@view
func symbol{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() -> (symbol: felt) {
    let (symbol) = ERC721S_symbol();
    return (symbol,);
}

@view
func totalSupply{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() -> (
    supply: Uint256
) {
    let (res: Uint256) = ERC721S_total_supply();
    return (res,);
}

@view
func balanceOf{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(owner: felt) -> (
    balance: Uint256
) {
    let (balance: Uint256) = ERC721S_balanceOf(owner);
    return (balance,);
}

@view
func ownerOf{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256) -> (owner: felt) {
    let (owner) = ERC721S_ownerOf(tokenId);
    return (owner,);
}

@view
func getOwnerTokens{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(owner: felt) -> (tokenIds_len: felt, tokenIds: Uint256*) {
    alloc_locals;
    let (arr_len, arr) = ERC721S_getOwnerTokens(owner);
    return (arr_len, arr);
}

@view
func tokenOfOwnerByIndex{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(owner: felt, index: Uint256) -> (tokenId: Uint256) {
    let (tokenId: Uint256) = ERC721S_tokenOfOwnerByIndex(owner, index);
    return (tokenId,);
}

@view
func tokenByIndex{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(index: Uint256) -> (tokenId: Uint256) {
    let (tokenId: Uint256) = ERC721S_tokenByIndex(index);
    return (tokenId,);
}

// ---------------------------------------------------------------------------- #
//                            ERC3525 view functions                            #
// ---------------------------------------------------------------------------- #

@view
func slotOf{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256) -> (slot: Uint256) {
    let (slot: Uint256) = ERC3525_slotOf(tokenId);
    return (slot,);
}

@view
func supplyOfSlot{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    slot: Uint256
) -> (supply: Uint256) {
    let (supply: Uint256) = ERC3525_supplyOfSlot(slot);
    return (supply,);
}

@view
func tokenOfSlotByIndex{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(slot: Uint256, index: Uint256) -> (tokenId: Uint256) {
    let (tokenId: Uint256) = ERC3525_tokenOfSlotByIndex(slot, index);
    return (tokenId,);
}

@view
func unitsInToken{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256) -> (units: Uint256) {
    let (units: Uint256) = ERC3525_unitsInToken(tokenId);
    return (units,);
}

@view
func allowance{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256, spender: felt) -> (units: Uint256) {
    let (units: Uint256) = ERC3525_allowance(tokenId, spender);
    return (units,);
}

// ---------------------------------------------------------------------------- #
//                           external functions                                 #
// ---------------------------------------------------------------------------- #

@external
func transferFrom{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(from_: felt, to: felt, tokenId: Uint256) {
    ERC721S_transferFrom(from_, to, tokenId);
    ERC3525_clearUnitApprovals(tokenId);
    return ();
}

@external
func unitTransferFrom{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(from_: felt, to: felt, tokenId: Uint256, targetTokenId: Uint256, units: Uint256) {
    ERC3525_transferFrom(from_, to, tokenId, targetTokenId, units);
    return ();
}

@external
func unitApprove{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(to: felt, tokenId: Uint256, units: Uint256) {
    ERC3525_approve(to, tokenId, units);
    return ();
}

@external
func split{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256, units_arr_len: felt, units_arr: Uint256*) -> (ids_len: felt, ids: Uint256*) {
    let (ids_len, ids) = ERC3525_split(tokenId, units_arr_len, units_arr);
    return (ids_len, ids);
}

@external
func merge{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenIds_len: felt, tokenIds: Uint256*, targetTokenId: Uint256) {
    ERC3525_Merge(tokenIds_len, tokenIds, targetTokenId);
    return ();
}

@external
func safeMint{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(_quantity: Uint256, _slotId: Uint256, _units: Uint256, data_len: felt, data: felt*) {
    alloc_locals;
    let (minter) = get_caller_address();
    ERC3525_safeMint(minter, _quantity, _slotId, _units, data_len, data);
    return ();
}

@external
func burn{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256) {
    alloc_locals;
    let (local caller) = get_caller_address();
    with_attr error_message("caller cannot be zero address") {
        assert_not_zero(caller);
    }
    ERC3525_burn(tokenId);
    return ();
}
