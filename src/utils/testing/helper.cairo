use array::ArrayTrait;
use starknet::ContractAddress;
use starknet::class_hash::Felt252TryIntoClassHash;
use core::result::ResultTrait;
use option::OptionTrait;
use traits::TryInto;

fn deploy(class_hash: felt252, calldata: Array<felt252>) -> ContractAddress {
    let (address, _) = starknet::deploy_syscall(
        class_hash.try_into().unwrap(), 0, calldata.span(), false
    )
        .unwrap();
    address
}
