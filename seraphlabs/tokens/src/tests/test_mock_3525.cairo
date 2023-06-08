use seraphlabs_tokens::tests::mocks::{Mock3525Contract as Mock, ERC3525Receiver as Receiver};
use seraphlabs_tokens::utils::constants;
use starknet::{ContractAddress, contract_address_const};
use starknet::testing::set_caller_address;
use starknet::class_hash::Felt252TryIntoClassHash;
use traits::{Into, TryInto};
use option::OptionTrait;
use array::ArrayTrait;
use core::result::ResultTrait;
use zeroable::Zeroable;

fn VALUE_DECIMALS() -> u8 {
    20_u8
}

fn TOKEN_ID() -> u256 {
    2114_u256
}

fn SLOT() -> u256 {
    7_u256
}

fn SLOT2() -> u256 {
    8_u256
}

fn OWNER() -> ContractAddress {
    contract_address_const::<2114>()
}

fn USER() -> ContractAddress {
    contract_address_const::<3525>()
}

fn OPERATOR() -> ContractAddress {
    contract_address_const::<721>()
}

fn INVALID_ADDRESS() -> ContractAddress {
    Zeroable::zero()
}

fn RECEIVER() -> ContractAddress {
    let (address, _) = starknet::deploy_syscall(
        Receiver::TEST_CLASS_HASH.try_into().unwrap(), 0, ArrayTrait::new().span(), false
    )
        .unwrap();
    address
}

#[test]
#[available_gas(2000000)]
fn test_constructor() {
    Mock::constructor(VALUE_DECIMALS());

    assert(Mock::supports_interface(constants::IERC3525_ID), 'missing interface ID');
    assert(Mock::supports_interface(constants::IERC721_ENUMERABLE_ID), 'missing interface ID');
    assert(Mock::supports_interface(constants::IERC721_ID), 'missing interface ID');
    assert(Mock::value_decimals() == VALUE_DECIMALS(), 'wrong value decimals');
}


#[test]
#[available_gas(2000000)]
fn test_balance() {
    let owner = OWNER();
    Mock::mint(owner, TOKEN_ID(), SLOT(), 100);
    assert(Mock::balance_of(owner) == 1_u256, 'wrong balance');
}

#[test]
#[available_gas(2000000)]
fn test_owner_of() {
    let token_id = TOKEN_ID();
    let owner = OWNER();
    Mock::mint(owner, token_id, SLOT(), 100);
    assert(Mock::owner_of(token_id) == owner, 'wrong owner');
}

#[test]
#[available_gas(2000000)]
fn test_slot_of() {
    let token_id = TOKEN_ID();
    let slot = SLOT();
    Mock::mint(OWNER(), token_id, slot, 100);
    assert(Mock::slot_of(token_id) == slot, 'wrong slot');
}

