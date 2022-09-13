%lang starknet
%builtins pedersen range_check bitwise
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import Uint256, uint256_check
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from SeraphLabs.strings.AsciiArray import word_to_ascii, concat_word_with_uint
from SeraphLabs.strings.JsonString import JsonString
from SeraphLabs.models.StringObject import StrObj, StrObj_is_equal

@view
func return_ascii_arr{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() -> (arr_len: felt, arr: felt*) {
    alloc_locals;
    let x = '"hello"';
    let (arr_len, arr) = word_to_ascii(StrObj(x, 7));
    return (arr_len, arr);
}

@view
func get_json{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() -> (arr_len: felt, arr: felt*) {
    alloc_locals;
    let x = '"name"';
    let y = '"BasicSeraph #1"';
    let i = '"weapon"';
    let j = '"sword"';
    let (key1_len, key1) = word_to_ascii(StrObj(x, 6));
    let (val1_len, val1) = word_to_ascii(StrObj(y, 16));
    let (key2_len, key2) = word_to_ascii(StrObj(i, 8));
    let (val2_len, val2) = word_to_ascii(StrObj(j, 7));
    let (data1_len, data1) = JsonString.create_key_value_pair(key1_len, key1, val1_len, val1);
    let (data2_len, data2) = JsonString.create_key_value_pair(key2_len, key2, val2_len, val2);
    let (data_all_len, data_all) = JsonString.append_new_data(data1_len, data1, data2_len, data2);
    let (arr_len, arr) = JsonString.enclose_curlyBraces(data_all_len, data_all);
    return (arr_len, arr);
}

@view
func get_string_with_uint_json{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() -> (arr_len: felt, arr: felt*) {
    alloc_locals;
    let x = '"name"';
    let y = 'BasicSeraph #';
    let i = '"weapon"';
    let j = '"sword"';
    let (temp_data1_1_len, temp_data1_1) = word_to_ascii(StrObj(x, 6));
    let (temp_data1_2_len, temp_data1_2) = concat_word_with_uint(StrObj(y, 13), Uint256(2114, 0));
    let (temp_data1_3_len, temp_data1_3) = JsonString.enclose_word_with_doubleQuotes(
        temp_data1_2_len, temp_data1_2
    );
    let (data1_len, data1) = JsonString.create_key_value_pair(
        temp_data1_1_len, temp_data1_1, temp_data1_3_len, temp_data1_3
    );
    let (data2_len, data2) = JsonString.strings_to_key_value_pair(StrObj(i, 8), StrObj(j, 7));
    let (data_all_len, data_all) = JsonString.append_new_data(data1_len, data1, data2_len, data2);
    let (arr_len, arr) = JsonString.enclose_curlyBraces(data_all_len, data_all);
    return (arr_len, arr);
}

@view
func get_string_jsonArr{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() -> (arr_len: felt, arr: felt*) {
    alloc_locals;
    let x = '"name"';
    let y = '"BasicSeraph"';
    let i = '"weapon"';
    let j = '"sword"';
    let h1 = '"attributes"';

    let (data1_len, data1) = JsonString.strings_to_key_value_pair(StrObj(x, 6), StrObj(y, 13));
    let (data2_len, data2) = JsonString.strings_to_key_value_pair(StrObj(i, 8), StrObj(j, 7));
    let (data_all_len, data_all) = JsonString.append_new_data(data1_len, data1, data2_len, data2);

    let (jsonArr1_len, JsonArr1) = JsonString.create_json_array(
        StrObj(h1, 12), data_all_len, data_all
    );
    let (jsonArr_len, jsonArr) = JsonString.append_data_to_jsonArr(
        jsonArr1_len, JsonArr1, data2_len, data2
    );

    let (tarr_len, tarr) = JsonString.append_new_data(data_all_len, data_all, jsonArr_len, jsonArr);
    let (arr_len, arr) = JsonString.enclose_curlyBraces(tarr_len, tarr);

    return (arr_len, arr);
}

@view
func test_enclosed_string_append{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256) -> (arr_len: felt, arr: felt*) {
    alloc_locals;
    let x = '"weapon"';
    let (number_arr_len, number_arr) = concat_word_with_uint(StrObj(' #', 2), tokenId);
    let (word_arr_len, word_arr) = word_to_ascii(StrObj(x, 8));
    let (arr_len, arr) = JsonString.append_data_to_enclosedString(
        word_arr_len, word_arr, number_arr_len, number_arr
    );
    return (arr_len, arr);
}

@view
func test_stringEqual{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    a: StrObj, b: StrObj
) -> (res: felt) {
    let (res) = StrObj_is_equal(a, b);
    return (res,);
}
