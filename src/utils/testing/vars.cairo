use starknet::{ContractAddress, contract_address_const};
use array::ArrayTrait;
use zeroable::Zeroable;

fn TOKEN_ID() -> u256 {
    2114_u256
}

fn BASEURI() -> Array<felt252> {
    let mut base_uri = ArrayTrait::<felt252>::new();
    base_uri.append('arweave.net/');
    base_uri.append('FAKE_EXAMPLE_OF_ARWEAVE_HASH/');
    base_uri
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
    contract_address_const::<0>()
}