#[test]
#[available_gas(2000000)]
fn test_value_units() {
    let token_id = TOKEN_ID();
    Mock::mint(OWNER(), token_id, SLOT(), 100);
    assert(Mock::value_of(token_id) == 100_u256, 'wrong value units');
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC3525: invalid to address', ))]
fn test_invalid_owner_mint() {
    Mock::mint(INVALID_ADDRESS(), TOKEN_ID(), SLOT(), 100);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC3525: token already exist', ))]
fn test_same_token() {
    let token_id = TOKEN_ID();
    let owner = OWNER();
    let slot = SLOT();
    Mock::mint(owner, token_id, slot, 100);
    Mock::mint(owner, token_id, slot, 20);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC3525: invalid token_id', ))]
fn test_invalid_token_id() {
    Mock::mint(OWNER(), 0_u256, SLOT(), 100);
}

#[test]
#[available_gas(2000000)]
fn test_enum() {
    let token_id = TOKEN_ID();
    let owner = OWNER();
    Mock::mint(owner, token_id, SLOT(), 100);
    assert(Mock::token_by_index(0_u256) == token_id, 'wrong token id');
    assert(Mock::token_of_owner_by_index(owner, 0_u256) == token_id, 'wrong token id');
    assert(Mock::total_supply() == 1_u256, 'wrong total supply');
}

#[test]
#[available_gas(2000000)]
fn test_owner_approve_value() {
    let token_id = TOKEN_ID();
    let owner = OWNER();
    let user = USER();
    Mock::mint(owner, token_id, SLOT(), 100);

    set_caller_address(owner);
    Mock::approve_value(token_id, user, 100);
    assert(Mock::allowance(token_id, user) == 100, 'wrong allowance');
}

#[test]
#[available_gas(2000000)]
fn test_approve_value_from_opeartor() {
    let token_id = TOKEN_ID();
    let owner = OWNER();
    let operator = OPERATOR();
    let user = USER();

    Mock::mint(owner, token_id, SLOT(), 100);

    set_caller_address(owner);
    Mock::approve(operator, token_id);

    set_caller_address(operator);
    Mock::approve_value(token_id, user, 100);
    assert(Mock::allowance(token_id, user) == 100, 'wrong allowance');
}

#[test]
#[available_gas(2000000)]
fn test_approve_from_all_opeartor_approve_value() {
    let token_id = TOKEN_ID();
    let owner = OWNER();
    let operator = OPERATOR();
    let user = USER();
    Mock::mint(owner, token_id, SLOT(), 100);

    set_caller_address(owner);
    Mock::set_approval_for_all(operator, true);

    set_caller_address(operator);
    Mock::approve_value(token_id, user, 100);
    assert(Mock::allowance(token_id, user) == 100, 'wrong allowance');
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC3525: approval to owner', ))]
fn test_approve_value_to_owner() {
    let token_id = TOKEN_ID();
    let owner = OWNER();
    Mock::mint(owner, token_id, SLOT(), 100);
    set_caller_address(owner);
    Mock::approve_value(token_id, owner, 100);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC3525: caller not approved', ))]
fn test_approve_value_from_not_approved() {
    let token_id = TOKEN_ID();
    let owner = OWNER();
    let user = USER();

    Mock::mint(owner, token_id, SLOT(), 100);
    set_caller_address(user);
    Mock::approve_value(token_id, user, 100);
}


#[test]
#[available_gas(20000000)]
fn test_transfer_value_with_no_token() {
    let reciever = RECEIVER();
    let token_id = TOKEN_ID();
    let owner = OWNER();
    let slot = SLOT();

    Mock::mint(owner, token_id, slot, 100);
    set_caller_address(owner);

    assert(
        Mock::transfer_value_from(token_id, reciever, 50) == token_id + 1_u256, 'wrong token id'
    );

    assert(Mock::balance_of(owner) == 1_u256, 'wrong balance');
    assert(Mock::balance_of(reciever) == 1_u256, 'wrong balance');

    assert(Mock::owner_of(token_id) == owner, 'wrong owner');
    assert(Mock::owner_of(token_id + 1_u256) == reciever, 'wrong owner');

    assert(Mock::value_of(token_id) == 50_u256, 'wrong value units');
    assert(Mock::value_of(token_id + 1_u256) == 50_u256, 'wrong value units');

    assert(Mock::slot_of(token_id) == slot, 'wrong slot');
    assert(Mock::slot_of(token_id + 1_u256) == slot, 'wrong slot');
}

#[test]
#[available_gas(20000000)]
fn test_transfer_value_with_same_slot() {
    let reciever = RECEIVER();
    let token_id = TOKEN_ID();
    let owner = OWNER();
    let slot = SLOT();
    let slot2 = SLOT2();
    let wrong_slot_token_1 = 20_u256;
    let same_slot_token = 3525_u256;
    let wrong_slot_token_2 = 721_u256;

    Mock::mint(owner, token_id, slot, 100);
    Mock::mint(reciever, wrong_slot_token_1, slot2, 100);
    Mock::mint(reciever, same_slot_token, slot, 100);
    Mock::mint(reciever, wrong_slot_token_2, slot2, 100);

    set_caller_address(owner);

    assert(Mock::transfer_value_from(token_id, reciever, 50) == same_slot_token, 'wrong token id');

    assert(Mock::balance_of(owner) == 1_u256, 'wrong balance');
    assert(Mock::balance_of(reciever) == 3_u256, 'wrong balance');

    assert(Mock::owner_of(token_id) == owner, 'wrong owner');
    assert(Mock::owner_of(wrong_slot_token_1) == reciever, 'wrong owner');
    assert(Mock::owner_of(same_slot_token) == reciever, 'wrong owner');
    assert(Mock::owner_of(wrong_slot_token_2) == reciever, 'wrong owner');

    assert(Mock::value_of(token_id) == 50_u256, 'wrong value units');
    assert(Mock::value_of(same_slot_token) == 150_u256, 'wrong value units');
    assert(Mock::value_of(wrong_slot_token_1) == 100_u256, 'wrong value units');
    assert(Mock::value_of(wrong_slot_token_2) == 100_u256, 'wrong value units');

    assert(Mock::slot_of(token_id) == slot, 'wrong slot');
    assert(Mock::slot_of(same_slot_token) == slot, 'wrong slot');
    assert(Mock::slot_of(wrong_slot_token_1) == slot2, 'wrong slot');
    assert(Mock::slot_of(wrong_slot_token_2) == slot2, 'wrong slot');
}

#[test]
#[available_gas(20000000)]
fn test_approve_unit_level_operator_value_transfer() {
    let reciever = RECEIVER();
    let token_id = TOKEN_ID();
    let owner = OWNER();
    let operator = OPERATOR();

    Mock::mint(owner, token_id, SLOT(), 100);
    set_caller_address(owner);
    Mock::approve_value(token_id, operator, 50);
    set_caller_address(operator);
    assert(
        Mock::transfer_value_from(token_id, reciever, 20) == token_id + 1_u256, 'wrong token id'
    );
    assert(Mock::balance_of(reciever) == 1_u256, 'wrong balance');
    assert(Mock::value_of(token_id + 1_u256) == 20, 'wrong value units');
    assert(Mock::allowance(token_id, operator) == 30, 'wrong allowance');
}

#[test]
#[available_gas(20000000)]
fn test_approve_operator_value_transfer() {
    let reciever = RECEIVER();
    let token_id = TOKEN_ID();
    let owner = OWNER();
    let operator = OPERATOR();

    Mock::mint(owner, token_id, SLOT(), 100);
    set_caller_address(owner);
    Mock::approve(operator, token_id);
    set_caller_address(operator);
    assert(
        Mock::transfer_value_from(token_id, reciever, 50) == token_id + 1_u256, 'wrong token id'
    );
    assert(Mock::balance_of(reciever) == 1_u256, 'wrong balance');
    assert(Mock::value_of(token_id + 1_u256) == 50, 'wrong value units');
}

#[test]
#[available_gas(20000000)]
fn test_approve_for_all_operator_value_transfer() {
    let reciever = RECEIVER();
    let token_id = TOKEN_ID();
    let owner = OWNER();
    let operator = OPERATOR();

    Mock::mint(owner, token_id, SLOT(), 100);
    set_caller_address(owner);
    Mock::set_approval_for_all(operator, true);
    set_caller_address(operator);
    assert(
        Mock::transfer_value_from(token_id, reciever, 50) == token_id + 1_u256, 'wrong token id'
    );
    assert(Mock::balance_of(reciever) == 1_u256, 'wrong balance');
    assert(Mock::value_of(token_id + 1_u256) == 50, 'wrong value units');
}

#[test]
#[available_gas(20000000)]
fn test_721_transfer() {
    let token_id = TOKEN_ID();
    let owner = OWNER();
    let user = USER();
    let operator = OPERATOR();

    Mock::mint(owner, token_id, SLOT(), 100);
    set_caller_address(owner);
    Mock::approve_value(token_id, operator, 50);
    Mock::transfer_from(owner, user, token_id);

    assert(Mock::owner_of(token_id) == user, 'wrong user');
    assert(Mock::allowance(token_id, operator) == 0_u256, 'allowance not cleared');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: operator not approved', ))]
fn test_unapprove_operator_value_transfer() {
    let reciever = RECEIVER();
    let token_id = TOKEN_ID();
    Mock::mint(OWNER(), token_id, SLOT(), 100);
    set_caller_address(USER());
    Mock::transfer_value_from(token_id, reciever, 25);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: insufficient balance', ))]
fn test_exceeding_value_transfer() {
    let reciever = RECEIVER();
    let token_id = TOKEN_ID();
    let owner = OWNER();

    Mock::mint(owner, token_id, SLOT(), 100);
    set_caller_address(owner);
    Mock::transfer_value_from(token_id, reciever, 101);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: Insufficient allowance', ))]
fn test_exceeding_unit_level_approved_operator_value_transfer() {
    let reciever = RECEIVER();
    let token_id = TOKEN_ID();
    let owner = OWNER();
    let operator = OPERATOR();

    Mock::mint(owner, token_id, SLOT(), 100);
    set_caller_address(owner);
    Mock::approve_value(token_id, operator, 50);
    set_caller_address(operator);
    Mock::transfer_value_from(token_id, reciever, 51);
}

#[test]
#[available_gas(20000000)]
fn test_mint_value() {
    let token_id = TOKEN_ID();
    let owner = OWNER();
    Mock::mint(owner, token_id, SLOT(), 100);
    Mock::mint_value(token_id, 2000);
    assert(Mock::value_of(token_id) == 2100, 'wrong value units');
}

#[test]
#[available_gas(20000000)]
fn test_3525_burn() {
    let token_id = TOKEN_ID();
    let owner = OWNER();
    let operator = OPERATOR();

    Mock::mint(owner, token_id, SLOT(), 100);
    set_caller_address(owner);
    // approve value
    Mock::approve_value(token_id, operator, 50);
    Mock::burn(token_id);

    assert(Mock::balance_of(owner) == 0_u256, 'wrong balance');
    assert(Mock::total_supply() == 0_u256, 'wrong total supply');
    assert(Mock::value_of(token_id) == 0_u256, 'not zero units');
    assert(Mock::slot_of(token_id) == 0_u256, 'not empty slot');
    assert(Mock::allowance(token_id, operator) == 0_u256, 'allowance not cleared');
}

#[test]
#[available_gas(20000000)]
fn test_burn_value() {
    let token_id = TOKEN_ID();
    let owner = OWNER();
    Mock::mint(owner, token_id, SLOT(), 100);
    Mock::burn_value(token_id, 50);
    assert(Mock::value_of(token_id) == 50_u256, 'wrong value units');
}
