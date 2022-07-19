%lang starknet
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.memcpy import memcpy
from SeraphLabs.strings.AsciiArray import word_to_ascii
from SeraphLabs.models.StringObject import StrObj
# ---------------------------------------------------------------------------- #
#                                   constants                                  #
# ---------------------------------------------------------------------------- #
const OPENCURLY = 123
const CLOSECURLY = 125
const OPENSQBRAC = 91
const CLOSESQBRAC = 93
const DOUBLEQUOTES = 34
const COLON = 58
const COMMA = 44
const WHITESPACE = 32

namespace JsonString:
    func enclose_curlyBraces{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}(
        arr_len : felt, arr : felt*
    ) -> (arr_len : felt, arr : felt*):
        alloc_locals
        let (new_arr_len, new_arr) = _new_array()
        assert [new_arr] = OPENCURLY
        memcpy(new_arr + 1, arr, arr_len)
        assert new_arr[arr_len + 1] = CLOSECURLY
        return (arr_len + 2, new_arr)
    end

    func enclose_word_with_doubleQuotes{
        syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
    }(arr_len : felt, arr : felt*) -> (arr_len : felt, arr : felt*):
        alloc_locals
        let (new_arr_len, new_arr) = _new_array()
        assert [new_arr] = DOUBLEQUOTES
        memcpy(new_arr + 1, arr, arr_len)
        assert new_arr[arr_len + 1] = DOUBLEQUOTES
        return (arr_len + 2, new_arr)
    end

    func create_key_value_pair{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}(
        keyArr_len : felt, keyArr : felt*, valueArr_len : felt, valueArr : felt*
    ) -> (arr_len : felt, arr : felt*):
        alloc_locals
        let (new_arr_len, new_arr) = _new_array()
        memcpy(new_arr, keyArr, keyArr_len)
        assert new_arr[keyArr_len] = COLON
        memcpy(new_arr + keyArr_len + 1, valueArr, valueArr_len)
        return (keyArr_len + valueArr_len + 1, new_arr)
    end

    func strings_to_key_value_pair{
        bitwise_ptr : BitwiseBuiltin*,
        syscall_ptr : felt*,
        range_check_ptr,
        pedersen_ptr : HashBuiltin*,
    }(string1 : StrObj, string2 : StrObj) -> (arr_len : felt, arr : felt*):
        alloc_locals

        let (key_len, key) = word_to_ascii(string1)
        let (val_len, val) = word_to_ascii(string2)
        assert key[key_len] = COLON
        memcpy(key + key_len + 1, val, val_len)
        return (key_len + val_len + 1, key)
    end

    func create_json_array{
        bitwise_ptr : BitwiseBuiltin*,
        syscall_ptr : felt*,
        range_check_ptr,
        pedersen_ptr : HashBuiltin*,
    }(header : StrObj, arr_len : felt, arr : felt*) -> (arr_len : felt, arr : felt*):
        alloc_locals
        let (new_arr_len, new_arr) = word_to_ascii(header)
        assert new_arr[new_arr_len] = COLON
        assert new_arr[new_arr_len + 1] = OPENSQBRAC
        memcpy(new_arr + new_arr_len + 2, arr, arr_len)
        assert new_arr[new_arr_len + arr_len + 2] = CLOSESQBRAC
        return (new_arr_len + arr_len + 3, new_arr)
    end

    func append_data_to_jsonArr{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}(
        arr1_len : felt, arr1 : felt*, arr2_len : felt, arr2 : felt*
    ) -> (arr_len : felt, arr : felt*):
        alloc_locals
        let (new_arr_len, new_arr) = _new_array()
        memcpy(new_arr, arr1, arr1_len - 1)
        assert new_arr[arr1_len - 1] = COMMA
        assert new_arr[arr1_len] = WHITESPACE
        memcpy(new_arr + arr1_len + 1, arr2, arr2_len)
        assert new_arr[arr1_len + arr2_len + 1] = CLOSESQBRAC
        return (arr1_len + arr2_len + 2, new_arr)
    end

    func append_new_data{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}(
        arr1_len : felt, arr1 : felt*, arr2_len : felt, arr2 : felt*
    ) -> (arr_len : felt, arr : felt*):
        alloc_locals
        let (new_arr_len, new_arr) = _new_array()
        memcpy(new_arr, arr1, arr1_len)
        assert new_arr[arr1_len] = COMMA
        assert new_arr[arr1_len + 1] = WHITESPACE
        memcpy(new_arr + arr1_len + 2, arr2, arr2_len)
        return (arr1_len + arr2_len + 2, new_arr)
    end

    func append_data_to_jsonString{
        syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
    }(arr1_len : felt, arr1 : felt*, arr2_len : felt, arr2 : felt*) -> (
        arr_len : felt, arr : felt*
    ):
        alloc_locals
        let (new_arr_len, new_arr) = _new_array()
        memcpy(new_arr, arr1, arr1_len - 1)
        assert new_arr[arr1_len - 1] = COMMA
        assert new_arr[arr1_len] = WHITESPACE
        memcpy(new_arr + arr1_len + 1, arr2, arr2_len)
        assert new_arr[arr1_len + arr2_len + 1] = CLOSECURLY
        return (arr1_len + arr2_len + 2, new_arr)
    end

    func append_data_to_enclosedString{
        syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
    }(arr1_len : felt, arr1 : felt*, arr2_len : felt, arr2 : felt*) -> (
        arr_len : felt, arr : felt*
    ):
        alloc_locals
        let (new_arr_len, new_arr) = _new_array()
        memcpy(new_arr, arr1, arr1_len - 1)
        memcpy(new_arr + arr1_len - 1, arr2, arr2_len)
        assert new_arr[arr1_len + arr2_len - 1] = DOUBLEQUOTES
        return (arr1_len + arr2_len, new_arr)
    end
end

func _new_array{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    arr_len : felt, arr : felt*
):
    alloc_locals
    let (local arr : felt*) = alloc()
    return (0, arr)
end
