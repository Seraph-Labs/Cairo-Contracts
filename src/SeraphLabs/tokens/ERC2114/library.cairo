// SPDX-License-Identifier: AGPL-3.0
// SeraphLabs Contracts for Cairo v0.3.0 (tokens/ERC2114/library.cairo)
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

from openzeppelin.introspection.ERC165.IERC165 import IERC165
// -------------------------------- constants ------------------------------- //
from SeraphLabs.utils.constants import IERC2114_ID
// ------------------------------- token libs ------------------------------- //
from SeraphLabs.tokens.ERC721S.library import (
    ERC721S_exist,
    ERC721S_ownerOf,
    _ERC721S_transfer,
    _ERC721S_is_approved_or_owner,
)
// ---------------------------------- libs ---------------------------------- //
from SeraphLabs.arrays.UintArray import UintArray
from SeraphLabs.math.simple_checks import is_uint_valid

from SeraphLabs.models.StringObject import StrObj, StrObj_check, assert_valid_StrObj
from SeraphLabs.tokens.erc2114.libs.scalarToken import TokenAttr, ScalarToken, ScalarTokenHandler
// -------------------------------------------------------------------------- //
//                                   events                                   //
// -------------------------------------------------------------------------- //
@event
func ScalarTransfer(from_: felt, tokenId: Uint256, to: Uint256, toContract: felt) {
}

@event
func ScalarRemove(from_: Uint256, tokenId: Uint256, to: felt) {
}

@event
func AttributeCreated(attrId: Uint256, name: StrObj) {
}

@event
func AttributeAdded(tokenId: Uint256, attrId: Uint256, value: StrObj, ammount: Uint256) {
}

// -------------------------------------------------------------------------- //
//                                   storage                                  //
// -------------------------------------------------------------------------- //
@storage_var
func ERC2114_attrName(attrId: Uint256) -> (name: StrObj) {
}

@storage_var
func ERC2114_tokenToToken(tokenId: Uint256) -> (SToken: ScalarToken) {
}

@storage_var
func ERC2114_tokenBalance(tokenId: Uint256) -> (balance: Uint256) {
}

@storage_var
func ERC2114_tokenAttribute_len(tokenId: Uint256) -> (len: felt) {
}

@storage_var
func ERC2114_tokenAttribute(tokenId: Uint256, index: felt) -> (attrId: Uint256) {
}

@storage_var
func ERC2114_tokenAttribute_value(tokenId: Uint256, attrId: Uint256) -> (tokenAttr: TokenAttr) {
}

// -------------------------------------------------------------------------- //
//                                 Constructor                                //
// -------------------------------------------------------------------------- //
func ERC2114_initializer{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    ERC165.register_interface(IERC2114_ID);
    return ();
}

// -------------------------------------------------------------------------- //
//                                   Getters                                  //
// -------------------------------------------------------------------------- //

func ERC2114_tokenOf{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256) -> (fromTokenId: Uint256, fromContract: felt) {
    alloc_locals;
    _ERC2114_assert_exist(tokenId);

    let (SToken: ScalarToken) = ERC2114_tokenToToken.read(tokenId);
    let (noToken) = uint256_le(SToken.tokenId, Uint256(0, 0));
    if (noToken == FALSE and SToken.from_ == 0) {
        let (contract_addr) = get_contract_address();
        return (SToken.tokenId, contract_addr);
    }

    return (SToken.tokenId, SToken.from_);
}

func ERC2114_tokenBalanceOf{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256) -> (balance: Uint256) {
    _ERC2114_assert_exist(tokenId);
    let (balance: Uint256) = ERC2114_tokenBalance.read(tokenId);
    return (balance,);
}

func ERC2114_attributesOf{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256) -> (attrIds_len: felt, attrIds: Uint256*) {
    alloc_locals;
    _ERC2114_assert_exist(tokenId);
    let (attrlen) = ERC2114_tokenAttribute_len.read(tokenId);
    let (local attrIds: Uint256*) = alloc();

    _ERC2114_getAttributesLoop(tokenId, 0, attrlen, attrIds);
    return (attrlen, attrIds);
}

func ERC2114_attributesCount{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256) -> (balance: Uint256) {
    _ERC2114_assert_exist(tokenId);

    let (attrLen) = ERC2114_tokenAttribute_len.read(tokenId);
    return (Uint256(attrLen, 0),);
}

func ERC2114_attributeAmmount{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256, attrId: Uint256) -> (ammount: Uint256) {
    alloc_locals;
    _ERC2114_assert_exist(tokenId);
    let (ammount: Uint256) = _ERC2114_attributeAmmount(tokenId, attrId);
    return (ammount,);
}

