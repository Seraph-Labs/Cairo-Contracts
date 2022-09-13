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
    ERC721S_transferFrom,
    ERC721S_mint,
    ERC721S_burn,
    ERC721S_getOwnerTokens,
)

@constructor
func constructor{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    name: felt, symbol: felt
) {
    ERC721S_initializer(name, symbol);
    return ();
}

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
}(owner: felt) -> (arr_len: felt, arr: Uint256*) {
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
func burn{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256) {
    alloc_locals;
    let (local caller) = get_caller_address();
    with_attr error_message("caller cannot be zero address") {
        assert_not_zero(caller);
    }
    ERC721S_burn(tokenId);
    return ();
}
