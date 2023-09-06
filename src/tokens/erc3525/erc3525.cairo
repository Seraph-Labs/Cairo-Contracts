#[starknet::contract]
mod ERC3525 {
    use seraphlabs::tokens::constants;
    use seraphlabs::tokens::erc3525::interface;
    use interface::{IERC3525ReceiverDispatcher, IERC3525ReceiverDispatcherTrait};
    use seraphlabs::tokens::erc3525::utils::{
        ApprovedUnits, ApprovedUnitsTrait, OperatorIndex, OperatorIndexTrait
    };
    use seraphlabs::tokens::src5::{SRC5, interface::{ISRC5Dispatcher, ISRC5DispatcherTrait}};
    use seraphlabs::tokens::erc721::ERC721;
    use seraphlabs::tokens::erc721::extensions::ERC721Enumerable as ERC721Enum;
    // corelib imports
    use starknet::{
        get_caller_address, contract_address_const, ContractAddress, ContractAddressIntoFelt252
    };
    use integer::BoundedInt;

    #[storage]
    struct Storage {
        decimals: u8,
        slot: LegacyMap::<u256, u256>,
        units: LegacyMap::<u256, u256>,
        // (token_id, index) -> (units, operator)
        unit_level_approvals: LegacyMap::<(u256, u16), ApprovedUnits>,
        // to track the higest token minted
        max_token_id: u256,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        TransferValue: TransferValue,
        ApprovalValue: ApprovalValue,
        SlotChanged: SlotChanged,
    }

    #[derive(Drop, starknet::Event)]
    struct TransferValue {
        #[key]
        from_token_id: u256,
        #[key]
        to_token_id: u256,
        value: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct ApprovalValue {
        #[key]
        token_id: u256,
        #[key]
        operator: ContractAddress,
        value: u256
    }

    #[derive(Drop, starknet::Event)]
    struct SlotChanged {
        #[key]
        token_id: u256,
        #[key]
        old_slot: u256,
        #[key]
        new_slot: u256,
    }

    #[external(v0)]
    impl IERC3525Impl of interface::IERC3525<ContractState> {
        fn value_decimals(self: @ContractState,) -> u8 {
            self.decimals.read()
        }

        fn value_of(self: @ContractState, token_id: u256) -> u256 {
            self.units.read(token_id)
        }

        fn slot_of(self: @ContractState, token_id: u256) -> u256 {
            self.slot.read(token_id)
        }

        fn approve_value(
            ref self: ContractState, token_id: u256, operator: ContractAddress, value: u256
        ) {
            let caller = get_caller_address();
            assert(!caller.is_zero(), 'ERC3525: invalid caller');
            assert(!operator.is_zero(), 'ERC3525: invalid operator');

            let unsafe_state = ERC721::unsafe_new_contract_state();
            let owner = ERC721::IERC721Impl::owner_of(@unsafe_state, token_id);
            // assert owner is not operator
            assert(owner != operator, 'ERC3525: approval to owner');
            // assert caller is approved or owner 
            assert(
                ERC721::InternalImpl::_is_approved_or_owner(@unsafe_state, caller, token_id),
                'ERC3525: caller not approved'
            );
            self._approve_value(token_id, operator, value);
        }

        fn allowance(self: @ContractState, token_id: u256, operator: ContractAddress) -> u256 {
            let index = self._find_operator_index(token_id, operator);
            match index {
                OperatorIndex::Contain(x) => {
                    self.unit_level_approvals.read((token_id, x)).units
                },
                OperatorIndex::Empty(_) => {
                    BoundedInt::min()
                }
            }
        }

