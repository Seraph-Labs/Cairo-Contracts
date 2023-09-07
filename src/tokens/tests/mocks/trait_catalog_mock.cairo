#[starknet::contract]
mod TraitCatalogMock {
    use seraphlabs::tokens::erc2114::extensions::TraitCatalog;
    use seraphlabs::tokens::erc2114::interface;
    use seraphlabs::tokens::src5::SRC5;
    use starknet::ContractAddress;

    #[storage]
    struct Storage {}

    #[constructor]
    fn constructor(ref self: ContractState) {
        let mut unsafe_state = TraitCatalog::unsafe_new_contract_state();
        TraitCatalog::InternalImpl::initializer(ref unsafe_state);
    }

    #[external(v0)]
    fn supports_interface(self: @ContractState, interface_id: felt252) -> bool {
        let unsafe_state = SRC5::unsafe_new_contract_state();
        SRC5::ISRC5Impl::supports_interface(@unsafe_state, interface_id)
    }

    #[external(v0)]
    impl ITraitCatalogImpl of interface::ITraitCatalog<ContractState> {
        fn trait_list_count(self: @ContractState) -> u64 {
            let unsafe_state = TraitCatalog::unsafe_new_contract_state();
            TraitCatalog::ITraitCatalogImpl::trait_list_count(@unsafe_state)
        }

        fn trait_list_length(self: @ContractState, list_id: u64) -> felt252 {
            let unsafe_state = TraitCatalog::unsafe_new_contract_state();
            TraitCatalog::ITraitCatalogImpl::trait_list_length(@unsafe_state, list_id)
        }

        fn trait_list_value_by_index(
            self: @ContractState, list_id: u64, index: felt252
        ) -> felt252 {
            let unsafe_state = TraitCatalog::unsafe_new_contract_state();
            TraitCatalog::ITraitCatalogImpl::trait_list_value_by_index(
                @unsafe_state, list_id, index
            )
        }

        fn generate_trait_list(ref self: ContractState, values: Span<felt252>) -> u64 {
            let mut unsafe_state = TraitCatalog::unsafe_new_contract_state();
            TraitCatalog::ITraitCatalogImpl::generate_trait_list(ref unsafe_state, values)
        }

        fn append_to_trait_list(ref self: ContractState, list_id: u64, value: felt252) {
            let mut unsafe_state = TraitCatalog::unsafe_new_contract_state();
            TraitCatalog::ITraitCatalogImpl::append_to_trait_list(ref unsafe_state, list_id, value)
        }

        fn append_batch_to_trait_list(
            ref self: ContractState, list_id: u64, values: Span<felt252>
        ) {
            let mut unsafe_state = TraitCatalog::unsafe_new_contract_state();
            TraitCatalog::ITraitCatalogImpl::append_batch_to_trait_list(
                ref unsafe_state, list_id, values
            )
        }

        fn ammend_trait_list(
            ref self: ContractState, list_id: u64, index: felt252, value: felt252
        ) {
            let mut unsafe_state = TraitCatalog::unsafe_new_contract_state();
            TraitCatalog::ITraitCatalogImpl::ammend_trait_list(
                ref unsafe_state, list_id, index, value
            )
        }
    }
}

#[starknet::contract]
mod InvalidTraitCatalogMock {
    use seraphlabs::tokens::erc2114::extensions::TraitCatalog;
    use seraphlabs::tokens::erc2114::interface;
    use seraphlabs::tokens::src5::SRC5;
    use starknet::ContractAddress;

    #[storage]
    struct Storage {}

    #[constructor]
    fn constructor(ref self: ContractState) {}

    #[external(v0)]
    fn supports_interface(self: @ContractState, interface_id: felt252) -> bool {
        let unsafe_state = SRC5::unsafe_new_contract_state();
        SRC5::ISRC5Impl::supports_interface(@unsafe_state, interface_id)
    }

    #[external(v0)]
    impl ITraitCatalogImpl of interface::ITraitCatalog<ContractState> {
        fn trait_list_count(self: @ContractState) -> u64 {
            let unsafe_state = TraitCatalog::unsafe_new_contract_state();
            TraitCatalog::ITraitCatalogImpl::trait_list_count(@unsafe_state)
        }

        fn trait_list_length(self: @ContractState, list_id: u64) -> felt252 {
            let unsafe_state = TraitCatalog::unsafe_new_contract_state();
            TraitCatalog::ITraitCatalogImpl::trait_list_length(@unsafe_state, list_id)
        }

        fn trait_list_value_by_index(
            self: @ContractState, list_id: u64, index: felt252
        ) -> felt252 {
            let unsafe_state = TraitCatalog::unsafe_new_contract_state();
            TraitCatalog::ITraitCatalogImpl::trait_list_value_by_index(
                @unsafe_state, list_id, index
            )
        }

        fn generate_trait_list(ref self: ContractState, values: Span<felt252>) -> u64 {
            let mut unsafe_state = TraitCatalog::unsafe_new_contract_state();
            TraitCatalog::ITraitCatalogImpl::generate_trait_list(ref unsafe_state, values)
        }

        fn append_to_trait_list(ref self: ContractState, list_id: u64, value: felt252) {
            let mut unsafe_state = TraitCatalog::unsafe_new_contract_state();
            TraitCatalog::ITraitCatalogImpl::append_to_trait_list(ref unsafe_state, list_id, value)
        }

        fn append_batch_to_trait_list(
            ref self: ContractState, list_id: u64, values: Span<felt252>
        ) {
            let mut unsafe_state = TraitCatalog::unsafe_new_contract_state();
            TraitCatalog::ITraitCatalogImpl::append_batch_to_trait_list(
                ref unsafe_state, list_id, values
            )
        }

        fn ammend_trait_list(
            ref self: ContractState, list_id: u64, index: felt252, value: felt252
        ) {
            let mut unsafe_state = TraitCatalog::unsafe_new_contract_state();
            TraitCatalog::ITraitCatalogImpl::ammend_trait_list(
                ref unsafe_state, list_id, index, value
            )
        }
    }
}
