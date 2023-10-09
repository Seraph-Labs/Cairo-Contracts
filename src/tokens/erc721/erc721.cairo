#[starknet::component]
mod ERC721Component {
    use seraphlabs::tokens::constants;
    use seraphlabs::tokens::erc721::interface;
    use interface::{IERC721ReceiverDispatcher, IERC721ReceiverDispatcherTrait};
    use seraphlabs::tokens::src5::{
        SRC5Component, interface::{ISRC5Dispatcher, ISRC5DispatcherTrait}
    };
    use SRC5Component::SRC5InternalImpl;
    // corelib imports
    use starknet::{
        get_caller_address, contract_address_const, ContractAddress, ContractAddressIntoFelt252
    };


    #[storage]
    struct Storage {
        erc721_owners: LegacyMap::<u256, ContractAddress>,
        erc721_balances: LegacyMap::<ContractAddress, u256>,
        erc721_token_approvals: LegacyMap::<u256, ContractAddress>,
        erc721_operator_approvals: LegacyMap::<(ContractAddress, ContractAddress), bool>,
    }

    #[event]
    #[derive(Drop, PartialEq, starknet::Event)]
    enum Event {
        Transfer: Transfer,
        Approval: Approval,
        ApprovalForAll: ApprovalForAll,
    }

    #[derive(Drop, PartialEq, starknet::Event)]
    struct Transfer {
        #[key]
        from: ContractAddress,
        #[key]
        to: ContractAddress,
        #[key]
        token_id: u256,
    }

    #[derive(Drop, PartialEq, starknet::Event)]
    struct Approval {
        #[key]
        owner: ContractAddress,
        #[key]
        approved: ContractAddress,
        #[key]
        token_id: u256,
    }

    #[derive(Drop, PartialEq, starknet::Event)]
    struct ApprovalForAll {
        #[key]
        owner: ContractAddress,
        #[key]
        operator: ContractAddress,
        approved: bool,
    }

    // -------------------------------------------------------------------------- //
    //                               For Embeddable                               //
    // -------------------------------------------------------------------------- //

    #[embeddable_as(ERC721Impl)]
    impl ERC721<
        TContractState, +HasComponent<TContractState>,
    > of interface::IERC721<ComponentState<TContractState>> {
        fn balance_of(self: @ComponentState<TContractState>, owner: ContractAddress) -> u256 {
            IERC721Impl::balance_of(self, owner)
        }

        fn owner_of(self: @ComponentState<TContractState>, token_id: u256) -> ContractAddress {
            IERC721Impl::owner_of(self, token_id)
        }

        fn get_approved(self: @ComponentState<TContractState>, token_id: u256) -> ContractAddress {
            IERC721Impl::get_approved(self, token_id)
        }

        fn is_approved_for_all(
            self: @ComponentState<TContractState>, owner: ContractAddress, operator: ContractAddress
        ) -> bool {
            IERC721Impl::is_approved_for_all(self, owner, operator)
        }

        fn approve(
            ref self: ComponentState<TContractState>, approved: ContractAddress, token_id: u256
        ) {
            IERC721Impl::approve(ref self, approved, token_id);
        }

        fn set_approval_for_all(
            ref self: ComponentState<TContractState>, operator: ContractAddress, approved: bool
        ) {
            self._set_approval_for_all(operator, approved);
        }

        fn safe_transfer_from(
            ref self: ComponentState<TContractState>,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            data: Span<felt252>
        ) {
            IERC721Impl::safe_transfer_from(ref self, from, to, token_id, data);
        }

        fn transfer_from(
            ref self: ComponentState<TContractState>,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256
        ) {
            IERC721Impl::transfer_from(ref self, from, to, token_id);
        }
    }

    // -------------------------------------------------------------------------- //
    //                                 Initializer                                //
    // -------------------------------------------------------------------------- //

    #[generate_trait]
    impl ERC721InitializerImpl<
        TContractState,
        +HasComponent<TContractState>,
        +SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>
    > of ERC721InitializerTrait<TContractState> {
        fn initializer(ref self: ComponentState<TContractState>) {
            let mut src5 = self.get_src5_mut();
            src5.register_interface(constants::IERC721_ID);
        }
    }

