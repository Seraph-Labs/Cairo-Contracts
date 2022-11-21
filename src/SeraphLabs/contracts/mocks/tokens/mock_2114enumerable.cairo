%lang starknet
%builtins pedersen range_check bitwise

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
from SeraphLabs.tokens.libs.scalarHandler import ScalarAsset

from SeraphLabs.tokens.ERC721S.library import (
    ERC721S_initializer,
    ERC721S_name,
    ERC721S_symbol,
    ERC721S_total_supply,
    ERC721S_balanceOf,
    ERC721S_ownerOf,
    ERC721S_tokenOfOwnerByIndex,
    ERC721S_tokenByIndex,
    ERC721S_getApproved,
    ERC721S_approve,
    ERC721S_transferFrom,
    ERC721S_mint,
)

from SeraphLabs.tokens.ERC2114.library import (
    ERC2114_tokenOf,
    ERC2114_tokenBalanceOf,
    ERC2114_attributesOf,
    ERC2114_attributesCount,
    ERC2114_attributeAmmount,
    ERC2114_attributeValue,
    ERC2114_createAttribute,
    ERC2114_batchCreateAttribute,
    ERC2114_addAttribute,
    ERC2114_batchAddAttribute,
)

from SeraphLabs.tokens.ERC2114.enumerable.library import (
    ERC2114Enumerable_tokenOfTokenByIndex,
    ERC2114Enumerable_scalarTransferFrom,
    ERC2114Enumerable_scalarRemoveFrom,
)

from SeraphLabs.models.StringObject import StrObj

@constructor
func constructor{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    name: felt, symbol: felt
) {
    ERC721S_initializer(name, symbol);
    return ();
}

// -------------------------------------------------------------------------- //
//                               721S view func                               //
// -------------------------------------------------------------------------- //
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

@view
func getApproved{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256) -> (approved: felt) {
    let (approved) = ERC721S_getApproved(tokenId);
    return (approved,);
}
// -------------------------------------------------------------------------- //
//                               2114 view func                               //
// -------------------------------------------------------------------------- //
@view
func tokenOfTokenByIndex{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256, index: Uint256) -> (tokenId: Uint256, from_: felt) {
    let (tokend, from_) = ERC2114Enumerable_tokenOfTokenByIndex(tokenId, index);
    return (tokenId, from_);
}

@view
func tokenOf{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256) -> (fromTokenId: Uint256, fromContract: felt) {
    return ERC2114_tokenOf(tokenId);
}

@view
func tokenBalanceOf{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256) -> (balance: Uint256) {
    return ERC2114_tokenBalanceOf(tokenId);
}

@view
func attributesOf{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256) -> (attrIds_len: felt, attrIds: Uint256*) {
    return ERC2114_attributesOf(tokenId);
}

@view
func attributesCount{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256) -> (balance: Uint256) {
    return ERC2114_attributesCount(tokenId);
}

@view
func attributesAmmount{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256, attrId: Uint256) -> (ammount: Uint256) {
    return ERC2114_attributeAmmount(tokenId, attrId);
}

@view
func attributeValue{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256, attrId: Uint256) -> (value_len: felt, value: felt*) {
    return ERC2114_attributeValue(tokenId, attrId);
}

// -------------------------------------------------------------------------- //
//                             721S external funcs                            //
// -------------------------------------------------------------------------- //
@external
func transferFrom{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(from_: felt, to: felt, tokenId: Uint256) {
    ERC721S_transferFrom(from_, to, tokenId);
    return ();
}

@external
func mint{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(_quantity: Uint256) {
    alloc_locals;
    let (minter) = get_caller_address();
    ERC721S_mint(minter, _quantity);
    return ();
}

@external
func approve{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(to: felt, tokenId: Uint256) {
    ERC721S_approve(to, tokenId);
    return ();
}
// -------------------------------------------------------------------------- //
//                               2114 exterbals                               //
// -------------------------------------------------------------------------- //
@external
func scalarTransferFrom{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(from_: felt, tokenId: Uint256, to: Uint256) {
    ERC2114Enumerable_scalarTransferFrom(from_, tokenId, to);
    return ();
}

@external
func scalarRemoveFrom{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(from_: Uint256, tokenId: Uint256) {
    ERC2114Enumerable_scalarRemoveFrom(from_, tokenId);
    return ();
}

@external
func createAttribute{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    attrId: Uint256, name: StrObj
) {
    ERC2114_createAttribute(attrId, name);
    return ();
}

@external
func batchCreateAttribute{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    attrIds_len: felt, attrIds: Uint256*, names_len: felt, names: StrObj*
) {
    ERC2114_batchCreateAttribute(attrIds_len, attrIds, names_len, names);
    return ();
}

@external
func addAttribute{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256, attrId: Uint256, value: StrObj, ammount: Uint256) {
    ERC2114_addAttribute(tokenId, attrId, value, ammount);
    return ();
}

@external
func batchAddAttribute{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(
    tokenId: Uint256,
    attrIds_len: felt,
    attrIds: Uint256*,
    values_len: felt,
    values: StrObj*,
    ammounts_len: felt,
    ammounts: Uint256*,
) {
    ERC2114_batchAddAttribute(
        tokenId, attrIds_len, attrIds, values_len, values, ammounts_len, ammounts
    );
    return ();
}
