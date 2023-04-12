
use starknet::ContractAddress;
use array::ArrayTrait;

#[abi]
trait IERC721{
    fn balance_of(owner : ContractAddress) -> u256;
    fn owner_of(tokenId : u256) -> ContractAddress;
    fn get_approved(tokenId : u256) -> ContractAddress;
    fn is_approved_for_all(owner : ContractAddress, operator : ContractAddress) -> bool;
    fn approve(approved : ContractAddress, tokenId : u256);
    fn set_approval_for_all(operator : ContractAddress, approved : bool);
    fn safe_transfer_from(from : ContractAddress, to : ContractAddress, tokenId : u256, data: Array::<felt252>);
    fn transfer_from(from : ContractAddress, to : ContractAddress, tokenId: u256);
}

#[abi]
trait IERC721MetaData{
    fn name() -> felt252;
    fn symbol() -> felt252;
    //TODO implement tokenuri function
}

#[abi]
trait IERC721Receiver {
    fn on_erc721_received(
        operator: ContractAddress, from: ContractAddress, tokenId: u256, data: Array<felt252>
    ) -> u32;
}

#[abi]
trait IERC721Enumerable{
    fn total_supply() -> u256;
    fn token_by_index(index : u256) -> u256;
    fn token_of_owner_by_index(owner : felt252, index : u256) -> u256;
}