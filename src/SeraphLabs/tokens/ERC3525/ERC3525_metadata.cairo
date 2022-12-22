// SPDX-License-Identifier: MIT
// SeraphLabs Contracts for Cairo v0.3.0 (tokens/ERC3525/ERC3525_metadata.cairo)
%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256

from SeraphLabs.strings.AsciiArray import uint256_to_ascii, word_to_ascii
from SeraphLabs.arrays.Array import Array
from SeraphLabs.models.StringObject import StrObj
from SeraphLabs.tokens.ERC721S.library import _ERC721S_exist

// ---------------------------------------------------------------------------- #
//                                    storage                                   #
// ---------------------------------------------------------------------------- #

@storage_var
func ERC3525_base_slot_uri(index: felt) -> (res: felt) {
}

@storage_var
func ERC3525_base_slot_uri_len() -> (res: felt) {
}

@storage_var
func ERC3525_base_slot_uri_suffix() -> (res: StrObj) {
}

// ---------------------------------------------------------------------------- #
//                              external functions                              #
// ---------------------------------------------------------------------------- #

func ERC3525_Metadata_slotURI{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(slot_id: Uint256) -> (slot_uri_len: felt, slot_uri: felt*) {
    alloc_locals;

    let (local base_slot_uri) = alloc();
    let (local base_slot_uri_len) = ERC3525_base_slot_uri_len.read();

    _ERC3525_Metadata_baseSlotURI(base_slot_uri_len, base_slot_uri);

    let (token_id_ss_len, token_id_ss) = uint256_to_ascii(slot_id);
    let (token_uri_arr_len, token_uri_arr) = Array.concat(
        base_slot_uri_len, base_slot_uri, token_id_ss_len, token_id_ss
    );
    let (ERC3525_slot_uri_suffix: StrObj) = ERC3525_base_slot_uri_suffix.read();
    let (suffix_arr_len, suffix_arr) = word_to_ascii(ERC3525_slot_uri_suffix);
    let (slot_uri_len, slot_uri) = Array.concat(
        token_uri_arr_len, token_uri_arr, suffix_arr_len, suffix_arr
    );

    return (slot_uri_len=slot_uri_len, slot_uri=slot_uri);
}

func ERC3525_Metadata_setBaseSlotURI{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(slot_uri_len: felt, slot_uri: felt*, token_uri_suffix: StrObj) {
    _ERC3525_Metadata_setBaseSlotURI(slot_uri_len, slot_uri);
    ERC3525_base_slot_uri_len.write(slot_uri_len);
    ERC3525_base_slot_uri_suffix.write(token_uri_suffix);
    return ();
}

// ---------------------------------------------------------------------------- #
//                              internal functions                              #
// ---------------------------------------------------------------------------- #

func _ERC3525_Metadata_baseSlotURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    base_slot_uri_len: felt, base_slot_uri: felt*
) {
    if (base_slot_uri_len == 0) {
        return ();
    }
    let (base) = ERC3525_base_slot_uri.read(base_slot_uri_len);
    assert [base_slot_uri] = base;
    _ERC3525_Metadata_baseSlotURI(
        base_slot_uri_len=base_slot_uri_len - 1, base_slot_uri=base_slot_uri + 1
    );
    return ();
}

func _ERC3525_Metadata_setBaseSlotURI{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(slot_uri_len: felt, slot_uri: felt*) {
    if (slot_uri_len == 0) {
        return ();
    }
    ERC3525_base_slot_uri.write(index=slot_uri_len, value=[slot_uri]);
    _ERC3525_Metadata_setBaseSlotURI(slot_uri_len=slot_uri_len - 1, slot_uri=slot_uri + 1);
    return ();
}
