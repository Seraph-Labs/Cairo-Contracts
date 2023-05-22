use seraphlabs_tokens::tests::mocks::Mock721EnumContract as Mock;
use starknet::{ContractAddress, contract_address_const};
use starknet::testing::set_caller_address;
use traits::{Into,TryInto};
use option::OptionTrait;
use array::ArrayTrait;


const NAME : felt252 = 'hello';
const SYMBOL : felt252 = 'world';

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
fn test_mint(){
    let account = setup();
    Mock::mint(account, 1.into());
    assert(Mock::balance_of(account) == 1.into(), 'balance is not set correctly');
    assert(Mock::owner_of(1.into()) == account, 'owner is not set correctly');
    assert(Mock::total_supply() == 1.into(),'total supply failed');
    assert(Mock::token_by_index(0.into()) == 1.into(),'token by index failed');
    assert(Mock::token_of_owner_by_index(account,0.into()) == 1.into(),'token by owner index failed');
}

#[test]
#[available_gas(20000000)]
fn test_total_enum(){
    let account = contract_address_const::<1>();
    Mock::mint(account, 1.into());
    Mock::mint(account, 2.into());
    Mock::mint(account, 3.into());
    Mock::mint(account, 4.into());
    Mock::mint(account, 5.into());
    assert(Mock::total_supply() == 5.into(),'total supply failed');
    assert(Mock::token_by_index(0.into()) == 1.into(),'token by index failed');
    assert(Mock::token_by_index(4.into()) == 5.into(),'token by index failed');

    Mock::burn(2.into());
    Mock::burn(4.into());
    assert(Mock::total_supply() == 3.into(),'total supply failed');
    assert(Mock::token_by_index(0.into()) == 1.into(),'token by index failed');
    assert(Mock::token_by_index(1.into()) == 5.into(),'token by index failed');
    assert(Mock::token_by_index(2.into()) == 3.into(),'token by index failed');
}

#[test]
#[available_gas(20000000)]
fn test_owner_enum(){
    let account = contract_address_const::<1>();
    Mock::mint(account, 1.into());
    Mock::mint(account, 2.into());
    Mock::mint(account, 3.into());
    Mock::mint(account, 4.into());
    Mock::mint(account, 5.into());

    set_caller_address(account);
    let account2 = contract_address_const::<2>();
    Mock::transfer_from(account, account2, 2.into());
    Mock::transfer_from(account, account2, 4.into());
    assert(Mock::balance_of(account) == 3.into(), 'balance is not set correctly');
    assert(Mock::balance_of(account2) == 2.into(), 'balance is not set correctly');
    assert(Mock::token_of_owner_by_index(account,0.into()) == 1.into(),'token by owner index failed');
    assert(Mock::token_of_owner_by_index(account,1.into()) == 5.into(),'token by owner index failed');
    assert(Mock::token_of_owner_by_index(account,2.into()) == 3.into(),'token by owner index failed');
    assert(Mock::token_of_owner_by_index(account2,0.into()) == 2.into(),'token by owner index failed');
    assert(Mock::token_of_owner_by_index(account2,1.into()) == 4.into(),'token by owner index failed');
}