    // -------------------------------------------------------------------------- //
    //                             External Functions                             //
    // -------------------------------------------------------------------------- //

    #[generate_trait]
    impl IERC721Impl<
        TContractState, +HasComponent<TContractState>,
    > of IERC721ImplTrait<TContractState> {
        #[inline(always)]
        fn balance_of(self: @ComponentState<TContractState>, owner: ContractAddress) -> u256 {
            self.erc721_balances.read(owner)
        }

        #[inline(always)]
        fn owner_of(self: @ComponentState<TContractState>, token_id: u256) -> ContractAddress {
            self._owner_of(token_id).expect('ERC721: invalid tokenId')
        }

        #[inline(always)]
        fn get_approved(self: @ComponentState<TContractState>, token_id: u256) -> ContractAddress {
            assert(self._exist(token_id), 'ERC721: tokenId does not exist');
            self.erc721_token_approvals.read(token_id)
        }

        #[inline(always)]
        fn is_approved_for_all(
            self: @ComponentState<TContractState>, owner: ContractAddress, operator: ContractAddress
        ) -> bool {
            self.erc721_operator_approvals.read((owner, operator))
        }

        #[inline(always)]
        fn approve(
            ref self: ComponentState<TContractState>, approved: ContractAddress, token_id: u256
        ) {
            let owner: ContractAddress = self._owner_of(token_id).expect('ERC721: invalid tokenId');
            let caller: ContractAddress = get_caller_address();
            assert(caller == owner, 'ERC721: invalid owner');
            self._approve(approved, token_id);
        }

        #[inline(always)]
        fn set_approval_for_all(
            ref self: ComponentState<TContractState>, operator: ContractAddress, approved: bool
        ) {
            self._set_approval_for_all(operator, approved);
        }

        #[inline(always)]
        fn safe_transfer_from(
            ref self: ComponentState<TContractState>,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            data: Span<felt252>
        ) {
            let caller: ContractAddress = get_caller_address();
            assert(self._is_approved_or_owner(caller, token_id), 'ERC721: caller is not approved');
            self._safe_transfer(from, to, token_id, data);
        }

        #[inline(always)]
        fn transfer_from(
            ref self: ComponentState<TContractState>,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256
        ) {
            let caller: ContractAddress = get_caller_address();
            assert(self._is_approved_or_owner(caller, token_id), 'ERC721: caller is not approved');
            self._transfer(from, to, token_id);
        }
    }

    // -------------------------------------------------------------------------- //
    //                             Internal Functions                             //
    // -------------------------------------------------------------------------- //

