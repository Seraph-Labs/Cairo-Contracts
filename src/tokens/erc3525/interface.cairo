use starknet::ContractAddress;
use array::{ArrayTrait, SpanTrait, SpanSerde};

#[starknet::interface]
trait IERC3525<TContractState> {
    fn value_decimals(self: @TContractState) -> u8;
    fn value_of(self: @TContractState, token_id: u256) -> u256;
    fn slot_of(self: @TContractState, token_id: u256) -> u256;
    fn approve_value(
        ref self: TContractState, token_id: u256, operator: ContractAddress, value: u256
    );
    fn allowance(self: @TContractState, token_id: u256, operator: ContractAddress) -> u256;
    fn transfer_value_from(
        ref self: TContractState, from_token_id: u256, to: ContractAddress, value: u256
    ) -> u256;
// transfer_value_from(from_token_id : u256, to_token_id : u256, value : u256);
}

#[starknet::interface]
trait IERC3525SlotEnumerable<TContractState> {
    fn slot_count(self: @TContractState) -> u256;
    fn slot_by_index(self: @TContractState, index: u256) -> u256;
    fn token_supply_in_slot(self: @TContractState, slot: u256) -> u256;
    fn token_in_slot_by_index(self: @TContractState, slot: u256, index: u256) -> u256;
}

#[starknet::interface]
trait IERC3525SlotApprovable<TContractState> {
    fn set_approval_for_slot(
        ref self: TContractState,
        owner: ContractAddress,
        slot: u256,
        operator: ContractAddress,
        approved: bool
    );
    fn is_approved_for_slot(
        self: @TContractState, owner: ContractAddress, slot: u256, operator: ContractAddress
    ) -> bool;
}

#[starknet::interface]
trait IERC3525MetaData<TContractState> {
    fn contract_uri(self: @TContractState) -> Array<felt252>;
    fn slot_uri(self: @TContractState, slot: u256) -> Array<felt252>;
}

#[starknet::interface]
trait IERC3525Receiver<TContractState> {
    fn on_erc3525_received(
        self: @TContractState,
        operator: ContractAddress,
        from_token_id: u256,
        to_token_id: u256,
        value: u256,
        data: Span<felt252>
    ) -> felt252;
}
