use starknet::ContractAddress;

#[abi]
trait IERC721{
    fn name() -> felt252;
    fn symbol() -> felt252;
    fn balance_of(owner : ContractAddress) -> u256;
    fn owner_of(tokenId : u256) -> ContractAddress;
    fn get_approved(tokenId : u256) -> ContractAddress;
    fn is_approved_for_all(owner : ContractAddress, operator : ContractAddress) -> bool;
    fn safe_transfer_from(from : ContractAddress, to : ContractAddress, tokenId : u256, data: Array::<felt252>);
    fn transfer_from(from : ContractAddress, to : ContractAddress, tokenId: u256);
    fn approve(approved : ContractAddress, tokenId : u256);
    fn set_approval_for_all(operator : ContractAddress, approved : bool);
}