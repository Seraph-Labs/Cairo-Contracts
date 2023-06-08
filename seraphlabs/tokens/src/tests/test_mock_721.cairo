use core::clone::Clone;
use seraphlabs_tokens::tests::mocks::{Mock721Contract as Mock, ERC721Receiver as Receiver};
use seraphlabs_tokens::utils::constants;
use starknet::{ContractAddress, contract_address_const};
use starknet::testing::set_caller_address;
use starknet::class_hash::Felt252TryIntoClassHash;
use traits::{Into, TryInto};
use option::OptionTrait;
use array::ArrayTrait;
use core::result::ResultTrait;

const NAME: felt252 = 'hello';
const SYMBOL: felt252 = 'world';

fn TOKEN_ID() -> u256 {
    2114_u256
}

fn BASEURI() -> Array<felt252> {
    let mut base_uri = ArrayTrait::<felt252>::new();
    base_uri.append('arweave.net/');
    base_uri.append('FAKE_EXAMPLE_OF_ARWEAVE_HASH/');
    base_uri
}

fn DATA(valid : bool) -> Span<felt252>{
    let mut data = ArrayTrait::<felt252>::new();
    match valid {
        bool::False(()) => data.append('fail'),
        bool::True(()) => data.append('pass'),
    }
    data.span()
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
    Mock::constructor(NAME, SYMBOL);

    assert(Mock::name() == NAME, 'name is not set correctly');
    assert(Mock::symbol() == SYMBOL, 'symbol is not set correctly');
    assert(Mock::supports_interface(constants::IERC721_ID), 'missing interface ID');
    assert(Mock::supports_interface(constants::IERC721_METADATA_ID), 'missing interface ID');
}


#[test]
#[available_gas(2000000)]
fn test_token_uri() {
    let base_uri = BASEURI();
    let token_id = TOKEN_ID();
    Mock::set_base_uri(base_uri.clone());
    Mock::mint(OWNER(), token_id);
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
    let owner = OWNER();
    Mock::mint(owner, TOKEN_ID());
    assert(Mock::balance_of(owner) == 1_u256, 'wrong balance');
}

#[test]
#[available_gas(2000000)]
fn test_owner_of() {
    let token_id = TOKEN_ID();
    let owner = OWNER();
    Mock::mint(owner, token_id);
    assert(Mock::owner_of(token_id) == owner, 'wrong owner');
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: invalid address', ))]
fn test_mint_invalid_address() {
    Mock::mint(INVALID_ADDRESS(), 2114_u256);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: tokenId already exist', ))]
fn test_mint_existing_token() {
    let owner = OWNER();
    let token_id = TOKEN_ID();
    Mock::mint(owner, token_id);
    Mock::mint(owner, token_id);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: invalid tokenId', ))]
fn test_mint_invalid_token() {
    Mock::mint(OWNER(), 0_u256);
}

#[test]
#[available_gas(2000000)]
fn test_approve() {
    let owner = OWNER();
    let operator = OPERATOR();
    let token_id = TOKEN_ID();
    set_caller_address(owner);

    Mock::mint(owner, token_id);
    Mock::approve(operator, token_id);
    assert(Mock::get_approved(token_id) == operator, 'approved is not set correctly');
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: invalid owner', ))]
fn test_only_owner_approve() {
    let token_id = TOKEN_ID();
    let owner = OWNER();
    let user = USER();

    set_caller_address(user);

    Mock::mint(owner, token_id);
    Mock::approve(user, token_id);
}


#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: owner cant approve self', ))]
fn test_approve_to_self() {
    let token_id = TOKEN_ID();
    let owner = OWNER();
    set_caller_address(owner);

    Mock::mint(owner, token_id);
    Mock::approve(owner, token_id);
}

#[test]
#[available_gas(2000000)]
fn test_approval_for_all() {
    let token_id = TOKEN_ID();
    let owner = OWNER();
    let operator = OPERATOR();
    set_caller_address(owner);

    Mock::set_approval_for_all(operator, true);
    assert(Mock::is_approved_for_all(owner, operator), 'approval for all fail');
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: invalid address', ))]
fn test_approval_for_all_invalid_operator() {
    let owner = OWNER();
    set_caller_address(owner);

    Mock::set_approval_for_all(INVALID_ADDRESS(), true);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: invalid address', ))]
fn test_approval_for_all_invalid_caller() {
    set_caller_address(INVALID_ADDRESS());

    Mock::set_approval_for_all(OPERATOR(), true);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: owner cant approve self', ))]
fn test_approval_for_all_to_self() {
    let owner = OWNER();
    set_caller_address(owner);
    Mock::set_approval_for_all(owner, true);
}

#[test]
#[available_gas(2000000)]
fn test_transfer() {
    let token_id = TOKEN_ID();
    let owner = OWNER();
    let operator = OPERATOR();
    let user = USER();

    Mock::mint(owner, token_id);

    set_caller_address(owner);
    Mock::approve(operator, token_id);
    Mock::transfer_from(owner, user, token_id);
    // test clear approvals
    assert(Mock::get_approved(token_id) == INVALID_ADDRESS(), 'approvals not cleared');
    assert(Mock::balance_of(owner) == 0_u256, 'balance is not set correctly');
    assert(Mock::balance_of(user) == 1_u256, 'balance is not set correctly');
    assert(Mock::owner_of(token_id) == user, 'owner is not set correctly');
}

#[test]
#[available_gas(2000000)]
fn test_approve_transfer() {
    let token_id = TOKEN_ID();
    let owner = OWNER();
    let operator = OPERATOR();

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
    let token_id = TOKEN_ID();
    let owner = OWNER();
    let operator = OPERATOR();

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
    let token_id = TOKEN_ID();
    let owner = OWNER();
    let user = USER();

    Mock::mint(owner, token_id);
    set_caller_address(user);

    Mock::transfer_from(owner, user, token_id);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: invalid sender', ))]
fn test_invalid_from_transfer() {
    let token_id = TOKEN_ID();
    let owner = OWNER();
    let operator = OPERATOR();
    let user = USER();

    Mock::mint(owner, token_id);
    set_caller_address(owner);
    Mock::transfer_from(user, operator, token_id);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: invalid address', ))]
fn test_invalid_to_transfer() {
    let token_id = TOKEN_ID();
    let owner = OWNER();

    Mock::mint(owner, token_id);
    set_caller_address(owner);
    Mock::transfer_from(owner, INVALID_ADDRESS(), token_id);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: invalid tokenId', ))]
fn test_invalid_token_transfer() {
    let owner = OWNER();
    let user = USER();
    set_caller_address(owner);
    Mock::transfer_from(owner, user, 0_u256);
}

#[test]
#[available_gas(2000000)]
fn test_burn() {
    let token_id = TOKEN_ID();
    let owner = OWNER();
    set_caller_address(owner);
    Mock::mint(owner, token_id);
    Mock::burn(token_id);
    assert(Mock::balance_of(owner) == 0_u256, 'balance is not set correctly');
}

