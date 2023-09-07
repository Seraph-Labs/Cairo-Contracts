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
        _owners: LegacyMap::<u256, ContractAddress>,
        _balances: LegacyMap::<ContractAddress, u256>,
        _token_approvals: LegacyMap::<u256, ContractAddress>,
        _operator_approvals: LegacyMap::<(ContractAddress, ContractAddress), bool>,
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
            self._balances.read(owner)
        }

        fn owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            self._owner_of(token_id).expect('ERC721: invalid tokenId')
        }

        fn get_approved(self: @ContractState, token_id: u256) -> ContractAddress {
            assert(self._exist(token_id), 'ERC721: tokenId does not exist');
            self._token_approvals.read(token_id)
        }

        fn is_approved_for_all(
            self: @ContractState, owner: ContractAddress, operator: ContractAddress
        ) -> bool {
            self._operator_approvals.read((owner, operator))
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
            let owner = self._owners.read(token_id);
            match owner.is_zero() {
                bool::False(()) => Option::Some(owner),
                bool::True(()) => Option::None(()),
            }
        }

        fn _exist(self: @ContractState, token_id: u256) -> bool {
            let owner = self._owners.read(token_id);
            !owner.is_zero()
        }

        fn _is_approved_or_owner(
            self: @ContractState, spender: ContractAddress, token_id: u256
        ) -> bool {
            let owner: ContractAddress = self._owner_of(token_id).expect('ERC721: invalid tokenId');
            owner == spender
                || spender == self._token_approvals.read(token_id)
                || self._operator_approvals.read((owner, spender))
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
            self._token_approvals.write(token_id, Zeroable::zero());

            // update balances
            self._balances.write(to, self._balances.read(to) + 1_u256);
            self._balances.write(from, self._balances.read(from) - 1_u256);

            // update owner
            self._owners.write(token_id, to);
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
            self._token_approvals.write(token_id, to);
            self.emit(Approval { owner, approved: to, token_id });
        }

        fn _set_approval_for_all(
            ref self: ContractState, operator: ContractAddress, approved: bool
        ) {
            assert(!operator.is_zero(), 'ERC721: invalid address');

            let caller: ContractAddress = get_caller_address();
            assert(!caller.is_zero(), 'ERC721: invalid address');

            assert(caller != operator, 'ERC721: owner cant approve self');

            self._operator_approvals.write((caller, operator), approved);
            self.emit(ApprovalForAll { owner: caller, operator, approved });
        }

        fn _mint(ref self: ContractState, to: ContractAddress, token_id: u256) {
            assert(!to.is_zero(), 'ERC721: invalid address');
            assert(token_id > 0_u256, 'ERC721: invalid tokenId');
            assert(!self._exist(token_id), 'ERC721: tokenId already exist');

            // update balances
            self._balances.write(to, self._balances.read(to) + 1.into());
            // update owner
            self._owners.write(token_id, to);
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
            self._token_approvals.write(token_id, Zeroable::zero());

            // update balances
            self._balances.write(owner, self._balances.read(owner) - 1.into());

            // update owner
            self._owners.write(token_id, Zeroable::zero());

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
