%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.introspection.ERC165.library import ERC165

from SeraphLabs.strings.AsciiArray import uint256_to_ascii, word_to_ascii
from SeraphLabs.arrays.Array import Array
from SeraphLabs.models.StringObject import StrObj
from SeraphLabs.utils.Constants import IERC721_METADATA_ID
from SeraphLabs.tokens.ERC721S.library import _ERC721S_exist
// ---------------------------------------------------------------------------- #
//                                    storage                                   #
// ---------------------------------------------------------------------------- #

@storage_var
func ERC721_base_token_uri(index: felt) -> (res: felt) {
}

@storage_var
func ERC721_base_token_uri_len() -> (res: felt) {
}

@storage_var
func ERC721_base_token_uri_suffix() -> (res: StrObj) {
}

// ---------------------------------------------------------------------------- #
//                                  constructor                                 #
// ---------------------------------------------------------------------------- #
func ERC721_Metadata_Initalizer{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    ERC165.register_interface(IERC721_METADATA_ID);
    return ();
}

// ---------------------------------------------------------------------------- #
//                              external functions                              #
// ---------------------------------------------------------------------------- #

func ERC721_Metadata_tokenURI{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(token_id: Uint256) -> (token_uri_len: felt, token_uri: felt*) {
    alloc_locals;

    let (exists) = _ERC721S_exist(token_id);
    assert exists = 1;

    let (local base_token_uri) = alloc();
    let (local base_token_uri_len) = ERC721_base_token_uri_len.read();

    _ERC721_Metadata_baseTokenURI(base_token_uri_len, base_token_uri);

    let (token_id_ss_len, token_id_ss) = uint256_to_ascii(token_id);
    let (temp_token_uri_len, temp_token_uri) = Array.concat(
        base_token_uri_len, base_token_uri, token_id_ss_len, token_id_ss
    );
    let (ERC721S_token_uri_suffix: StrObj) = ERC721_base_token_uri_suffix.read();
    let (suffix_arr_len, suffix_arr) = word_to_ascii(ERC721S_token_uri_suffix);
    let (token_uri_len, token_uri) = Array.concat(
        temp_token_uri_len, temp_token_uri, suffix_arr_len, suffix_arr
    );

    return (token_uri_len=token_uri_len, token_uri=token_uri);
}

func ERC721_Metadata_setBaseTokenURI{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(token_uri_len: felt, token_uri: felt*, token_uri_suffix: StrObj) {
    _ERC721_Metadata_setBaseTokenURI(token_uri_len, token_uri);
    ERC721_base_token_uri_len.write(token_uri_len);
    ERC721_base_token_uri_suffix.write(token_uri_suffix);
    return ();
}

// ---------------------------------------------------------------------------- #
//                              internal functions                              #
// ---------------------------------------------------------------------------- #

func _ERC721_Metadata_baseTokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    base_token_uri_len: felt, base_token_uri: felt*
) {
    if (base_token_uri_len == 0) {
        return ();
    }
    let (base) = ERC721_base_token_uri.read(base_token_uri_len);
    assert [base_token_uri] = base;
    _ERC721_Metadata_baseTokenURI(
        base_token_uri_len=base_token_uri_len - 1, base_token_uri=base_token_uri + 1
    );
    return ();
}

func _ERC721_Metadata_setBaseTokenURI{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(token_uri_len: felt, token_uri: felt*) {
    if (token_uri_len == 0) {
        return ();
    }
    ERC721_base_token_uri.write(index=token_uri_len, value=[token_uri]);
    _ERC721_Metadata_setBaseTokenURI(token_uri_len=token_uri_len - 1, token_uri=token_uri + 1);
    return ();
}
