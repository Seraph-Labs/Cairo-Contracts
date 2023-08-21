// SPDX-License-Identifier: AGPL-3.0
// SeraphLabs Contracts for Cairo >=v2.1.0 (tokens/erc2114/interface.cairo)
use seraphlabs::tokens::erc2114::utils::AttrType;
use starknet::ContractAddress;
use array::{ArrayTrait, SpanTrait, SpanSerde};

#[starknet::interface]
trait IERC2114<TContractState> {
    fn get_trait_catalog(self: @TContractState) -> ContractAddress;

    fn token_balance_of(self: @TContractState, token_id: u256) -> u256;

    fn token_of(self: @TContractState, token_id: u256) -> u256;

    fn token_of_token_by_index(self: @TContractState, token_id: u256, index: u256) -> u256;

    fn attribute_name(self: @TContractState, attr_id: u64) -> felt252;

    fn attribute_type(self: @TContractState, attr_id: u64) -> AttrType;

    fn attribute_value(self: @TContractState, token_id: u256, attr_id: u64) -> felt252;

    fn attributes_of(self: @TContractState, token_id: u256) -> Span<u64>;

    fn scalar_transfer_from(
        ref self: TContractState, from: ContractAddress, token_id: u256, to_token_id: u256
    );

    fn scalar_remove_from(ref self: TContractState, from_token_id: u256, token_id: u256);

    fn create_attribute(ref self: TContractState, attr_id: u64, attr_type: AttrType, name: felt252);
}

#[starknet::interface]
trait ITraitCatalog<TContractState> {
    fn trait_list_count(self: @TContractState) -> u64;

    fn trait_list_length(self: @TContractState, list_id: u64) -> felt252;

    fn trait_list_value_by_index(self: @TContractState, list_id: u64, index: felt252) -> felt252;

    fn generate_trait_list(ref self: TContractState, values: Span<felt252>) -> u64;

    fn append_to_trait_list(ref self: TContractState, list_id: u64, value: felt252);

    fn append_batch_to_trait_list(ref self: TContractState, list_id: u64, values: Span<felt252>);

    fn ammend_trait_list(ref self: TContractState, list_id: u64, index: felt252, value: felt252);
}

#[starknet::interface]
trait IERC2114SlotAttribute<TContractState> {
    fn slot_attribute_value(self: @TContractState, slot_id: u256, attr_id: u64) -> felt252;

    fn slot_attributes_of(self: @TContractState, slot_id: u256) -> Span<u64>;

    fn set_slot_attribute(ref self: TContractState, slot_id: u256, attr_id: u64, value: felt252);

    fn batch_set_slot_attribute(
        ref self: TContractState, slot_id: u256, attr_ids: Span<u64>, values: Span<felt252>
    );
}
