use seraphlabs_tokens::tests::mocks::Mock721Contract as Mock;
use starknet::{ContractAddress, contract_address_const};
use starknet::testing::set_caller_address;
use traits::{Into,TryInto};
use option::OptionTrait;
use array::ArrayTrait;

const NAME : felt252 = 'hello';
const SYMBOL : felt252 = 'world';
const BASEURI1 : felt252 = 'arweave.net/';
const BASEURI2 : felt252 = 'FAKE_EXAMPLE_OF_ARWEAVE_HASH/';


fn setup() -> ContractAddress{
    let account = contract_address_const::<1>();
    Mock::constructor(NAME, SYMBOL);
    account
}

fn set_caller_as_zero() {
    set_caller_address(contract_address_const::<0>());
}

#[test]
#[available_gas(2000000)]
fn test_constructor(){
    Mock::constructor(NAME, SYMBOL);

    assert(Mock::name() == NAME, 'name is not set correctly');
    assert(Mock::symbol() == SYMBOL, 'symbol is not set correctly');
}


#[test]
#[available_gas(2000000)]
fn test_token_uri(){
    let mut base_uri = ArrayTrait::<felt252>::new();
    base_uri.append(BASEURI1);
    base_uri.append(BASEURI2);
    Mock::set_base_uri(base_uri);
    let data = Mock::token_uri(2114.into());
    assert(data.len() == 4, 'base uri is not set correctly');
    assert(*data.at(0) == BASEURI1, 'base uri is not set correctly');
    assert(*data.at(1) == BASEURI2, 'base uri is not set correctly');
    assert(*data.at(2) == '2114', 'base uri is not set correctly');
    assert(*data.at(3) == '.json', 'base uri is not set correctly');
}

#[test]
#[available_gas(2000000)]
fn test_mint(){
    let account = setup();
    Mock::mint(account, 1.into());
    assert(Mock::balance_of(account) == 1.into(), 'balance is not set correctly');
    assert(Mock::owner_of(1.into()) == account, 'owner is not set correctly');
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: invalid address', ))]
fn test_mint_invalid_address(){
    Mock::mint(contract_address_const::<0>(), 1.into());
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: tokenId already exist', ))]
fn test_mint_existing_token(){
    let account = setup();
    Mock::mint(account, 1.into());
    assert(Mock::balance_of(account) == 1.into(), 'balance is not set correctly');
    assert(Mock::owner_of(1.into()) == account, 'owner is not set correctly');
    Mock::mint(account, 1.into());
}

#[test]
#[available_gas(2000000)]
fn test_approve(){
    let account = setup();
    set_caller_address(account);
    let account2 = contract_address_const::<2>();

    Mock::mint(account, 1.into());
    Mock::approve(account2, 1.into());
    assert(Mock::get_approved(1.into()) == account2, 'approved is not set correctly');
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: invalid owner', ))]
fn test_only_owner_approve(){
    let account = setup();
    let account2 = contract_address_const::<2>();
    set_caller_address(account);
    // account 2 mint tokenId 1
    Mock::mint(account2, 1.into());
    // try to approve itself as if it was the owner
    Mock::approve(account, 1.into());
}


#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: owner cant approve self', ))]
fn test_approve_to_self(){
    let account = setup();
    set_caller_address(account);

    Mock::mint(account, 1.into());
    Mock::approve(account, 1.into());
}

#[test]
#[available_gas(2000000)]
fn test_approval_for_all(){
    let account = setup();
    let account2 = contract_address_const::<2>();
    set_caller_address(account);

    Mock::mint(account, 1.into());
    Mock::set_approval_for_all(account2, true);
    assert(Mock::is_approved_for_all(account, account2), 'approval for all fail');
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: invalid address', ))]
fn test_approval_for_all_invalid_operator(){
    let account =contract_address_const::<1>();
    set_caller_address(account);

    Mock::mint(account, 1.into());
    Mock::set_approval_for_all(contract_address_const::<0>(), true);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: invalid address', ))]
fn test_approval_for_all_invalid_caller(){
    let account = contract_address_const::<1>();
    let account2 = contract_address_const::<2>();
    set_caller_as_zero();

    Mock::mint(account, 1.into());
    Mock::set_approval_for_all(account2, true);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: owner cant approve self', ))]
fn test_approval_for_all_to_self(){
    let account = contract_address_const::<1>();
    set_caller_address(account);

    Mock::mint(account, 1.into());
    Mock::set_approval_for_all(account, true);
}

#[test]
#[available_gas(2000000)]
fn test_transfer(){
    let account = setup();
    set_caller_address(account);
    let account2 = contract_address_const::<2>();

    Mock::mint(account, 1.into());
    Mock::approve(account2, 1.into());
    assert(Mock::get_approved(1.into()) == account2, 'approved is not set correctly');

    Mock::transfer_from(account, account2, 1.into());
    // test clear approvals
    assert(Mock::get_approved(1.into()) == contract_address_const::<0>(), 'approvals nit cleared');
    assert(Mock::balance_of(account) == 0.into(), 'balance is not set correctly');
    assert(Mock::balance_of(account2) == 1.into(), 'balance is not set correctly');
    assert(Mock::owner_of(1.into()) == account2, 'owner is not set correctly');
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: caller is not approved', ))]
fn test_unapproved_transfer(){
    let account = contract_address_const::<1>();
    let account2 = contract_address_const::<2>();
    set_caller_address(account2);

    Mock::mint(account, 1.into());
    Mock::transfer_from(account, account2, 1.into());
}

#[test]
#[available_gas(2000000)]
fn test_approve_transfer(){
    let account = contract_address_const::<1>();
    set_caller_address(account);
    let account2 = contract_address_const::<2>();
    // approve tokenId to account 2
    Mock::mint(account, 1.into());
    Mock::approve(account2, 1.into());
    // set caller to account 2
    set_caller_address(account2);
    Mock::transfer_from(account, account2, 1.into());

    assert(Mock::balance_of(account) == 0.into(), 'balance is not set correctly');
    assert(Mock::balance_of(account2) == 1.into(), 'balance is not set correctly');
    assert(Mock::owner_of(1.into()) == account2, 'owner is not set correctly');
}

#[test]
#[available_gas(2000000)]
fn test_approval_for_all_transfer(){
    let account =contract_address_const::<1>();
    set_caller_address(account);
    let account2 = contract_address_const::<2>();
    // approve tokenId to account 2
    Mock::mint(account, 1.into());
    Mock::set_approval_for_all(account2, true);

    // set caller to account 2
    set_caller_address(account2);
    Mock::transfer_from(account, account2, 1.into());

    assert(Mock::balance_of(account) == 0.into(), 'balance is not set correctly');
    assert(Mock::balance_of(account2) == 1.into(), 'balance is not set correctly');
    assert(Mock::owner_of(1.into()) == account2, 'owner is not set correctly');
}

#[test]
#[available_gas(2000000)]
fn test_burn(){
    let account = contract_address_const::<1>();
    set_caller_address(account);
    Mock::mint(account, 1.into());
    Mock::burn(1.into());
    assert(Mock::balance_of(account) == 0.into(), 'balance is not set correctly');
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: invalid tokenId', ))]
fn test_burn_approve(){
    let account = contract_address_const::<1>();
    set_caller_address(account);
    Mock::mint(account, 1.into());
    Mock::burn(1.into());
    let account2 = contract_address_const::<2>();
    Mock::approve(account2, 1.into());
}