#[starknet::contract]
mod ERC721Metadata {
    use seraphlabs::ascii::interger::IntergerToAsciiTrait;
    use seraphlabs::data_structures::arrays::SeraphArrayTrait;
    use seraphlabs::tokens::constants;
    use seraphlabs::tokens::erc721::{ERC721, interface};
    use seraphlabs::tokens::src5::SRC5;
    // corelib imports
    use array::ArrayTrait;
    use option::OptionTrait;
    use traits::{Into, TryInto};
    use zeroable::Zeroable;

    #[storage]
    struct Storage {
        _name: felt252,
        _symbol: felt252,
        _base_uri: LegacyMap::<felt252, felt252>,
        _base_uri_len: felt252,
    }

    #[external(v0)]
    impl IERC721MetadataImpl of interface::IERC721Metadata<ContractState> {
        fn name(self: @ContractState) -> felt252 {
            self._name.read()
        }

        fn symbol(self: @ContractState) -> felt252 {
            self._symbol.read()
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
            // TODO : covert entire u256 instead of just u128
            let mut ascii = token_id.low.to_ascii();
            // append it to base_uri array along with suffix
            base_uri.concat(ref ascii);
            base_uri.append('.json');
            base_uri
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn initializer(ref self: ContractState, name: felt252, symbol: felt252) {
            self._name.write(name);
            self._symbol.write(symbol);
            // add metadata interface id
            let mut unsafe_state = SRC5::unsafe_new_contract_state();
            SRC5::InternalImpl::register_interface(
                ref unsafe_state, constants::IERC721_METADATA_ID
            );
        }

        fn _get_base_uri(self: @ContractState) -> Array<felt252> {
            let len = self._base_uri_len.read();
            let mut base_uri = ArrayTrait::<felt252>::new();
            let mut index = 0;
            loop {
                if index == len {
                    break ();
                }
                base_uri.append(self._base_uri.read(index));
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
                        self._base_uri.write(index, value);
                        index += 1;
                    },
                    Option::None(()) => {
                        break ();
                    },
                };
            };
            // write length to storage
            self._base_uri_len.write(len.into());
        }
    }
}