        fn transfer_value_from(
            ref self: ContractState, from_token_id: u256, to: ContractAddress, value: u256
        ) -> u256 {
            assert(value != 0.into(), 'ERC3525: invalid value');
            let token_id = self._transfer_value_to_address(from_token_id, to, value);
            let data = ArrayTrait::<felt252>::new();
            assert(
                self
                    ._check_on_erc3525_received(
                        to, get_caller_address(), from_token_id, token_id, value, data.span()
                    ),
                'ERC3525: reciever failed'
            );
            token_id
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn initializer(ref self: ContractState, value_decimals: u8) {
            let mut unsafe_state = SRC5::unsafe_new_contract_state();
            SRC5::InternalImpl::register_interface(ref unsafe_state, constants::IERC3525_ID);
            self.decimals.write(value_decimals);
        }

        fn _mint(
            ref self: ContractState, to: ContractAddress, token_id: u256, slot_id: u256, value: u256
        ) {
            // assert valid to address
            assert(!to.is_zero(), 'ERC3525: invalid to address');
            // assert token_id does not exist
            let unsafe_state = ERC721::unsafe_new_contract_state();
            assert(
                !ERC721::InternalImpl::_exist(@unsafe_state, token_id),
                'ERC3525: token already exist'
            );
            assert(token_id != 0.into(), 'ERC3525: invalid token_id');
            // mint token
            self._mint_new(to, token_id, slot_id, value);
        }

        fn _mint_value(ref self: ContractState, to_token_id: u256, value: u256) {
            let unsafe_state = ERC721::unsafe_new_contract_state();
            assert(
                ERC721::InternalImpl::_exist(@unsafe_state, to_token_id), 'ERC3525: invalid tokenId'
            );

            assert(value != 0.into(), 'ERC3525: invalid value');
            // increase to units
            self.units.write(to_token_id, self.units.read(to_token_id) + value);
            // emit event
            self.emit(TransferValue { from_token_id: 0.into(), to_token_id, value })
        }

        fn _burn(ref self: ContractState, token_id: u256) {
            let mut unsafe_state = ERC721Enum::unsafe_new_contract_state();
            // function already checks if token_id exist
            ERC721Enum::InternalImpl::_burn(ref unsafe_state, token_id);
            // clear value approvals
            self._clear_value_approvals(token_id);
            // get slot and units
            let slot_id = self.slot.read(token_id);
            let value = self.units.read(token_id);
            // clear slot and units
            self.slot.write(token_id, 0_u256);
            self.units.write(token_id, 0_u256);
            // emit events
            self.emit(SlotChanged { token_id, old_slot: slot_id, new_slot: 0_u256 });
            self.emit(TransferValue { from_token_id: token_id, to_token_id: 0_u256, value });
        }

        fn _burn_value(ref self: ContractState, token_id: u256, value: u256) {
            let unsafe_state = ERC721::unsafe_new_contract_state();
            assert(
                ERC721::InternalImpl::_exist(@unsafe_state, token_id), 'ERC3525: invalid tokenId'
            );
            assert(value > 0_u256, 'ERC3525: invalid value');
            // decrease token units
            let token_units = self.units.read(token_id);
            assert(token_units >= value, 'ERC3525: insufficient balance');
            self.units.write(token_id, token_units - value);
            // emit event
            self.emit(TransferValue { from_token_id: token_id, to_token_id: 0_u256, value });
        }

        fn _approve_value(
            ref self: ContractState, token_id: u256, operator: ContractAddress, value: u256
        ) {
            let index = self._find_operator_index(token_id, operator);
            match index {
                OperatorIndex::Contain(x) => {
                    // if operator already approved update value
                    self
                        .unit_level_approvals
                        .write((token_id, x), ApprovedUnitsTrait::new(value, operator));
                },
                OperatorIndex::Empty(x) => {
                    // if operator not approved add new approval
                    // unless value is zero the skip and dont add approvasls
                    // if value is zero and operator was never registered to save space 
                    // dont add them to the approval array
                    if value == 0_u256 {
                        return ();
                    }

                    self
                        .unit_level_approvals
                        .write((token_id, x), ApprovedUnitsTrait::new(value, operator));
                }
            }
            self.emit(ApprovalValue { token_id, operator, value });
        }

        fn _spend_allownce(
            ref self: ContractState, token_id: u256, operator: ContractAddress, value: u256
        ) {
            //* does not check if operator is a zero address
            // method will revert if index returned is rom a empty slot, means operator not approved
            let index = self
                ._find_operator_index(token_id, operator)
                .expect_contains('ERC3525: operator not approved');
            let mut value_approvals = self.unit_level_approvals.read((token_id, index));
            // spend units , method alrady checks for value exceeding units
            value_approvals.spend_units(value);
            self.unit_level_approvals.write((token_id, index), value_approvals);
            //  emit event
            self.emit(ApprovalValue { token_id, operator, value: value_approvals.units });
        }

        fn _transfer_value_to_address(
            ref self: ContractState, from_token_id: u256, to: ContractAddress, value: u256
        ) -> u256 {
            // assert valid to adderss
            assert(!to.is_zero(), 'ERC3525: invalid address');
            // find token_id with same slot to transfer if not generate new token_id and mint
            let token_id = match self._find_same_slot_token_id(from_token_id, to) {
                Option::Some(x) => x,
                Option::None(_) => {
                    let new_token_id = self._generate_new_token_id();
                    self._mint_new(to, new_token_id, self.slot.read(from_token_id), 0.into());
                    new_token_id
                },
            };
            self._transfer_value(from_token_id, token_id, value);
            token_id
        }

        fn _transfer_value(
            ref self: ContractState, from_token_id: u256, to_token_id: u256, value: u256
        ) {
            // assert caller is valid
            let caller = get_caller_address();
            assert(!caller.is_zero(), 'ERC3525: invalid caller');
            // checks for tokenId level approval and above
            // if not there check for value level approval and spend allowance
            // functions already check if from_tokenId exist
            let unsafe_state = ERC721::unsafe_new_contract_state();
            if !ERC721::InternalImpl::_is_approved_or_owner(@unsafe_state, caller, from_token_id) {
                self._spend_allownce(from_token_id, caller, value);
            }
            // checks if to_token_id exist
            assert(
                ERC721::InternalImpl::_exist(@unsafe_state, to_token_id), 'ERC3525: invalid tokenId'
            );
            // assert from and to tokenIds are different
            assert(from_token_id != to_token_id, 'ERC3525: cant transfer self');
            // checks tokenIds have the same slot
            assert(
                self.slot.read(from_token_id) == self.slot.read(to_token_id),
                'ERC3525: different slots'
            );
            // asserts that value does not exceend balance
            let from_units = self.units.read(from_token_id);
            assert(from_units >= value, 'ERC3525: insufficient balance');
            // decrease from units and increase to units
            self.units.write(from_token_id, from_units - value);
            self.units.write(to_token_id, self.units.read(to_token_id) + value);
            // emit event
            self.emit(TransferValue { from_token_id, to_token_id, value });
        }

        fn _mint_new(
            ref self: ContractState, to: ContractAddress, token_id: u256, slot_id: u256, value: u256
        ) {
            //? internal mint function does not check for assertions or on ERC3525Received
            let mut unsafe_state = ERC721Enum::unsafe_new_contract_state();
            ERC721Enum::InternalImpl::_mint(ref unsafe_state, to, token_id);
            // check if token_id is greater than max_token_id
            self._check_max_token_id(token_id);

            self.slot.write(token_id, slot_id);
            self.units.write(token_id, value);
            // emit event
            self.emit(SlotChanged { token_id, old_slot: 0.into(), new_slot: slot_id });
            self.emit(TransferValue { from_token_id: 0.into(), to_token_id: token_id, value });
        }

        fn _clear_value_approvals(ref self: ContractState, token_id: u256) {
            let mut index = 0;
            loop {
                // if zero break else clear approval slot
                let value_approvals = self.unit_level_approvals.read((token_id, index));
                if value_approvals.is_zero() {
                    break ();
                }
                self.unit_level_approvals.write((token_id, index), Zeroable::zero());
                index += 1;
            }
        }
    }

