#[starknet::component]
mod ERC721MetadataComponent {
    use seraphlabs::ascii::interger::IntergerToAsciiTrait;
    use seraphlabs::data_structures::arrays::SeraphArrayTrait;
    use seraphlabs::tokens::constants;
    use seraphlabs::tokens::erc721::{ERC721Component, interface};
    use seraphlabs::tokens::src5::SRC5Component;
    use ERC721Component::ERC721InternalImpl;
    use SRC5Component::SRC5InternalImpl;

    #[storage]
    struct Storage {
        erc721_name: felt252,
        erc721_symbol: felt252,
        erc721_base_uri: LegacyMap::<felt252, felt252>,
        erc721_base_uri_len: felt252,
    }

    #[event]
    #[derive(Drop, PartialEq, starknet::Event)]
    enum Event {}

    // -------------------------------------------------------------------------- //
    //                               For Embeddable                               //
    // -------------------------------------------------------------------------- //

    #[embeddable_as(ERC721MetadataImpl)]
    impl ERC721Metadata<
        TContractState,
        +HasComponent<TContractState>,
        +ERC721Component::HasComponent<TContractState>,
        +Drop<TContractState>
    > of interface::IERC721Metadata<ComponentState<TContractState>> {
        fn name(self: @ComponentState<TContractState>) -> felt252 {
            IERC721MetadataImpl::name(self)
        }

        fn symbol(self: @ComponentState<TContractState>) -> felt252 {
            IERC721MetadataImpl::symbol(self)
        }

        fn token_uri(self: @ComponentState<TContractState>, token_id: u256) -> Array<felt252> {
            IERC721MetadataImpl::token_uri(self, token_id)
        }
    }

    // -------------------------------------------------------------------------- //
    //                                 Initializer                                //
    // -------------------------------------------------------------------------- //

    #[generate_trait]
    impl ERC721MetadataInitializerImpl<
        TContractState,
        +HasComponent<TContractState>,
        +SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>
    > of ERC721MetadataInitializerTrait<TContractState> {
        fn initializer(ref self: ComponentState<TContractState>, name: felt252, symbol: felt252) {
            self.erc721_name.write(name);
            self.erc721_symbol.write(symbol);
            let mut src5 = self.get_src5_mut();
            src5.register_interface(constants::IERC721_METADATA_ID);
        }
    }

    // -------------------------------------------------------------------------- //
    //                             External Functions                             //
    // -------------------------------------------------------------------------- //

    #[generate_trait]
    impl IERC721MetadataImpl<
        TContractState,
        +HasComponent<TContractState>,
        +ERC721Component::HasComponent<TContractState>,
        +Drop<TContractState>
    > of IERC721MetadataImplTrait<TContractState> {
        #[inline(always)]
        fn name(self: @ComponentState<TContractState>) -> felt252 {
            self.erc721_name.read()
        }

        #[inline(always)]
        fn symbol(self: @ComponentState<TContractState>) -> felt252 {
            self.erc721_symbol.read()
        }

        #[inline(always)]
        fn token_uri(self: @ComponentState<TContractState>, token_id: u256) -> Array<felt252> {
            // get_base_uri
            assert(self.get_erc721()._exist(token_id), 'ERC721Metadata: invalid tokenId');
            let mut base_uri = self._get_base_uri();
            // get token_id low ascii value
            let mut ascii: Array<felt252> = token_id.to_ascii();
            // append it to base_uri array along with suffix
            base_uri.append_array(ref ascii);
            base_uri.append('.json');
            base_uri
        }
    }

    // -------------------------------------------------------------------------- //
    //                             Internal Functions                             //
    // -------------------------------------------------------------------------- //