    #[generate_trait]
    impl ERC721InternalImpl<
        TContractState, +HasComponent<TContractState>,
    > of ERC721InternalTrait<TContractState> {
        #[inline(always)]
        fn _owner_of(
            self: @ComponentState<TContractState>, token_id: u256
        ) -> Option<ContractAddress> {
            let owner = self.erc721_owners.read(token_id);
            match owner.is_zero() {
                bool::False(()) => Option::Some(owner),
                bool::True(()) => Option::None(()),
            }
        }

        #[inline(always)]
        fn _exist(self: @ComponentState<TContractState>, token_id: u256) -> bool {
            let owner = self.erc721_owners.read(token_id);
            !owner.is_zero()
        }

        #[inline(always)]
        fn _is_approved_or_owner(
            self: @ComponentState<TContractState>, spender: ContractAddress, token_id: u256
        ) -> bool {
            assert(spender.is_non_zero(), 'ERC721: invalid caller');
            let owner: ContractAddress = self._owner_of(token_id).expect('ERC721: invalid tokenId');
            owner == spender
                || spender == self.erc721_token_approvals.read(token_id)
                || self.erc721_operator_approvals.read((owner, spender))
        }

        #[inline(always)]
        fn _transfer(
            ref self: ComponentState<TContractState>,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256
        ) {
            let owner = self._owner_of(token_id).expect('ERC721: invalid tokenId');

            // ensures owner == from
            assert(owner == from, 'ERC721: invalid sender');
            // ensures to is not a zero address
            assert(!to.is_zero(), 'ERC721: invalid address');

            // clear approvals
            self.erc721_token_approvals.write(token_id, Zeroable::zero());

            // update balances
            self.erc721_balances.write(to, self.erc721_balances.read(to) + 1_u256);
            self.erc721_balances.write(from, self.erc721_balances.read(from) - 1_u256);

            // update owner
            self.erc721_owners.write(token_id, to);
            // emit event
            self.emit(Transfer { from, to, token_id });
        }

        #[inline(always)]
        fn _safe_transfer(
            ref self: ComponentState<TContractState>,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            data: Span<felt252>
        ) {
            self._transfer(from, to, token_id);
            assert(
                self._check_on_erc721_received(from, to, token_id, data), 'ERC721: reciever failed'
            );
        }

        #[inline(always)]
        fn _approve(ref self: ComponentState<TContractState>, to: ContractAddress, token_id: u256) {
            let owner = self._owner_of(token_id).expect('ERC721: invalid tokenId');
            assert(owner != to, 'ERC721: owner cant approve self');
            self.erc721_token_approvals.write(token_id, to);
            self.emit(Approval { owner, approved: to, token_id });
        }

        #[inline(always)]
        fn _set_approval_for_all(
            ref self: ComponentState<TContractState>, operator: ContractAddress, approved: bool
        ) {
            assert(!operator.is_zero(), 'ERC721: invalid address');

            let caller: ContractAddress = get_caller_address();
            assert(!caller.is_zero(), 'ERC721: invalid caller');

            assert(caller != operator, 'ERC721: owner cant approve self');

            self.erc721_operator_approvals.write((caller, operator), approved);
            self.emit(ApprovalForAll { owner: caller, operator, approved });
        }

        #[inline(always)]
        fn _mint(ref self: ComponentState<TContractState>, to: ContractAddress, token_id: u256) {
            assert(!to.is_zero(), 'ERC721: invalid address');
            assert(token_id > 0_u256, 'ERC721: invalid tokenId');
            assert(!self._exist(token_id), 'ERC721: tokenId already exist');

            // update balances
            self.erc721_balances.write(to, self.erc721_balances.read(to) + 1.into());
            // update owner
            self.erc721_owners.write(token_id, to);
            // emit event
            self.emit(Transfer { from: Zeroable::zero(), to, token_id });
        }

        #[inline(always)]
        fn _safe_mint(
            ref self: ComponentState<TContractState>,
            to: ContractAddress,
            token_id: u256,
            data: Span<felt252>
        ) {
            self._mint(to, token_id);
            assert(
                self._check_on_erc721_received(Zeroable::zero(), to, token_id, data),
                'ERC721: reciever failed'
            );
        }

        #[inline(always)]
        fn _burn(ref self: ComponentState<TContractState>, token_id: u256) {
            // ensures tokenId has owner
            let owner = self._owner_of(token_id).expect('ERC721: invalid tokenId');

            // clear approvals
            self.erc721_token_approvals.write(token_id, Zeroable::zero());

            // update balances
            self.erc721_balances.write(owner, self.erc721_balances.read(owner) - 1.into());

            // update owner
            self.erc721_owners.write(token_id, Zeroable::zero());

            // emit event
            self.emit(Transfer { from: owner, to: Zeroable::zero(), token_id });
        }


        #[inline(always)]
        fn _check_on_erc721_received(
            self: @ComponentState<TContractState>,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            data: Span<felt252>
        ) -> bool {
            let support_interface = ISRC5Dispatcher { contract_address: to }
                .supports_interface(constants::IERC721_RECEIVER_ID);
            match support_interface {
                bool::False(()) => ISRC5Dispatcher { contract_address: to }
                    .supports_interface(constants::ISRC6_ID),
                bool::True(()) => {
                    IERC721ReceiverDispatcher { contract_address: to }
                        .on_erc721_received(
                            get_caller_address(), from, token_id, data
                        ) == constants::IERC721_RECEIVER_ID
                },
            }
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


#[starknet::contract]
mod ERC721 {
    use seraphlabs::tokens::constants;
    use super::super::interface;
    use interface::{IERC721ReceiverDispatcher, IERC721ReceiverDispatcherTrait};
    use seraphlabs::tokens::src5::{SRC5, interface::{ISRC5Dispatcher, ISRC5DispatcherTrait}};
    // corelib imports
    use starknet::{
        get_caller_address, contract_address_const, ContractAddress, ContractAddressIntoFelt252
    };

    #[storage]
    struct Storage {
        erc721_owners: LegacyMap::<u256, ContractAddress>,
        erc721_balances: LegacyMap::<ContractAddress, u256>,
        erc721_token_approvals: LegacyMap::<u256, ContractAddress>,
        erc721_operator_approvals: LegacyMap::<(ContractAddress, ContractAddress), bool>,
    }

    #[event]
    #[derive(Drop, PartialEq, starknet::Event)]
    enum Event {
        Transfer: Transfer,
        Approval: Approval,
        ApprovalForAll: ApprovalForAll,
    }

    #[derive(Drop, PartialEq, starknet::Event)]
    struct Transfer {
        #[key]
        from: ContractAddress,
        #[key]
        to: ContractAddress,
        #[key]
        token_id: u256,
    }

    #[derive(Drop, PartialEq, starknet::Event)]
    struct Approval {
        #[key]
        owner: ContractAddress,
        #[key]
        approved: ContractAddress,
        #[key]
        token_id: u256,
    }

    #[derive(Drop, PartialEq, starknet::Event)]
    struct ApprovalForAll {
        #[key]
        owner: ContractAddress,
        #[key]
        operator: ContractAddress,
        approved: bool,
    }

    #[external(v0)]
    impl IERC721Impl of interface::IERC721<ContractState> {
        fn balance_of(self: @ContractState, owner: ContractAddress) -> u256 {
            self.erc721_balances.read(owner)
        }

        fn owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            self._owner_of(token_id).expect('ERC721: invalid tokenId')
        }

        fn get_approved(self: @ContractState, token_id: u256) -> ContractAddress {
            assert(self._exist(token_id), 'ERC721: tokenId does not exist');
            self.erc721_token_approvals.read(token_id)
        }

        fn is_approved_for_all(
            self: @ContractState, owner: ContractAddress, operator: ContractAddress
        ) -> bool {
            self.erc721_operator_approvals.read((owner, operator))
        }

        fn approve(ref self: ContractState, approved: ContractAddress, token_id: u256) {
            let owner: ContractAddress = self._owner_of(token_id).expect('ERC721: invalid tokenId');
            let caller: ContractAddress = get_caller_address();
            assert(caller == owner, 'ERC721: invalid owner');
            self._approve(approved, token_id);
        }

        fn set_approval_for_all(
            ref self: ContractState, operator: ContractAddress, approved: bool
        ) {
            self._set_approval_for_all(operator, approved);
        }

        fn safe_transfer_from(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            data: Span<felt252>
        ) {
            let caller: ContractAddress = get_caller_address();
            assert(self._is_approved_or_owner(caller, token_id), 'ERC721: caller is not approved');
            self._safe_transfer(from, to, token_id, data);
        }

        fn transfer_from(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            let caller: ContractAddress = get_caller_address();
            assert(self._is_approved_or_owner(caller, token_id), 'ERC721: caller is not approved');
            self._transfer(from, to, token_id);
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn initializer(ref self: ContractState) {
            let mut unsafe_state = SRC5::unsafe_new_contract_state();
            SRC5::InternalImpl::register_interface(ref unsafe_state, constants::IERC721_ID);
        }

        fn _owner_of(self: @ContractState, token_id: u256) -> Option<ContractAddress> {
            let owner = self.erc721_owners.read(token_id);
            match owner.is_zero() {
                bool::False(()) => Option::Some(owner),
                bool::True(()) => Option::None(()),
            }
        }

        fn _exist(self: @ContractState, token_id: u256) -> bool {
            let owner = self.erc721_owners.read(token_id);
            !owner.is_zero()
        }

        fn _is_approved_or_owner(
            self: @ContractState, spender: ContractAddress, token_id: u256
        ) -> bool {
            assert(spender.is_non_zero(), 'ERC721: invalid caller');
            let owner: ContractAddress = self._owner_of(token_id).expect('ERC721: invalid tokenId');
            owner == spender
                || spender == self.erc721_token_approvals.read(token_id)
                || self.erc721_operator_approvals.read((owner, spender))
        }

        fn _transfer(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            let owner = self._owner_of(token_id).expect('ERC721: invalid tokenId');

            // ensures owner == from
            assert(owner == from, 'ERC721: invalid sender');
            // ensures to is not a zero address
            assert(!to.is_zero(), 'ERC721: invalid address');

            // clear approvals
            self.erc721_token_approvals.write(token_id, Zeroable::zero());

            // update balances
            self.erc721_balances.write(to, self.erc721_balances.read(to) + 1_u256);
            self.erc721_balances.write(from, self.erc721_balances.read(from) - 1_u256);

            // update owner
            self.erc721_owners.write(token_id, to);
            // emit event
            self.emit(Transfer { from, to, token_id });
        }

        fn _safe_transfer(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            data: Span<felt252>
        ) {
            self._transfer(from, to, token_id);
            assert(
                self._check_on_erc721_received(from, to, token_id, data), 'ERC721: reciever failed'
            );
        }

        fn _approve(ref self: ContractState, to: ContractAddress, token_id: u256) {
            let owner = self._owner_of(token_id).expect('ERC721: invalid tokenId');
            assert(owner != to, 'ERC721: owner cant approve self');
            self.erc721_token_approvals.write(token_id, to);
            self.emit(Approval { owner, approved: to, token_id });
        }

        fn _set_approval_for_all(
            ref self: ContractState, operator: ContractAddress, approved: bool
        ) {
            assert(!operator.is_zero(), 'ERC721: invalid address');

            let caller: ContractAddress = get_caller_address();
            assert(!caller.is_zero(), 'ERC721: invalid caller');

            assert(caller != operator, 'ERC721: owner cant approve self');

            self.erc721_operator_approvals.write((caller, operator), approved);
            self.emit(ApprovalForAll { owner: caller, operator, approved });
        }

        fn _mint(ref self: ContractState, to: ContractAddress, token_id: u256) {
            assert(!to.is_zero(), 'ERC721: invalid address');
            assert(token_id > 0_u256, 'ERC721: invalid tokenId');
            assert(!self._exist(token_id), 'ERC721: tokenId already exist');

            // update balances
            self.erc721_balances.write(to, self.erc721_balances.read(to) + 1.into());
            // update owner
            self.erc721_owners.write(token_id, to);
            // emit event
            self.emit(Transfer { from: Zeroable::zero(), to, token_id });
        }

        fn _safe_mint(
            ref self: ContractState, to: ContractAddress, token_id: u256, data: Span<felt252>
        ) {
            self._mint(to, token_id);
            assert(
                self._check_on_erc721_received(Zeroable::zero(), to, token_id, data),
                'ERC721: reciever failed'
            );
        }

        fn _burn(ref self: ContractState, token_id: u256) {
            // ensures tokenId has owner
            let owner = self._owner_of(token_id).expect('ERC721: invalid tokenId');

            // clear approvals
            self.erc721_token_approvals.write(token_id, Zeroable::zero());

            // update balances
            self.erc721_balances.write(owner, self.erc721_balances.read(owner) - 1.into());

            // update owner
            self.erc721_owners.write(token_id, Zeroable::zero());

            // emit event
            self.emit(Transfer { from: owner, to: Zeroable::zero(), token_id });
        }


        fn _check_on_erc721_received(
            self: @ContractState,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            data: Span<felt252>
        ) -> bool {
            let support_interface = ISRC5Dispatcher { contract_address: to }
                .supports_interface(constants::IERC721_RECEIVER_ID);
            match support_interface {
                bool::False(()) => ISRC5Dispatcher { contract_address: to }
                    .supports_interface(constants::ISRC6_ID),
                bool::True(()) => {
                    IERC721ReceiverDispatcher { contract_address: to }
                        .on_erc721_received(
                            get_caller_address(), from, token_id, data
                        ) == constants::IERC721_RECEIVER_ID
                },
            }
        }
    }
}

