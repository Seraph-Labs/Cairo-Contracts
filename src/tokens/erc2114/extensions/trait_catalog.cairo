// SPDX-License-Identifier: AGPL-3.0
// SeraphLabs Contracts for Cairo >=v2.3.0-rc0 (tokens/erc2114/extensions/trait_catalog.cairo)
#[starknet::component]
mod TraitCatalogComponent {
    use seraphlabs::tokens::constants;
    use seraphlabs::tokens::erc2114::interface;
    use seraphlabs::tokens::src5::{
        SRC5Component, interface::{ISRC5Dispatcher, ISRC5DispatcherTrait}
    };
    use SRC5Component::SRC5InternalImpl;
    // corelib imports
    use starknet::ContractAddress;

    #[storage]
    struct Storage {
        ERC2114_trait_list_counter: u64,
        ERC2114_trait_list_size: LegacyMap<u64, felt252>,
        ERC2114_index_to_trait_list_value: LegacyMap<(u64, felt252), felt252>,
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

    // -------------------------------------------------------------------------- //
    //                               For Embeddable                               //
    // -------------------------------------------------------------------------- //
    #[embeddable_as(TraitCatalogImpl)]
    impl TraitCatalog<
        TContractState, +HasComponent<TContractState>
    > of interface::ITraitCatalog<ComponentState<TContractState>> {
        fn trait_list_count(self: @ComponentState<TContractState>) -> u64 {
            ITraitCatalogImpl::trait_list_count(self)
        }

        fn trait_list_length(self: @ComponentState<TContractState>, list_id: u64) -> felt252 {
            ITraitCatalogImpl::trait_list_length(self, list_id)
        }

        fn trait_list_value_by_index(
            self: @ComponentState<TContractState>, list_id: u64, index: felt252
        ) -> felt252 {
            ITraitCatalogImpl::trait_list_value_by_index(self, list_id, index)
        }

        fn generate_trait_list(
            ref self: ComponentState<TContractState>, values: Span<felt252>
        ) -> u64 {
            ITraitCatalogImpl::generate_trait_list(ref self, values)
        }

        fn append_to_trait_list(
            ref self: ComponentState<TContractState>, list_id: u64, value: felt252
        ) {
            ITraitCatalogImpl::append_to_trait_list(ref self, list_id, value);
        }

        fn append_batch_to_trait_list(
            ref self: ComponentState<TContractState>, list_id: u64, values: Span<felt252>
        ) {
            ITraitCatalogImpl::append_batch_to_trait_list(ref self, list_id, values);
        }

        fn ammend_trait_list(
            ref self: ComponentState<TContractState>, list_id: u64, index: felt252, value: felt252
        ) {
            ITraitCatalogImpl::ammend_trait_list(ref self, list_id, index, value);
        }
    }
    // -------------------------------------------------------------------------- //
    //                                 Initializer                                //
    // -------------------------------------------------------------------------- //

    #[generate_trait]
    impl TraitCatalogInitializerImpl<
        TContractState,
        +HasComponent<TContractState>,
        +SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>
    > of TraitCatalogInitializerTrait<TContractState> {
        fn initializer(ref self: ComponentState<TContractState>) {
            let mut src5 = self.get_src5_mut();
            src5.register_interface(constants::ITRAIT_CATALOG_ID);
        }
    }

    // -------------------------------------------------------------------------- //
    //                             External Functions                             //
    // -------------------------------------------------------------------------- //

    #[generate_trait]
    impl ITraitCatalogImpl<
        TContractState, +HasComponent<TContractState>
    > of ITraitCatalogImplTrait<TContractState> {
        #[inline(always)]
        fn trait_list_count(self: @ComponentState<TContractState>) -> u64 {
            self.ERC2114_trait_list_counter.read()
        }

        #[inline(always)]
        fn trait_list_length(self: @ComponentState<TContractState>, list_id: u64) -> felt252 {
            self.ERC2114_trait_list_size.read(list_id)
        }

        #[inline(always)]
        fn trait_list_value_by_index(
            self: @ComponentState<TContractState>, list_id: u64, index: felt252
        ) -> felt252 {
            self.ERC2114_index_to_trait_list_value.read((list_id, index))
        }

        #[inline(always)]
        fn generate_trait_list(
            ref self: ComponentState<TContractState>, values: Span<felt252>
        ) -> u64 {
            // assert values length is not zero
            assert(values.len().is_non_zero(), 'TraitCatalog: invalid values');
            // increase trait list count
            self._increase_trait_list_count();
            let list_id = self.ERC2114_trait_list_counter.read();
            // emits events, increases length, updates values and checks validity of value
            self._append_batch_to_trait_list(list_id, values);
            list_id
        }

        #[inline(always)]
        fn append_to_trait_list(
            ref self: ComponentState<TContractState>, list_id: u64, value: felt252
        ) {
            // assert trait list validity
            self._assert_trait_list_exists(list_id);
            let cur_len = self.ERC2114_trait_list_size.read(list_id);
            // emits events and cheecks validity of value
            self._update_trait_list(list_id, cur_len + 1, value);
            // increase trait list length
            self.ERC2114_trait_list_size.write(list_id, cur_len + 1);
        }

        #[inline(always)]
        fn append_batch_to_trait_list(
            ref self: ComponentState<TContractState>, list_id: u64, values: Span<felt252>
        ) {
            // assert trait list validity
            self._assert_trait_list_exists(list_id);
            // assert values length is not zero
            assert(values.len().is_non_zero(), 'TraitCatalog: invalid values');
            // emits events, increases length, updates values and checks validity of value
            self._append_batch_to_trait_list(list_id, values);
        }

        #[inline(always)]
        fn ammend_trait_list(
            ref self: ComponentState<TContractState>, list_id: u64, index: felt252, value: felt252
        ) {
            // assert trait list validity
            self._assert_trait_list_exists(list_id);
            // assert index is not out of bounds
            let cur_len: u256 = self.ERC2114_trait_list_size.read(list_id).into();
            assert(index.into() <= cur_len, 'TraitCatalog: index exceeded');
            // emits events and cheecks validity of value and ensures index is non_zero
            self._update_trait_list(list_id, index, value);
        }
    }

