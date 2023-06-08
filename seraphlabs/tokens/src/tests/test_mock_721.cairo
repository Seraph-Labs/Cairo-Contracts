use seraphlabs_tokens::tests::mocks::{Mock721Contract as Mock, ERC721Receiver as Receiver, NonReceiver};
use seraphlabs_tokens::utils::constants;
use seraphlabs_utils::testing::{vars, utils};
use starknet::{ContractAddress, contract_address_const};
use starknet::testing::set_caller_address;
use traits::{Into, TryInto};
use option::OptionTrait;
use array::ArrayTrait;
use core::clone::Clone;

const NAME: felt252 = 'hello';
const SYMBOL: felt252 = 'world';

fn DATA(valid : bool) -> Span<felt252>{
    let mut data = ArrayTrait::<felt252>::new();
    match valid {
        bool::False(()) => data.append('fail'),
        bool::True(()) => data.append('pass'),
    }
    data.span()
}

fn RECEIVER() -> ContractAddress {
    utils::deploy(Receiver::TEST_CLASS_HASH, ArrayTrait::new())
}

fn NON_RECEIVER() -> ContractAddress {
    utils::deploy(NonReceiver::TEST_CLASS_HASH, ArrayTrait::new())
}

#[test]
#[available_gas(2000000)]
fn test_constructor() {
    Mock::constructor(NAME, SYMBOL);

    assert(Mock::name() == NAME, 'name is not set correctly');
    assert(Mock::symbol() == SYMBOL, 'symbol is not set correctly');
    assert(Mock::supports_interface(constants::IERC721_ID), 'missing interface ID');
    assert(Mock::supports_interface(constants::IERC721_METADATA_ID), 'missing interface ID');
}


