use starknet::ContractAddress;
use array::ArrayTrait;

#[abi]
trait IERC3525 {
    fn value_decimals() -> u8;
    fn value_of(token_id: u256) -> u256;
    fn slot_of(token_id: u256) -> u256;
    fn approve_value(token_id: u256, operator: ContractAddress, value: u256);
    fn allowance(token_id: u256, operator: ContractAddress) -> u256;
    fn transfer_value_from(from_token_id: u256, to: ContractAddress, value: u256) -> u256;
// transfer_value_from(from_token_id : u256, to_token_id : u256, value : u256);
}

#[abi]
trait IERC3525SlotEnumerable {
    fn slot_count() -> u256;
    fn slot_by_index(index: u256) -> u256;
    fn token_supply_in_slot(slot: u256) -> u256;
    fn token_in_slot_by_index(slot: u256, index: u256) -> u256;
}

#[abi]
trait IERC3525SlotApprovable {
    fn set_approval_for_slot(
        owner: ContractAddress, slot: u256, operator: ContractAddress, approved: bool
    );
    fn is_approved_for_slot(owner: ContractAddress, slot: u256, operator: ContractAddress) -> bool;
}

#[abi]
trait IERC3525MetaData {
    fn contract_uri() -> Array<felt252>;
    fn slot_uri(slot: u256) -> Array<felt252>;
}

#[abi]
trait IERC3525Receiver {
    fn on_erc3525_received(
        operator: ContractAddress,
        from_token_id: u256,
        to_token_id: u256,
        value: u256,
        data: Array<felt252>
    ) -> u32;
}