    // -------------------------------------------------------------------------- //
    //                             Internal Functions                             //
    // -------------------------------------------------------------------------- //

    #[generate_trait]
    impl TraitCatalogInternalImpl<
        TContractState, +HasComponent<TContractState>
    > of TraitCatalogInternalTrait<TContractState> {
        // @dev append a batch of values to trait list
        //  DOES NOT check validity of list_id
        //  increases length of trait list
        fn _append_batch_to_trait_list(
            ref self: ComponentState<TContractState>, list_id: u64, mut values: Span<felt252>
        ) {
            let mut cur_len = self.ERC2114_trait_list_size.read(list_id);
            loop {
                match values.pop_front() {
                    Option::Some(value) => {
                        cur_len += 1;
                        self._update_trait_list(list_id, cur_len, *value);
                    },
                    Option::None(_) => { break; }
                };
            };
            self.ERC2114_trait_list_size.write(list_id, cur_len);
        }
    }

    // -------------------------------------------------------------------------- //
    //                              Private Functions                             //
    // -------------------------------------------------------------------------- //
    #[generate_trait]
    impl TraitCatalogPrivateImpl<
        TContractState, +HasComponent<TContractState>
    > of TraitCatalogPrivateTrait<TContractState> {
        #[inline(always)]
        fn _assert_trait_list_exists(self: @ComponentState<TContractState>, list_id: u64) {
            assert(
                list_id > 0 && list_id <= self.ERC2114_trait_list_counter.read(),
                'TraitCatalog: invalid list id'
            );
        }

        #[inline(always)]
        fn _increase_trait_list_count(ref self: ComponentState<TContractState>) {
            self.ERC2114_trait_list_counter.write(self.ERC2114_trait_list_counter.read() + 1);
        }

        // @dev updates trait list value at index
        //  EMITS TraitListUpdate
        //  DOES NOT check validity of list_id
        //  DOES NOT check validity of index in relation to trait_list length
        //  checks validity of value and if index is non_zero

        #[inline(always)]
        fn _update_trait_list(
            ref self: ComponentState<TContractState>, list_id: u64, index: felt252, value: felt252
        ) {
            // assert index and value is not zero
            assert(index.is_non_zero() && value.is_non_zero(), 'TraitCatalog: invalid update');

            // if old_value == current value return
            let old_value = self.ERC2114_index_to_trait_list_value.read((list_id, index));
            if old_value == value {
                return;
            }
            // update index_to_trait_list_value
            self.ERC2114_index_to_trait_list_value.write((list_id, index), value);
            //emit event
            self.emit(TraitListUpdate { list_id, index, old_value, new_value: value });
        }
    }
    // -------------------------------------------------------------------------- //
    //                              Get Dependencies                              //
    // -------------------------------------------------------------------------- //

    #[generate_trait]
    impl GetSRC5<
        TContractState,
        +HasComponent<TContractState>,
        +SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>
    > of GetSRC5Trait<TContractState> {
        #[inline(always)]
        fn get_src5(
            self: @ComponentState<TContractState>
        ) -> @SRC5Component::ComponentState<TContractState> {
            let contract = self.get_contract();
            SRC5Component::HasComponent::<TContractState>::get_component(contract)
        }

        #[inline(always)]
        fn get_src5_mut(
            ref self: ComponentState<TContractState>
        ) -> SRC5Component::ComponentState<TContractState> {
            let mut contract = self.get_contract_mut();
            SRC5Component::HasComponent::<TContractState>::get_component_mut(ref contract)
        }
    }
}
