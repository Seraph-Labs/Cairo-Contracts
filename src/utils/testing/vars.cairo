use starknet::{ContractAddress, contract_address_const};
use array::ArrayTrait;
use zeroable::Zeroable;

#[inline(always)]
fn TOKEN_ID() -> u256 {
    2114_u256
}

#[inline(always)]
fn BASEURI() -> Array<felt252> {
    let mut base_uri = ArrayTrait::<felt252>::new();
    base_uri.append('arweave.net/');
    base_uri.append('FAKE_EXAMPLE_OF_ARWEAVE_HASH/');
    base_uri
}

#[inline(always)]
fn ADMIN() -> ContractAddress {
    contract_address_const::<'admin'>()
}

#[inline(always)]
fn OWNER() -> ContractAddress {
    contract_address_const::<2114>()
}

#[inline(always)]
fn USER() -> ContractAddress {
    contract_address_const::<3525>()
}

#[inline(always)]
fn OPERATOR() -> ContractAddress {
    contract_address_const::<721>()
}

#[inline(always)]
fn INVALID_ADDRESS() -> ContractAddress {
    contract_address_const::<0>()
}
