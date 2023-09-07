// SPDX-License-Identifier: AGPL-3.0
// SeraphLabs Contracts for Cairo >=v2.2.0 (tokens/erc2114/extensions/traitcatalog.cairo)
#[starknet::contract]
mod TraitCatalog {
    use core::zeroable::Zeroable;
    use seraphlabs::tokens::constants;
    use seraphlabs::tokens::erc2114::interface;
    use seraphlabs::tokens::src5::{SRC5, interface::{ISRC5Dispatcher, ISRC5DispatcherTrait}};
    // corelib imports
    use starknet::ContractAddress;

    #[storage]
    struct Storage {
        trait_list_counter: u64,
        trait_list_size: LegacyMap<u64, felt252>,
        index_to_trait_list_value: LegacyMap<(u64, felt252), felt252>,
    }

    #[event]
    #[derive(Drop, PartialEq, starknet::Event)]
    enum Event {
        TraitListUpdate: TraitListUpdate,
    }

    #[derive(Drop, PartialEq, starknet::Event)]
    struct TraitListUpdate {
        #[key]
        list_id: u64,
        #[key]
        index: felt252,
        #[key]
        old_value: felt252,
        #[key]
        new_value: felt252
    }

    #[external(v0)]
    impl ITraitCatalogImpl of interface::ITraitCatalog<ContractState> {
        fn trait_list_count(self: @ContractState) -> u64 {
            self.trait_list_counter.read()
        }

        fn trait_list_length(self: @ContractState, list_id: u64) -> felt252 {
            self.trait_list_size.read(list_id)
        }

        fn trait_list_value_by_index(
            self: @ContractState, list_id: u64, index: felt252
        ) -> felt252 {
            self.index_to_trait_list_value.read((list_id, index))
        }

        fn generate_trait_list(ref self: ContractState, values: Span<felt252>) -> u64 {
            // assert values length is not zero
            assert(values.len().is_non_zero(), 'TraitCatalog: invalid values');
            // increase trait list count
            self._increase_trait_list_count();
            let list_id = self.trait_list_counter.read();
            // emits events, increases length, updates values and checks validity of value
            self._append_batch_to_trait_list(list_id, values);
            list_id
        }

        fn append_to_trait_list(ref self: ContractState, list_id: u64, value: felt252) {
            // assert trait list validity
            self._assert_trait_list_exists(list_id);
            let cur_len = self.trait_list_size.read(list_id);
            // emits events and cheecks validity of value
            self._update_trait_list(list_id, cur_len + 1, value);
            // increase trait list length
            self.trait_list_size.write(list_id, cur_len + 1);
        }

        fn append_batch_to_trait_list(
            ref self: ContractState, list_id: u64, values: Span<felt252>
        ) {
            // assert trait list validity
            self._assert_trait_list_exists(list_id);
            // assert values length is not zero
            assert(values.len().is_non_zero(), 'TraitCatalog: invalid values');
            // emits events, increases length, updates values and checks validity of value
            self._append_batch_to_trait_list(list_id, values);
        }

        fn ammend_trait_list(
            ref self: ContractState, list_id: u64, index: felt252, value: felt252
        ) {
            // assert trait list validity
            self._assert_trait_list_exists(list_id);
            // assert index is not out of bounds
            let cur_len: u256 = self.trait_list_size.read(list_id).into();
            assert(index.into() <= cur_len, 'TraitCatalog: index exceeded');
            // emits events and cheecks validity of value and ensures index is non_zero
            self._update_trait_list(list_id, index, value);
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn initializer(ref self: ContractState) {
            let mut unsafe_state = SRC5::unsafe_new_contract_state();
            SRC5::InternalImpl::register_interface(ref unsafe_state, constants::ITRAIT_CATALOG_ID);
        }

        // @dev append a batch of values to trait list
        //  DOES NOT check validity of list_id
        //  increases length of trait list
        fn _append_batch_to_trait_list(
            ref self: ContractState, list_id: u64, mut values: Span<felt252>
        ) {
            let mut cur_len = self.trait_list_size.read(list_id);
            loop {
                match values.pop_front() {
                    Option::Some(value) => {
                        cur_len += 1;
                        self._update_trait_list(list_id, cur_len, *value);
                    },
                    Option::None(_) => {
                        break;
                    }
                };
            };
            self.trait_list_size.write(list_id, cur_len);
        }
    }

    #[generate_trait]
    impl PrivateImpl of PrivateTrait {
        fn _assert_trait_list_exists(self: @ContractState, list_id: u64) {
            assert(
                list_id > 0 && list_id <= self.trait_list_counter.read(),
                'TraitCatalog: invalid list id'
            );
        }

        fn _increase_trait_list_count(ref self: ContractState) {
            self.trait_list_counter.write(self.trait_list_counter.read() + 1);
        }

        // @dev updates trait list value at index
        //  EMITS TraitListUpdate
        //  DOES NOT check validity of list_id
        //  DOES NOT check validity of index in relation to trait_list length
        //  checks validity of value and if index is non_zero
        fn _update_trait_list(
            ref self: ContractState, list_id: u64, index: felt252, value: felt252
        ) {
            // assert index and value is not zero
            assert(index.is_non_zero() && value.is_non_zero(), 'TraitCatalog: invalid update');

            // if old_value == current value return
            let old_value = self.index_to_trait_list_value.read((list_id, index));
            if old_value == value {
                return;
            }
            // update index_to_trait_list_value
            self.index_to_trait_list_value.write((list_id, index), value);
            //emit event
            self.emit(TraitListUpdate { list_id, index, old_value, new_value: value });
        }
    }
}
