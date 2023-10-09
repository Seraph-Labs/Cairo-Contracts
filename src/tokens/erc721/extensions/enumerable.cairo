#[starknet::component]
mod ERC721EnumComponent {
    use seraphlabs::tokens::constants;
    use seraphlabs::tokens::erc721::interface;
    use seraphlabs::tokens::erc721::ERC721Component;
    use seraphlabs::tokens::src5::SRC5Component;
    use SRC5Component::SRC5InternalImpl;
    use ERC721Component::{ERC721InternalImpl, IERC721Impl};

    use starknet::ContractAddress;
    use array::SpanSerde;
    use integer::BoundedInt;

    #[storage]
    struct Storage {
        erc721_supply: u256,
        erc721_index_to_tokens: LegacyMap::<u256, u256>,
        erc721_tokens_to_index: LegacyMap::<u256, u256>,
        erc721_owner_index_to_token: LegacyMap::<(ContractAddress, u256), u256>,
        erc721_owner_token_to_index: LegacyMap::<u256, u256>,
    }

    #[event]
    #[derive(Drop, PartialEq, starknet::Event)]
    enum Event {}

    // -------------------------------------------------------------------------- //
    //                               For Embeddable                               //
    // -------------------------------------------------------------------------- //

    #[embeddable_as(ERC721EnumImpl)]
    impl ERC721Enum<
        TContractState,
        +HasComponent<TContractState>,
        +ERC721Component::HasComponent<TContractState>,
        +Drop<TContractState>
    > of interface::IERC721Enumerable<ComponentState<TContractState>> {
        fn total_supply(self: @ComponentState<TContractState>) -> u256 {
            IERC721EnumImpl::total_supply(self)
        }

        fn token_by_index(self: @ComponentState<TContractState>, index: u256) -> u256 {
            IERC721EnumImpl::token_by_index(self, index)
        }

        fn token_of_owner_by_index(
            self: @ComponentState<TContractState>, owner: ContractAddress, index: u256
        ) -> u256 {
            IERC721EnumImpl::token_of_owner_by_index(self, owner, index)
        }
    }

    // -------------------------------------------------------------------------- //
    //                                 Initializer                                //
    // -------------------------------------------------------------------------- //

    #[generate_trait]
    impl ERC721EnumInitializerImpl<
        TContractState,
        +HasComponent<TContractState>,
        +SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>
    > of ERC721EnumInitializerTrait<TContractState> {
        fn initializer(ref self: ComponentState<TContractState>) {
            let mut src5 = self.get_src5_mut();
            src5.register_interface(constants::IERC721_ENUMERABLE_ID);
        }
    }
    // -------------------------------------------------------------------------- //
    //                             External Functions                             //
    // -------------------------------------------------------------------------- //

    #[generate_trait]
    impl IERC721EnumImpl<
        TContractState,
        +HasComponent<TContractState>,
        +ERC721Component::HasComponent<TContractState>,
        +Drop<TContractState>
    > of IERC721EnumImplTrait<TContractState> {
        #[inline(always)]
        fn total_supply(self: @ComponentState<TContractState>) -> u256 {
            self.erc721_supply.read()
        }

        #[inline(always)]
        fn token_by_index(self: @ComponentState<TContractState>, index: u256) -> u256 {
            // assert index is not out of bounds
            let supply = self.erc721_supply.read();
            assert(index < supply, 'ERC721Enum: index out of bounds');
            self.erc721_index_to_tokens.read(index)
        }

        #[inline(always)]
        fn token_of_owner_by_index(
            self: @ComponentState<TContractState>, owner: ContractAddress, index: u256
        ) -> u256 {
            self._token_of_owner_by_index(owner, index).expect('ERC721Enum: index out of bounds')
        }
    }

    // -------------------------------------------------------------------------- //
    //                             Internal Functions                             //
    // -------------------------------------------------------------------------- //

