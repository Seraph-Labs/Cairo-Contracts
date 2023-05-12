use starknet::ContractAddress;
use array::ArrayTrait;

#[abi]
trait IERC721 {
    fn balance_of(owner: ContractAddress) -> u256;
    fn owner_of(token_id: u256) -> ContractAddress;
    fn get_approved(token_id: u256) -> ContractAddress;
    fn is_approved_for_all(owner: ContractAddress, operator: ContractAddress) -> bool;
    fn approve(approved: ContractAddress, token_id: u256);
    fn set_approval_for_all(operator: ContractAddress, approved: bool);
    fn safe_transfer_from(
        from: ContractAddress, to: ContractAddress, token_id: u256, data: Array<felt252>
    );
    fn transfer_from(from: ContractAddress, to: ContractAddress, token_id: u256);
}

#[abi]
trait IERC721MetaData {
    fn name() -> felt252;
    fn symbol() -> felt252;
    fn token_uri(token_id: u256) -> Array<felt252>;
}

#[abi]
trait IERC721Receiver {
    fn on_erc721_received(
        operator: ContractAddress, from: ContractAddress, token_id: u256, data: Array<felt252>
    ) -> u32;
}

#[abi]
trait IERC721Enumerable {
    fn total_supply() -> u256;
    fn token_by_index(index: u256) -> u256;
    fn token_of_owner_by_index(owner: ContractAddress, index: u256) -> u256;
}
