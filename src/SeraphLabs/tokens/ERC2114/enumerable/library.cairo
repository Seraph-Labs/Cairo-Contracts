// SPDX-License-Identifier: AGPL-3.0
// SeraphLabs Contracts for Cairo v0.3.0 (tokens/ERC2114/enumerable/library.cairo)
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_contract_address, get_caller_address
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

// -------------------------------- constants ------------------------------- //
from SeraphLabs.utils.constants import IERC2114_ENUMERABLE_ID

// --------------------------------- models --------------------------------- //
from SeraphLabs.tokens.ERC2114.libs.scalarToken import ScalarToken
// ---------------------------------- libs ---------------------------------- //
from SeraphLabs.tokens.ERC2114.library import (
    ERC2114_scalarTransferFrom,
    ERC2114_scalarRemoveFrom,
    ERC2114_tokenBalanceOf,
)

// -------------------------------------------------------------------------- //
//                                   storage                                  //
// -------------------------------------------------------------------------- //
@storage_var
func ERC2114Enumerable_tokenOfToken(tokenId: Uint256, index: Uint256) -> (SToken: ScalarToken) {
}

@storage_var
func ERC2114Enumerable_tokenIndex(tokenId: Uint256, from_contract: felt) -> (index: Uint256) {
}

// -------------------------------------------------------------------------- //
//                                 constructor                                //
// -------------------------------------------------------------------------- //
func ERC2114Enumerable_initializer{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    ) {
    ERC165.register_interface(IERC2114_ENUMERABLE_ID);
    return ();
}
// -------------------------------------------------------------------------- //
//                                    view                                    //
// -------------------------------------------------------------------------- //
func ERC2114Enumerable_tokenOfTokenByIndex{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256, index: Uint256) -> (tokenId: Uint256, from_: felt) {
    let (balance: Uint256) = ERC2114_tokenBalanceOf(tokenId);
    with_attr error_message("ERC2114: index is out of bounds") {
        let (is_valid) = uint256_lt(index, balance);
        assert is_valid = TRUE;
    }
    let (SToken: ScalarToken) = ERC2114Enumerable_tokenOfToken.read(tokenId, index);
    if (SToken.from_ == 0) {
        let (contract_addr) = get_contract_address();
        return (SToken.tokenId, contract_addr);
    } else {
        return (SToken.tokenId, SToken.from_);
    }
}

// -------------------------------------------------------------------------- //
//                                  external                                  //
// -------------------------------------------------------------------------- //
func ERC2114Enumerable_scalarTransferFrom{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(from_: felt, tokenId: Uint256, to: Uint256) {
    alloc_locals;
    // get balance first
    let (local balance: Uint256) = ERC2114_tokenBalanceOf(to);
    // trasfer token
    ERC2114_scalarTransferFrom(from_, tokenId, to);
    _ERC2114Enumerable_scalarTransferFrom(tokenId, to, balance);
    return ();
}

func ERC2114Enumerable_scalarRemoveFrom{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(from_: Uint256, tokenId: Uint256) {
    alloc_locals;
    // remove token
    ERC2114_scalarRemoveFrom(from_, tokenId);
    _ERC2114Enumerable_scalarRemoveFrom(from_, tokenId);
    return ();
}

// -------------------------------------------------------------------------- //
//                                  internals                                 //
// -------------------------------------------------------------------------- //

func _ERC2114Enumerable_scalarTransferFrom{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256, to: Uint256, index: Uint256) {
    alloc_locals;
    tempvar SToken: ScalarToken = ScalarToken(tokenId, 0);
    // write SToken to index
    ERC2114Enumerable_tokenOfToken.write(to, index, SToken);
    // write index to SToken
    ERC2114Enumerable_tokenIndex.write(tokenId, 0, index);
    return ();
}

func _ERC2114Enumerable_scalarRemoveFrom{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(from_: Uint256, tokenId: Uint256) {
    alloc_locals;
    // get balance
    let (balance: Uint256) = ERC2114_tokenBalanceOf(from_);
    // get index
    let (index: Uint256) = ERC2114Enumerable_tokenIndex.read(tokenId, 0);
    // check if from_ tokenId is the last index
    let (is_last) = uint256_eq(index, balance);

    tempvar empty_SToken: ScalarToken = ScalarToken(Uint256(0, 0), 0);
    if (is_last == TRUE) {
        // remove tokenId from from_ enummeration
        ERC2114Enumerable_tokenOfToken.write(from_, index, empty_SToken);
        // remove index from tokenId
        ERC2114Enumerable_tokenIndex.write(tokenId, 0, Uint256(0, 0));
        return ();
    } else {
        // get token in last index
        let (SToken: ScalarToken) = ERC2114Enumerable_tokenOfToken.read(from_, balance);
        // rewrite last token to current index
        ERC2114Enumerable_tokenOfToken.write(from_, index, SToken);
        // rewrite index from last token
        ERC2114Enumerable_tokenIndex.write(SToken.tokenId, SToken.from_, index);
        // remove index from tokenId
        ERC2114Enumerable_tokenIndex.write(tokenId, 0, Uint256(0, 0));
        return ();
    }
}