func ERC2114_attributeValue{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256, attrId: Uint256) -> (Str: StrObj) {
    alloc_locals;
    _ERC2114_assert_exist(tokenId);
    let (Str: StrObj) = _ERC2114_attributeValue(tokenId, attrId);
    return (Str,);
}

// -------------------------------------------------------------------------- //
//                                  externals                                 //
// -------------------------------------------------------------------------- //
func ERC2114_scalarTransferFrom{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(from_: felt, tokenId: Uint256, to: Uint256) {
    alloc_locals;
    _ERC2114_assert_exist(tokenId);
    _ERC2114_assert_exist(to);

    // ----------- check that tokenId is not already owned by another ----------- //
    _ERC2114_assert_notOwnedByToken(tokenId);

    // ------------- check that tokenId is not transfering to itself ------------ //
    with_attr error_message("ERC2114: tokenId cannot be the same as to tokenId") {
        let (is_equal) = uint256_eq(tokenId, to);
        assert is_equal = FALSE;
    }

    // -------- check if caller is approved or owner and not zero address ------- //
    let (caller) = get_caller_address();
    let (is_approved) = _ERC721S_is_approved_or_owner(caller, tokenId);
    with_attr error_message("ERC2114: caller is either not approved or is a zero address") {
        assert_not_zero(caller * is_approved);
    }

    let (contract_addr) = get_contract_address();
    _ERC721S_transfer(from_, contract_addr, tokenId);
    _ERC2114_scalar_transfer(from_, 0, tokenId, to);
    return ();
}

func ERC2114_scalarRemoveFrom{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(from_: Uint256, tokenId: Uint256) {
    alloc_locals;
    _ERC2114_assert_exist(from_);
    _ERC2114_assert_exist(tokenId);
    // ----------------------- check if from_ owns tokenId ---------------------- //
    _ERC2114_assert_tokenIsOwner(from_, tokenId, 0);
    // ---------------- check that tokenId is not rmoving itself ---------------- //
    with_attr error_message("ERC2114: from_ cannot be the same as to tokenId") {
        let (is_equal) = uint256_eq(from_, tokenId);
        assert is_equal = FALSE;
    }
    // ------------ check if caller is approved and not zero address ------------ //
    // checks the ownership and approval of the final parent tokenId of from_ tokenId
    let (local caller) = get_caller_address();
    let (owner, parentId) = _ERC2114_get_tokenOwner_loop(from_);
    let (is_approved) = _ERC721S_is_approved_or_owner(caller, parentId);
    with_attr error_message("ERC2114: caller is either not approved or is a zero address") {
        assert_not_zero(caller * is_approved);
    }

    let (contract_addr) = get_contract_address();
    _ERC721S_transfer(contract_addr, owner, tokenId);
    _ERC2114_scalar_remove(from_, tokenId, owner);
    return ();
}

func ERC2114_createAttribute{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    attrId: Uint256, name: StrObj
) {
    // ------------------------ check if attrId is valid ------------------------ //
    let (is_valid) = is_uint_valid(attrId);
    with_attr error_message("ERC2114: attrId is an invalid uint") {
        assert is_valid = TRUE;
    }
    // ------------------------ check if StrObj is valid ------------------------ //
    with_attr error_message("ERC2114: String object is invalid") {
        StrObj_check(name);
    }
    // -------------------- check if attribute already exist -------------------- //
    let (is_exist) = _ERC2114_check_attribute_exist(attrId);
    with_attr error_message("ERC2114: attrId already exist") {
        assert is_exist = FALSE;
    }
    ERC2114_attrName.write(attrId, name);
    AttributeCreated.emit(attrId, name);
    return ();
}

func ERC2114_batchCreateAttribute{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    attrIds_len: felt, attrIds: Uint256*, names_len: felt, names: StrObj*
) {
    alloc_locals;
    // ---------------------------- check array lens ---------------------------- //
    with_attr error_message("ERC2114: len cannot be 0") {
        assert_not_zero(attrIds_len * names_len);
    }
    // ------------------------ check length to be equal ------------------------ //
    with_attr error_message("ERC2114: args len must be equal") {
        assert attrIds_len = names_len;
    }
    _ERC2114_batchCreateAttribute_loop(attrIds_len, attrIds, names_len, names);
    return ();
}

func ERC2114_addAttribute{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256, attrId: Uint256, value: StrObj, ammount: Uint256) {
    alloc_locals;
    _ERC2114_assert_exist(tokenId);

    let (local attr_len) = ERC2114_tokenAttribute_len.read(tokenId);
    // ------------------------------ add attribute ----------------------------- //
    _ERC2114_addAttribute(tokenId, attrId, value, ammount, attr_len);
    // ---------------------------- increase balance ---------------------------- //
    tempvar new_len = attr_len + 1;
    ERC2114_tokenAttribute_len.write(tokenId, new_len);
    return ();
}

func ERC2114_batchAddAttribute{
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
    alloc_locals;
    _ERC2114_assert_exist(tokenId);

    let (local attr_len) = ERC2114_tokenAttribute_len.read(tokenId);
    // ---------------------------- check array lens ---------------------------- //
    with_attr error_message("ERC2114: len cannot be 0") {
        assert_not_zero(attrIds_len * values_len * ammounts_len);
    }
    // ------------------------ check length to be equal ------------------------ //
    with_attr error_message("ERC2114: args len must be equal") {
        assert attrIds_len = values_len;
        assert values_len = ammounts_len;
    }
    _ERC2114_add_attribute_loop(tokenId, attrIds, values, ammounts, attrIds_len, attr_len);
    tempvar new_len = attr_len + attrIds_len;
    ERC2114_tokenAttribute_len.write(tokenId, new_len);
    return ();
}
// -------------------------------------------------------------------------- //
//                                  internals                                 //
// -------------------------------------------------------------------------- //
func _ERC2114_attrIdName{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    attrId: Uint256
) -> (str: StrObj) {
    let (str: StrObj) = ERC2114_attrName.read(attrId);
    return (str,);
}

func _ERC2114_attributeAmmount{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    tokenId: Uint256, attrId: Uint256
) -> (ammount: Uint256) {
    let (attrObj: TokenAttr) = ERC2114_tokenAttribute_value.read(tokenId, attrId);
    return (attrObj.ammount,);
}

func _ERC2114_attributeValue{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    tokenId: Uint256, attrId: Uint256
) -> (Str: StrObj) {
    let (attrObj: TokenAttr) = ERC2114_tokenAttribute_value.read(tokenId, attrId);
    return (attrObj.value,);
}

func _ERC2114_get_tokenOwner_loop{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256) -> (owner: felt, parentId: Uint256) {
    let (SToken: ScalarToken) = ERC2114_tokenToToken.read(tokenId);
    let (has_tokenOwner) = ScalarTokenHandler.check_has_tokenOwner(SToken);

    if (has_tokenOwner == FALSE) {
        let (owner) = ERC721S_ownerOf(tokenId);
        return (owner, tokenId);
    }

    return _ERC2114_get_tokenOwner_loop(SToken.tokenId);
}

func _ERC2114_getAttributesLoop{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    tokenId: Uint256, index: felt, max_len: felt, attrIds: Uint256*
) {
    alloc_locals;
    if (index == max_len) {
        return ();
    }

    let (attrId: Uint256) = ERC2114_tokenAttribute.read(tokenId, index);
    assert [attrIds] = attrId;
    tempvar new_index = index + 1;

    _ERC2114_getAttributesLoop(
        tokenId=tokenId, index=new_index, max_len=max_len, attrIds=attrIds + Uint256.SIZE
    );
    return ();
}

func _ERC2114_scalar_transfer{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    from_: felt, toContract: felt, tokenId: Uint256, to: Uint256
) {
    let (bal: Uint256) = ERC2114_tokenBalance.read(to);
    let (new_bal: Uint256) = SafeUint256.add(bal, Uint256(1, 0));

    ERC2114_tokenBalance.write(to, new_bal);
    ERC2114_tokenToToken.write(tokenId, ScalarToken(to, toContract));
    if (toContract == 0) {
        let (contract_addr) = get_contract_address();
        ScalarTransfer.emit(from_, tokenId, to, contract_addr);
        return ();
    } else {
        ScalarTransfer.emit(from_, tokenId, to, toContract);
        return ();
    }
}

func _ERC2114_scalar_remove{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    fromTokenId: Uint256, tokenId: Uint256, to: felt
) {
    let (bal: Uint256) = ERC2114_tokenBalance.read(fromTokenId);
    let (new_bal: Uint256) = SafeUint256.sub_le(bal, Uint256(1, 0));

    ERC2114_tokenBalance.write(fromTokenId, new_bal);
    ERC2114_tokenToToken.write(tokenId, ScalarToken(Uint256(0, 0), 0));
    ScalarRemove.emit(fromTokenId, tokenId, to);
    return ();
}

func _ERC2114_batchCreateAttribute_loop{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(attrIds_len: felt, attrIds: Uint256*, names_len: felt, names: StrObj*) {
    if (attrIds_len == 0 and names_len == 0) {
        return ();
    }
    ERC2114_createAttribute([attrIds], [names]);
    _ERC2114_batchCreateAttribute_loop(
        attrIds_len=attrIds_len - 1,
        attrIds=attrIds + Uint256.SIZE,
        names_len=names_len - 1,
        names=names + StrObj.SIZE,
    );
    return ();
}

func _ERC2114_addAttribute{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    tokenId: Uint256, attrId: Uint256, value: StrObj, ammount: Uint256, index: felt
) {
    alloc_locals;
    // -------------------------- check if attrId exist ------------------------- //
    with_attr error_message("ERC2114: attrId does not exist") {
        let (is_exist) = _ERC2114_check_attribute_exist(attrId);
        assert is_exist = TRUE;
    }
    // ------------------------ check if StrObj is valid ------------------------ //
    with_attr error_message("ERC2114: StrObj is invalid") {
        assert_valid_StrObj(value);
    }
    // ------------------------ check if ammount is valid ----------------------- //
    with_attr error_message("ERC2114: ammount is not a valid uint") {
        let (is_valid) = is_uint_valid(ammount);
        assert is_valid = TRUE;
    }
    // ------------------ check if token owns this attribute Id ----------------- //
    with_attr error_message("ERC2114: tokenId already owns this attrId") {
        let (is_owned) = _ERC2114_check_attrId_ownership(tokenId, attrId);
        assert is_owned = FALSE;
    }
    // write value to attrId
    ERC2114_tokenAttribute_value.write(tokenId, attrId, TokenAttr(value, ammount));
    // write attrId to its index
    ERC2114_tokenAttribute.write(tokenId, index, attrId);
    // emit event
    AttributeAdded.emit(tokenId, attrId, value, ammount);
    return ();
}

func _ERC2114_add_attribute_loop{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    tokenId: Uint256, attrIds: Uint256*, values: StrObj*, ammounts: Uint256*, len: felt, index: felt
) {
    if (len == 0) {
        return ();
    }
    // add attribute
    _ERC2114_addAttribute(tokenId, [attrIds], [values], [ammounts], index);
    tempvar new_len = len - 1;
    tempvar new_index = index + 1;
    _ERC2114_add_attribute_loop(
        tokenId=tokenId,
        attrIds=attrIds + Uint256.SIZE,
        values=values + StrObj.SIZE,
        ammounts=ammounts + Uint256.SIZE,
        len=new_len,
        index=new_index,
    );
    return ();
}
// -------------------------------------------------------------------------- //
//                                 assertions                                 //
// -------------------------------------------------------------------------- //

func _ERC2114_assert_exist{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256) {
    let (exist) = ERC721S_exist(tokenId);
    with_attr error_message("ERC2114: tokeId does not exist") {
        assert exist = TRUE;
    }
    return ();
}

func _ERC2114_assert_notOwnedByToken{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256) {
    let (SToken: ScalarToken) = ERC2114_tokenToToken.read(tokenId);
    let (has_tokenOwner) = ScalarTokenHandler.check_has_tokenOwner(SToken);
    with_attr error_message("ERC2114: tokenId already owned by another token") {
        assert has_tokenOwner = FALSE;
    }
    return ();
}

func _ERC2114_assert_tokenIsOwner{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    tokenId: Uint256, owned_tokenId: Uint256, owned_tokenId_addr: felt
) {
    alloc_locals;
    let (SToken: ScalarToken) = ERC2114_tokenToToken.read(owned_tokenId);
    let (is_equal) = uint256_eq(SToken.tokenId, tokenId);
    with_attr error_message("ERC2114 : token does not own this tokenId") {
        assert is_equal = TRUE;
        assert owned_tokenId_addr = SToken.from_;
    }
    return ();
}

func _ERC2114_check_attribute_exist{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(attrId: Uint256) -> (res: felt) {
    let (string_obj: StrObj) = ERC2114_attrName.read(attrId);
    if (string_obj.val == 0 and string_obj.len == 0) {
        return (FALSE,);
    }
    return (TRUE,);
}

func _ERC2114_check_attrId_ownership{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}(tokenId: Uint256, attrId: Uint256) -> (res: felt) {
    alloc_locals;
    let (tokenAttr: TokenAttr) = ERC2114_tokenAttribute_value.read(tokenId, attrId);
    let (is_zero) = uint256_eq(tokenAttr.ammount, Uint256(0, 0));

    if (is_zero == TRUE) {
        return (FALSE,);
    }
    return (TRUE,);
}