    #[generate_trait]
    impl ERC721EnumInternalImpl<
        TContractState,
        +HasComponent<TContractState>,
        +ERC721Component::HasComponent<TContractState>,
        +Drop<TContractState>
    > of ERC721EnumInternalTrait<TContractState> {
        #[inline(always)]
        fn transfer_from(
            ref self: ComponentState<TContractState>,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256
        ) {
            self._transfer(from, to, token_id);
            let mut erc721 = self.get_erc721_mut();
            erc721.transfer_from(from, to, token_id);
        }

        #[inline(always)]
        fn safe_transfer_from(
            ref self: ComponentState<TContractState>,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            data: Span<felt252>
        ) {
            self._transfer(from, to, token_id);
            let mut erc721 = self.get_erc721_mut();
            erc721.safe_transfer_from(from, to, token_id, data);
        }

        // @dev transfer function that only edits the enum storage and not 721 storage

        #[inline(always)]
        fn _transfer(
            ref self: ComponentState<TContractState>,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256
        ) {
            self._remove_token_from_owner_enum(from, token_id);
            self._add_token_to_owner_enum(to, token_id);
        }

        #[inline(always)]
        fn _mint(ref self: ComponentState<TContractState>, to: ContractAddress, token_id: u256) {
            self._add_token_to_owner_enum(to, token_id);
            self._add_token_to_total_enum(token_id);

            let mut erc721 = self.get_erc721_mut();
            erc721._mint(to, token_id);
        }

        #[inline(always)]
        fn _safe_mint(
            ref self: ComponentState<TContractState>,
            to: ContractAddress,
            token_id: u256,
            data: Span<felt252>
        ) {
            self._add_token_to_owner_enum(to, token_id);
            self._add_token_to_total_enum(token_id);

            let mut erc721 = self.get_erc721_mut();
            erc721._safe_mint(to, token_id, data);
        }

        #[inline(always)]
        fn _burn(ref self: ComponentState<TContractState>, token_id: u256) {
            let mut erc721 = self.get_erc721_mut();
            let owner = erc721.owner_of(token_id);

            self._remove_token_from_owner_enum(owner, token_id);
            self._remove_token_from_total_enum(token_id);
            // set owners token_id index to zero
            self.erc721_owner_token_to_index.write(token_id, BoundedInt::min());
            erc721._burn(token_id);
        }

        #[inline(always)]
        fn _token_of_owner_by_index(
            self: @ComponentState<TContractState>, owner: ContractAddress, index: u256
        ) -> Option<u256> {
            let token_id = self.erc721_owner_index_to_token.read((owner, index));
            match token_id == BoundedInt::<u256>::min() {
                bool::False(()) => Option::Some(token_id),
                bool::True(()) => Option::None(()),
            }
        }
    }
    // -------------------------------------------------------------------------- //
    //                              Private Functions                             //
    // -------------------------------------------------------------------------- //
    #[generate_trait]
    impl ERC721EnumPrivateImpl<
        TContractState,
        +HasComponent<TContractState>,
        +ERC721Component::HasComponent<TContractState>,
        +Drop<TContractState>
    > of ERC721EnumPrivateTrait<TContractState> {
        #[inline(always)]
        fn _add_token_to_total_enum(ref self: ComponentState<TContractState>, token_id: u256) {
            let supply = self.erc721_supply.read();
            // add token_id to totals last index
            self.erc721_index_to_tokens.write(supply, token_id);
            // add last index to token_id
            self.erc721_tokens_to_index.write(token_id, supply);
            // add to new_supply
            self.erc721_supply.write(supply + 1_u256);
        }

        #[inline(always)]
        fn _remove_token_from_total_enum(ref self: ComponentState<TContractState>, token_id: u256) {
            // index starts from zero therefore minus 1
            let last_token_index = self.erc721_supply.read() - 1_u256;
            let cur_token_index = self.erc721_tokens_to_index.read(token_id);

            if last_token_index != cur_token_index {
                // set last token Id to cur token index
                let last_tokenId = self.erc721_index_to_tokens.read(last_token_index);
                self.erc721_index_to_tokens.write(cur_token_index, last_tokenId);
                // set cur token index to last token_id
                self.erc721_tokens_to_index.write(last_tokenId, cur_token_index);
            }

            // set token at last index to zero
            self.erc721_index_to_tokens.write(last_token_index, BoundedInt::min());
            // set token_id index to zero
            self.erc721_tokens_to_index.write(token_id, BoundedInt::min());
            // remove 1 from supply
            self.erc721_supply.write(last_token_index);
        }

        #[inline(always)]
        fn _add_token_to_owner_enum(
            ref self: ComponentState<TContractState>, owner: ContractAddress, token_id: u256
        ) {
            let len = self.get_erc721_mut().balance_of(owner);
            // set token_id to owners last index
            self.erc721_owner_index_to_token.write((owner, len), token_id);
            // set index to owners token_id
            self.erc721_owner_token_to_index.write(token_id, len);
        }

        #[inline(always)]
        fn _remove_token_from_owner_enum(
            ref self: ComponentState<TContractState>, owner: ContractAddress, token_id: u256
        ) {
            // index starts from zero therefore minus 1
            let last_token_index = self.get_erc721_mut().balance_of(owner) - 1.into();
            let cur_token_index = self.erc721_owner_token_to_index.read(token_id);

            if last_token_index != cur_token_index {
                // set last token Id to cur token index
                let last_tokenId = self.erc721_owner_index_to_token.read((owner, last_token_index));
                self.erc721_owner_index_to_token.write((owner, cur_token_index), last_tokenId);
                // set cur token index to last token_id
                self.erc721_owner_token_to_index.write(last_tokenId, cur_token_index);
            }
            // set token at owners last index to zero
            self.erc721_owner_index_to_token.write((owner, last_token_index), BoundedInt::min());
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
mod ERC721Enumerable {
    use seraphlabs::tokens::constants;
    use seraphlabs::tokens::erc721::interface;
    use seraphlabs::tokens::erc721::ERC721;
    use seraphlabs::tokens::src5::SRC5;

    use starknet::ContractAddress;
    use array::SpanSerde;
    use integer::BoundedInt;

    #[storage]
    struct Storage {
        erc721_supply: u256,
        erc721_index_to_tokens: LegacyMap::<u256, u256>,
        erc721_tokens_to_index: LegacyMap::<u256, u256>,
        erc721_owner_index_to_token: LegacyMap::<(ContractAddress, u256), u256>,
        erc721_owner_token_to_index: LegacyMap::<u256, u256>,
    }

    #[external(v0)]
    impl IERC721EnumImpl of interface::IERC721Enumerable<ContractState> {
        fn total_supply(self: @ContractState) -> u256 {
            self.erc721_supply.read()
        }

        fn token_by_index(self: @ContractState, index: u256) -> u256 {
            // assert index is not out of bounds
            let supply = self.erc721_supply.read();
            assert(index < supply, 'ERC721Enum: index out of bounds');
            self.erc721_index_to_tokens.read(index)
        }

        fn token_of_owner_by_index(
            self: @ContractState, owner: ContractAddress, index: u256
        ) -> u256 {
            self._token_of_owner_by_index(owner, index).expect('ERC721Enum: index out of bounds')
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn initializer(ref self: ContractState) {
            let mut unsafe_state = SRC5::unsafe_new_contract_state();
            SRC5::InternalImpl::register_interface(
                ref unsafe_state, constants::IERC721_ENUMERABLE_ID
            );
        }

        fn transfer_from(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            self._transfer(from, to, token_id);
            let mut unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::IERC721Impl::transfer_from(ref unsafe_state, from, to, token_id);
        }

        fn safe_transfer_from(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            data: Span<felt252>
        ) {
            self._transfer(from, to, token_id);
            let mut unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::IERC721Impl::safe_transfer_from(ref unsafe_state, from, to, token_id, data)
        }

        // @dev transfer function that only edits the enum storage and not 721 storage
        fn _transfer(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            self._remove_token_from_owner_enum(from, token_id);
            self._add_token_to_owner_enum(to, token_id);
        }

        fn _mint(ref self: ContractState, to: ContractAddress, token_id: u256) {
            self._add_token_to_owner_enum(to, token_id);
            self._add_token_to_total_enum(token_id);
            let mut unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::InternalImpl::_mint(ref unsafe_state, to, token_id);
        }

        fn _safe_mint(
            ref self: ContractState, to: ContractAddress, token_id: u256, data: Span<felt252>
        ) {
            self._add_token_to_owner_enum(to, token_id);
            self._add_token_to_total_enum(token_id);
            let mut unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::InternalImpl::_safe_mint(ref unsafe_state, to, token_id, data);
        }

        fn _burn(ref self: ContractState, token_id: u256) {
            let mut unsafe_state = ERC721::unsafe_new_contract_state();
            let owner = ERC721::IERC721Impl::owner_of(@unsafe_state, token_id);

            self._remove_token_from_owner_enum(owner, token_id);
            self._remove_token_from_total_enum(token_id);
            // set owners token_id index to zero
            self.erc721_owner_token_to_index.write(token_id, BoundedInt::min());
            ERC721::InternalImpl::_burn(ref unsafe_state, token_id);
        }

        fn _token_of_owner_by_index(
            self: @ContractState, owner: ContractAddress, index: u256
        ) -> Option<u256> {
            let token_id = self.erc721_owner_index_to_token.read((owner, index));
            match token_id == BoundedInt::<u256>::min() {
                bool::False(()) => Option::Some(token_id),
                bool::True(()) => Option::None(()),
            }
        }
    }

    #[generate_trait]
    impl PrivateImpl of PrivateTrait {
        fn _add_token_to_total_enum(ref self: ContractState, token_id: u256) {
            let supply = self.erc721_supply.read();
            // add token_id to totals last index
            self.erc721_index_to_tokens.write(supply, token_id);
            // add last index to token_id
            self.erc721_tokens_to_index.write(token_id, supply);
            // add to new_supply
            self.erc721_supply.write(supply + 1_u256);
        }

        fn _remove_token_from_total_enum(ref self: ContractState, token_id: u256) {
            // index starts from zero therefore minus 1
            let last_token_index = self.erc721_supply.read() - 1_u256;
            let cur_token_index = self.erc721_tokens_to_index.read(token_id);

            if last_token_index != cur_token_index {
                // set last token Id to cur token index
                let last_tokenId = self.erc721_index_to_tokens.read(last_token_index);
                self.erc721_index_to_tokens.write(cur_token_index, last_tokenId);
                // set cur token index to last token_id
                self.erc721_tokens_to_index.write(last_tokenId, cur_token_index);
            }

            // set token at last index to zero
            self.erc721_index_to_tokens.write(last_token_index, BoundedInt::min());
            // set token_id index to zero
            self.erc721_tokens_to_index.write(token_id, BoundedInt::min());
            // remove 1 from supply
            self.erc721_supply.write(last_token_index);
        }

        fn _add_token_to_owner_enum(
            ref self: ContractState, owner: ContractAddress, token_id: u256
        ) {
            let unsafe_state = ERC721::unsafe_new_contract_state();
            let len = ERC721::IERC721Impl::balance_of(@unsafe_state, owner);
            // set token_id to owners last index
            self.erc721_owner_index_to_token.write((owner, len), token_id);
            // set index to owners token_id
            self.erc721_owner_token_to_index.write(token_id, len);
        }

        fn _remove_token_from_owner_enum(
            ref self: ContractState, owner: ContractAddress, token_id: u256
        ) {
            // index starts from zero therefore minus 1
            let unsafe_state = ERC721::unsafe_new_contract_state();
            let last_token_index = ERC721::IERC721Impl::balance_of(@unsafe_state, owner) - 1.into();
            let cur_token_index = self.erc721_owner_token_to_index.read(token_id);

            if last_token_index != cur_token_index {
                // set last token Id to cur token index
                let last_tokenId = self.erc721_owner_index_to_token.read((owner, last_token_index));
                self.erc721_owner_index_to_token.write((owner, cur_token_index), last_tokenId);
                // set cur token index to last token_id
                self.erc721_owner_token_to_index.write(last_tokenId, cur_token_index);
            }
            // set token at owners last index to zero
            self.erc721_owner_index_to_token.write((owner, last_token_index), BoundedInt::min());
        }
    }
}