    #[generate_trait]
    impl ERC721MetadataInternalImpl<
        TContractState, +HasComponent<TContractState>,
    > of ERC721MetadataInternalTrait<TContractState> {
        fn _get_base_uri(self: @ComponentState<TContractState>) -> Array<felt252> {
            let len = self.erc721_base_uri_len.read();
            let mut base_uri = ArrayTrait::<felt252>::new();
            let mut index = 0;
            loop {
                if index == len {
                    break ();
                }
                base_uri.append(self.erc721_base_uri.read(index));
                index += 1;
            };
            base_uri
        }

        fn _set_base_uri(ref self: ComponentState<TContractState>, mut base_uri: Array<felt252>) {
            let len = base_uri.len();
            let mut index = 0;
            loop {
                match base_uri.pop_front() {
                    Option::Some(value) => {
                        self.erc721_base_uri.write(index, value);
                        index += 1;
                    },
                    Option::None(()) => { break (); },
                };
            };
            // write length to storage
            self.erc721_base_uri_len.write(len.into());
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

    #[generate_trait]
    impl GetERC721<
        TContractState,
        +HasComponent<TContractState>,
        +ERC721Component::HasComponent<TContractState>,
        +Drop<TContractState>
    > of GetERC721Trait<TContractState> {
        #[inline(always)]
        fn get_erc721(
            self: @ComponentState<TContractState>
        ) -> @ERC721Component::ComponentState<TContractState> {
            let contract = self.get_contract();
            ERC721Component::HasComponent::<TContractState>::get_component(contract)
        }

        #[inline(always)]
        fn get_erc721_mut(
            ref self: ComponentState<TContractState>
        ) -> ERC721Component::ComponentState<TContractState> {
            let mut contract = self.get_contract_mut();
            ERC721Component::HasComponent::<TContractState>::get_component_mut(ref contract)
        }
    }
}

#[starknet::contract]
mod ERC721Metadata {
    use seraphlabs::ascii::interger::IntergerToAsciiTrait;
    use seraphlabs::data_structures::arrays::SeraphArrayTrait;
    use seraphlabs::tokens::constants;
    use seraphlabs::tokens::erc721::{ERC721, interface};
    use seraphlabs::tokens::src5::SRC5;

    #[storage]
    struct Storage {
        erc721_name: felt252,
        erc721_symbol: felt252,
        erc721_base_uri: LegacyMap::<felt252, felt252>,
        erc721_base_uri_len: felt252,
    }

    #[external(v0)]
    impl IERC721MetadataImpl of interface::IERC721Metadata<ContractState> {
        fn name(self: @ContractState) -> felt252 {
            self.erc721_name.read()
        }

        fn symbol(self: @ContractState) -> felt252 {
            self.erc721_symbol.read()
        }

        fn token_uri(self: @ContractState, token_id: u256) -> Array<felt252> {
            let unsafe_state = ERC721::unsafe_new_contract_state();
            // get_base_uri
            assert(
                ERC721::InternalImpl::_exist(@unsafe_state, token_id),
                'ERC721Metadata: invalid tokenId'
            );

            let mut base_uri = self._get_base_uri();
            // get token_id low ascii value
            let mut ascii: Array<felt252> = token_id.to_ascii();
            // append it to base_uri array along with suffix
            base_uri.append_array(ref ascii);
            base_uri.append('.json');
            base_uri
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn initializer(ref self: ContractState, name: felt252, symbol: felt252) {
            self.erc721_name.write(name);
            self.erc721_symbol.write(symbol);
            // add metadata interface id
            let mut unsafe_state = SRC5::unsafe_new_contract_state();
            SRC5::InternalImpl::register_interface(
                ref unsafe_state, constants::IERC721_METADATA_ID
            );
        }

        fn _get_base_uri(self: @ContractState) -> Array<felt252> {
            let len = self.erc721_base_uri_len.read();
            let mut base_uri = ArrayTrait::<felt252>::new();
            let mut index = 0;
            loop {
                if index == len {
                    break ();
                }
                base_uri.append(self.erc721_base_uri.read(index));
                index += 1;
            };
            base_uri
        }

        fn _set_base_uri(ref self: ContractState, mut base_uri: Array<felt252>) {
            let len = base_uri.len();
            let mut index = 0;
            loop {
                match base_uri.pop_front() {
                    Option::Some(value) => {
                        self.erc721_base_uri.write(index, value);
                        index += 1;
                    },
                    Option::None(()) => { break (); },
                };
            };
            // write length to storage
            self.erc721_base_uri_len.write(len.into());
        }
    }
}