    #[generate_trait]
    impl PrivateImpl of PrivateTrait {
        fn _find_operator_index(
            self: @ContractState, token_id: u256, operator: ContractAddress
        ) -> OperatorIndex<u16> {
            let mut index: u16 = 0;
            // if operator found break else loop
            // until empty slot is found 
            let new_index = loop {
                let value_approvals = self.unit_level_approvals.read((token_id, index));
                if value_approvals.is_zero() {
                    break OperatorIndex::Empty(index);
                } else if value_approvals.operator == operator {
                    break OperatorIndex::Contain(index);
                }
                index += 1;
            };
            new_index
        }

        fn _find_same_slot_token_id(
            self: @ContractState, from_token_id: u256, to: ContractAddress
        ) -> Option<u256> {
            let mut index = 0;
            let slot = self.slot.read(from_token_id);
            let unsafe_state = ERC721Enum::unsafe_new_contract_state();

            let found_token_id = loop {
                // use internal function so function wont revert on out of bounds index
                match ERC721Enum::InternalImpl::_token_of_owner_by_index(
                    @unsafe_state, to, index.into()
                ) {
                    Option::Some(x) => {
                        // if x == from_token_id or slot not the same  skip
                        // else break and return token_id
                        if x == from_token_id || self.slot.read(x) != slot {
                            index += 1;
                            continue;
                        } else {
                            break Option::Some(x);
                        }
                    },
                    Option::None(_) => {
                        // if None means end of token of owner array reached
                        break Option::None(());
                    }
                };
            };
            found_token_id
        }

        fn _generate_new_token_id(self: @ContractState) -> u256 {
            //? gets the current higest token and assumes next token is available
            // if not loop and find the next available token
            let highest = self.max_token_id.read();
            let mut new_token_id = highest + 1_u256;

            let unsafe_state = ERC721::unsafe_new_contract_state();
            loop {
                if !ERC721::InternalImpl::_exist(@unsafe_state, new_token_id) {
                    break ();
                }
                new_token_id += 1_u256;
            };
            new_token_id
        }

        fn _check_max_token_id(ref self: ContractState, token_id: u256) {
            // if token_id is greater than max_token_id update max_token_id
            if token_id > self.max_token_id.read() {
                self.max_token_id.write(token_id);
            }
        }

        fn _check_on_erc3525_received(
            self: @ContractState,
            to: ContractAddress,
            operator: ContractAddress,
            from_token_id: u256,
            to_token_id: u256,
            value: u256,
            data: Span<felt252>
        ) -> bool {
            let support_interface = ISRC5Dispatcher { contract_address: to }
                .supports_interface(constants::IERC3525_RECEIVER_ID);
            match support_interface {
                bool::False(()) => ISRC5Dispatcher { contract_address: to }
                    .supports_interface(constants::ISRC6_ID),
                bool::True(()) => {
                    IERC3525ReceiverDispatcher { contract_address: to }
                        .on_erc3525_received(
                            operator, from_token_id, to_token_id, value, data
                        ) == constants::IERC3525_RECEIVER_ID
                },
            }
        }
    }
}