#[test]
#[available_gas(2000000)]
fn test_token_uri() {
    let base_uri = vars::BASEURI();
    let token_id = vars::TOKEN_ID();
    Mock::set_base_uri(base_uri.clone());
    Mock::mint(vars::OWNER(), token_id);
    let data = Mock::token_uri(token_id);
    assert(data.len() == 4, 'base uri is not set correctly');
    assert(*data.at(0) == *base_uri[0], 'base uri is not set correctly');
    assert(*data.at(1) == *base_uri[1], 'base uri is not set correctly');
    assert(*data.at(2) == '2114', 'base uri is not set correctly');
    assert(*data.at(3) == '.json', 'base uri is not set correctly');
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721Metadata: invalid tokenId', ))]
fn test_token_uri_invalid_token_id() {
    Mock::token_uri(0_u256);
}

#[test]
#[available_gas(2000000)]
fn test_balance_of() {
    let owner = vars::OWNER();
    Mock::mint(owner, vars::TOKEN_ID());
    assert(Mock::balance_of(owner) == 1_u256, 'wrong balance');
}

#[test]
#[available_gas(2000000)]
fn test_owner_of() {
    let token_id = vars::TOKEN_ID();
    let owner = vars::OWNER();
    Mock::mint(owner, token_id);
    assert(Mock::owner_of(token_id) == owner, 'wrong owner');
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: invalid address', ))]
fn test_mint_invalid_address() {
    Mock::mint(vars::INVALID_ADDRESS(), 2114_u256);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: tokenId already exist', ))]
fn test_mint_existing_token() {
    let owner = vars::OWNER();
    let token_id = vars::TOKEN_ID();
    Mock::mint(owner, token_id);
    Mock::mint(owner, token_id);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: invalid tokenId', ))]
fn test_mint_invalid_token() {
    Mock::mint(vars::OWNER(), 0_u256);
}

#[test]
#[available_gas(2000000)]
fn test_approve() {
    let owner = vars::OWNER();
    let operator = vars::OPERATOR();
    let token_id = vars::TOKEN_ID();
    set_caller_address(owner);

    Mock::mint(owner, token_id);
    Mock::approve(operator, token_id);
    assert(Mock::get_approved(token_id) == operator, 'approved is not set correctly');
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: invalid owner', ))]
fn test_only_owner_approve() {
    let token_id = vars::TOKEN_ID();
    let owner = vars::OWNER();
    let user = vars::USER();

    set_caller_address(user);

    Mock::mint(owner, token_id);
    Mock::approve(user, token_id);
}


#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: owner cant approve self', ))]
fn test_approve_to_self() {
    let token_id = vars::TOKEN_ID();
    let owner = vars::OWNER();
    set_caller_address(owner);

    Mock::mint(owner, token_id);
    Mock::approve(owner, token_id);
}

#[test]
#[available_gas(2000000)]
fn test_approval_for_all() {
    let token_id = vars::TOKEN_ID();
    let owner = vars::OWNER();
    let operator = vars::OPERATOR();
    set_caller_address(owner);

    Mock::set_approval_for_all(operator, true);
    assert(Mock::is_approved_for_all(owner, operator), 'approval for all fail');
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: invalid address', ))]
fn test_approval_for_all_invalid_operator() {
    let owner = vars::OWNER();
    set_caller_address(owner);

    Mock::set_approval_for_all(vars::INVALID_ADDRESS(), true);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: invalid address', ))]
fn test_approval_for_all_invalid_caller() {
    set_caller_address(vars::INVALID_ADDRESS());

    Mock::set_approval_for_all(vars::OPERATOR(), true);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: owner cant approve self', ))]
fn test_approval_for_all_to_self() {
    let owner = vars::OWNER();
    set_caller_address(owner);
    Mock::set_approval_for_all(owner, true);
}

#[test]
#[available_gas(2000000)]
fn test_transfer() {
    let token_id = vars::TOKEN_ID();
    let owner = vars::OWNER();
    let operator = vars::OPERATOR();
    let user = vars::USER();

    Mock::mint(owner, token_id);

    set_caller_address(owner);
    Mock::approve(operator, token_id);
    Mock::transfer_from(owner, user, token_id);
    // test clear approvals
    assert(Mock::get_approved(token_id) == vars::INVALID_ADDRESS(), 'approvals not cleared');
    assert(Mock::balance_of(owner) == 0_u256, 'balance is not set correctly');
    assert(Mock::balance_of(user) == 1_u256, 'balance is not set correctly');
    assert(Mock::owner_of(token_id) == user, 'owner is not set correctly');
}

#[test]
#[available_gas(2000000)]
fn test_approve_transfer() {
    let token_id = vars::TOKEN_ID();
    let owner = vars::OWNER();
    let operator = vars::OPERATOR();

    set_caller_address(owner);
    // approve tokenId to account 2
    Mock::mint(owner, token_id);
    Mock::approve(operator, token_id);
    // set caller to account 2
    set_caller_address(operator);
    Mock::transfer_from(owner, operator, token_id);

    assert(Mock::balance_of(owner) == 0.into(), 'balance is not set correctly');
    assert(Mock::balance_of(operator) == 1.into(), 'balance is not set correctly');
    assert(Mock::owner_of(token_id) == operator, 'owner is not set correctly');
}

#[test]
#[available_gas(2000000)]
fn test_approval_for_all_transfer() {
    let token_id = vars::TOKEN_ID();
    let owner = vars::OWNER();
    let operator = vars::OPERATOR();

    set_caller_address(owner);
    // approve tokenId to account 2
    Mock::mint(owner, token_id);
    Mock::set_approval_for_all(operator, true);

    // set caller to account 2
    set_caller_address(operator);
    Mock::transfer_from(owner, operator, token_id);

    assert(Mock::balance_of(owner) == 0.into(), 'balance is not set correctly');
    assert(Mock::balance_of(operator) == 1.into(), 'balance is not set correctly');
    assert(Mock::owner_of(token_id) == operator, 'owner is not set correctly');
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: caller is not approved', ))]
fn test_unapproved_transfer() {
    let token_id = vars::TOKEN_ID();
    let owner = vars::OWNER();
    let user = vars::USER();

    Mock::mint(owner, token_id);
    set_caller_address(user);

    Mock::transfer_from(owner, user, token_id);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: invalid sender', ))]
fn test_invalid_from_transfer() {
    let token_id = vars::TOKEN_ID();
    let owner = vars::OWNER();
    let operator = vars::OPERATOR();
    let user = vars::USER();

    Mock::mint(owner, token_id);
    set_caller_address(owner);
    Mock::transfer_from(user, operator, token_id);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: invalid address', ))]
fn test_invalid_to_transfer() {
    let token_id = vars::TOKEN_ID();
    let owner = vars::OWNER();

    Mock::mint(owner, token_id);
    set_caller_address(owner);
    Mock::transfer_from(owner, vars::INVALID_ADDRESS(), token_id);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: invalid tokenId', ))]
fn test_invalid_token_transfer() {
    let owner = vars::OWNER();
    let user = vars::USER();
    set_caller_address(owner);
    Mock::transfer_from(owner, user, 0_u256);
}

#[test]
#[available_gas(2000000)]
fn test_safe_transfer() {
    let token_id = vars::TOKEN_ID();
    let owner = vars::OWNER();
    let receiver = RECEIVER();

    Mock::mint(owner, token_id);
    set_caller_address(owner);
    Mock::safe_transfer_from(owner, receiver, token_id, DATA(true));

    assert(Mock::balance_of(owner) == 0_u256, 'balance is not set correctly');
    assert(Mock::balance_of(receiver) == 1_u256, 'balance is not set correctly');
    assert(Mock::owner_of(token_id) == receiver, 'owner is not set correctly');
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: reciever failed', ))]
fn test_safe_transfer_receiver_fail() {
    let token_id = vars::TOKEN_ID();
    let owner = vars::OWNER();
    let receiver = RECEIVER();

    Mock::mint(owner, token_id);
    set_caller_address(owner);
    Mock::safe_transfer_from(owner, receiver, token_id, DATA(false));
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ENTRYPOINT_NOT_FOUND', ))]
fn test_safe_transfer_non_receiver() {
    let token_id = vars::TOKEN_ID();
    let owner = vars::OWNER();
    let non_receiver = NON_RECEIVER();
    Mock::mint(owner, token_id);
    set_caller_address(owner);
    Mock::safe_transfer_from(owner, non_receiver, token_id, DATA(true));
}

#[test]
#[available_gas(2000000)]
fn test_safe_mint() {
    let token_id = vars::TOKEN_ID();
    let receiver = RECEIVER();

    set_caller_address(receiver);
    Mock::safe_mint(receiver, token_id, DATA(true));

    assert(Mock::balance_of(receiver) == 1_u256, 'balance is not set correctly');
    assert(Mock::owner_of(token_id) == receiver, 'owner is not set correctly');
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: reciever failed', ))]
fn test_safe_mint_receiver_fail() {
    let token_id = vars::TOKEN_ID();
    let receiver = RECEIVER();

    set_caller_address(receiver);
    Mock::safe_mint(receiver, token_id, DATA(false));
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ENTRYPOINT_NOT_FOUND', ))]
fn safe_mint_non_receiver() {
    let token_id = vars::TOKEN_ID();
    let non_receiver = NON_RECEIVER();

    set_caller_address(non_receiver);
    Mock::safe_mint(non_receiver, token_id, DATA(true));
}

#[test]
#[available_gas(2000000)]
fn test_burn() {
    let token_id = vars::TOKEN_ID();
    let owner = vars::OWNER();
    set_caller_address(owner);
    Mock::mint(owner, token_id);
    Mock::burn(token_id);
    assert(Mock::balance_of(owner) == 0_u256, 'balance is not set correctly');
}

