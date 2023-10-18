#[starknet::component]
mod ERC3525Component {
    use core::zeroable::Zeroable;
    use seraphlabs::tokens::constants;
    use seraphlabs::tokens::erc3525::interface;
    use interface::{IERC3525ReceiverDispatcher, IERC3525ReceiverDispatcherTrait};
    use seraphlabs::tokens::erc3525::utils::{
        ApprovedUnits, ApprovedUnitsTrait, OperatorIndex, OperatorIndexTrait
    };
    use seraphlabs::tokens::src5::{
        SRC5Component, interface::{ISRC5Dispatcher, ISRC5DispatcherTrait}
    };
    use seraphlabs::tokens::erc721::ERC721Component;
    use seraphlabs::tokens::erc721::extensions::ERC721EnumComponent;

    use SRC5Component::SRC5InternalImpl;
    use ERC721Component::{ERC721InternalImpl, IERC721Impl};
    use ERC721EnumComponent::ERC721EnumInternalImpl;

    // corelib imports
    use starknet::{
        get_caller_address, contract_address_const, ContractAddress, ContractAddressIntoFelt252
    };
    use integer::BoundedInt;

    #[storage]
    struct Storage {
        erc3525_decimals: u8,
        erc3525_slot: LegacyMap::<u256, u256>,
        erc3525_units: LegacyMap::<u256, u256>,
        // (token_id, index) -> (units, operator)
        erc3525_unit_level_approvals: LegacyMap::<(u256, u16), ApprovedUnits>,
        // to track the higest token minted
        erc3525_max_token_id: u256,
    }

    #[event]
    #[derive(Drop, PartialEq, starknet::Event)]
    enum Event {
        TransferValue: TransferValue,
        ApprovalValue: ApprovalValue,
        SlotChanged: SlotChanged,
    }

    #[derive(Drop, PartialEq, starknet::Event)]
    struct TransferValue {
        #[key]
        from_token_id: u256,
        #[key]
        to_token_id: u256,
        value: u256,
    }

    #[derive(Drop, PartialEq, starknet::Event)]
    struct ApprovalValue {
        #[key]
        token_id: u256,
        #[key]
        operator: ContractAddress,
        value: u256
    }

    #[derive(Drop, PartialEq, starknet::Event)]
    struct SlotChanged {
        #[key]
        token_id: u256,
        #[key]
        old_slot: u256,
        #[key]
        new_slot: u256,
    }

    // -------------------------------------------------------------------------- //
    //                               For Embeddable                               //
    // -------------------------------------------------------------------------- //

    #[embeddable_as(ERC3525Impl)]
    impl ERC3525<
        TContractState,
        +HasComponent<TContractState>,
        +ERC721Component::HasComponent<TContractState>,
        +ERC721EnumComponent::HasComponent<TContractState>,
        +Drop<TContractState>
    > of interface::IERC3525<ComponentState<TContractState>> {
        fn value_decimals(self: @ComponentState<TContractState>) -> u8 {
            IERC3525Impl::value_decimals(self)
        }

        fn value_of(self: @ComponentState<TContractState>, token_id: u256) -> u256 {
            IERC3525Impl::value_of(self, token_id)
        }

        fn slot_of(self: @ComponentState<TContractState>, token_id: u256) -> u256 {
            IERC3525Impl::slot_of(self, token_id)
        }

        fn approve_value(
            ref self: ComponentState<TContractState>,
            token_id: u256,
            operator: ContractAddress,
            value: u256
        ) {
            IERC3525Impl::approve_value(ref self, token_id, operator, value);
        }

        fn allowance(
            self: @ComponentState<TContractState>, token_id: u256, operator: ContractAddress
        ) -> u256 {
            IERC3525Impl::allowance(self, token_id, operator)
        }

        fn transfer_value_from(
            ref self: ComponentState<TContractState>,
            from_token_id: u256,
            to: ContractAddress,
            value: u256
        ) -> u256 {
            IERC3525Impl::transfer_value_from(ref self, from_token_id, to, value)
        }
    }

    // -------------------------------------------------------------------------- //
    //                                 Initializer                                //
    // -------------------------------------------------------------------------- //

    #[generate_trait]
    impl ERC3525InitializerImpl<
        TContractState,
        +HasComponent<TContractState>,
        +SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>
    > of ERC3525InitializerTrait<TContractState> {
        fn initializer(ref self: ComponentState<TContractState>, value_decimals: u8) {
            let mut src5 = self.get_src5_mut();
            src5.register_interface(constants::IERC3525_ID);
            self.erc3525_decimals.write(value_decimals);
        }
    }

    // -------------------------------------------------------------------------- //
    //                             External Functions                             //
    // -------------------------------------------------------------------------- //

    #[generate_trait]
    impl IERC3525Impl<
        TContractState,
        +HasComponent<TContractState>,
        +ERC721Component::HasComponent<TContractState>,
        +ERC721EnumComponent::HasComponent<TContractState>,
        +Drop<TContractState>
    > of IERC3525ImplTrait<TContractState> {
        #[inline(always)]
        fn value_decimals(self: @ComponentState<TContractState>) -> u8 {
            self.erc3525_decimals.read()
        }

        #[inline(always)]
        fn value_of(self: @ComponentState<TContractState>, token_id: u256) -> u256 {
            self.erc3525_units.read(token_id)
        }

        #[inline(always)]
        fn slot_of(self: @ComponentState<TContractState>, token_id: u256) -> u256 {
            self.erc3525_slot.read(token_id)
        }

        #[inline(always)]
        fn approve_value(
            ref self: ComponentState<TContractState>,
            token_id: u256,
            operator: ContractAddress,
            value: u256
        ) {
            let caller = get_caller_address();
            assert(!caller.is_zero(), 'ERC3525: invalid caller');
            assert(!operator.is_zero(), 'ERC3525: invalid operator');

            let mut erc721 = self.get_erc721_mut();
            let owner = erc721.owner_of(token_id);
            // assert owner is not operator
            assert(owner != operator, 'ERC3525: approval to owner');
            // assert caller is approved or owner 
            assert(erc721._is_approved_or_owner(caller, token_id), 'ERC3525: caller not approved');
            self._approve_value(token_id, operator, value);
        }

        #[inline(always)]
        fn allowance(
            self: @ComponentState<TContractState>, token_id: u256, operator: ContractAddress
        ) -> u256 {
            let index = self._find_operator_index(token_id, operator);
            match index {
                OperatorIndex::Contain(x) => {
                    let approved: ApprovedUnits = self
                        .erc3525_unit_level_approvals
                        .read((token_id, x));
                    approved.units
                },
                OperatorIndex::Empty(_) => { BoundedInt::min() }
            }
        }

        #[inline(always)]
        fn transfer_value_from(
            ref self: ComponentState<TContractState>,
            from_token_id: u256,
            to: ContractAddress,
            value: u256
        ) -> u256 {
            // assert value is not zero
            assert(value.is_non_zero(), 'ERC3525: invalid value');
            // assert caller is valid
            let caller = get_caller_address();
            assert(caller.is_non_zero(), 'ERC3525: invalid caller');
            // checks for tokenId level approval and above
            // if not there check for value level approval and spend allowance
            // functions already check if `from_tokenId` exist
            let mut erc721 = self.get_erc721_mut();
            if !erc721._is_approved_or_owner(caller, from_token_id) {
                self._spend_allownce(from_token_id, caller, value);
            }
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
    // -------------------------------------------------------------------------- //
    //                             Internal Functions                             //
    // -------------------------------------------------------------------------- //

    #[generate_trait]
    impl ERC3525InternalImpl<
        TContractState,
        +HasComponent<TContractState>,
        +ERC721Component::HasComponent<TContractState>,
        +ERC721EnumComponent::HasComponent<TContractState>,
        +Drop<TContractState>
    > of ERC3525InternalTrait<TContractState> {
        #[inline(always)]
        fn _mint(
            ref self: ComponentState<TContractState>,
            to: ContractAddress,
            token_id: u256,
            slot_id: u256,
            value: u256
        ) {
            let mut erc721_enum = self.get_erc721_enum_mut();
            // @dev this function already checks if token_id exist
            //  and if to address is non zero
            //  erc721 enum propogates the checking to erc721
            // mint actual token
            erc721_enum._mint(to, token_id);
            // mint token values and slot
            // this functionm EMITs SlotChanged and TransferValue events
            self._unsafe_mint(to, token_id, slot_id, value);
        }

        // @dev mints value straight to a token
        #[inline(always)]
        fn _mint_value(ref self: ComponentState<TContractState>, to_token_id: u256, value: u256) {
            // assert valid to value
            assert(value.is_non_zero(), 'ERC3525: invalid value');
            // assert token_id exist
            assert(self.get_erc721()._exist(to_token_id), 'ERC3525: invalid token_id');
            // increase to units
            self.erc3525_units.write(to_token_id, self.erc3525_units.read(to_token_id) + value);
            // emit event
            self.emit(TransferValue { from_token_id: 0, to_token_id, value })
        }


        #[inline(always)]
        fn _burn(ref self: ComponentState<TContractState>, token_id: u256) {
            let mut erc721_enum = self.get_erc721_enum_mut();
            // function already checks if token_id exist
            erc721_enum._burn(token_id);
            // clear value approvals
            self._clear_value_approvals(token_id);
            // get slot and units
            let slot_id = self.erc3525_slot.read(token_id);
            let value = self.erc3525_units.read(token_id);
            // clear slot and units
            self.erc3525_slot.write(token_id, 0_u256);
            self.erc3525_units.write(token_id, 0_u256);
            // emit events
            self.emit(SlotChanged { token_id, old_slot: slot_id, new_slot: 0_u256 });
            self.emit(TransferValue { from_token_id: token_id, to_token_id: 0_u256, value });
        }

        #[inline(always)]
        fn _burn_value(ref self: ComponentState<TContractState>, token_id: u256, value: u256) {
            assert(self.get_erc721()._exist(token_id), 'ERC3525: invalid tokenId');
            assert(value > 0_u256, 'ERC3525: invalid value');
            // decrease token units
            let token_units = self.erc3525_units.read(token_id);
            assert(token_units >= value, 'ERC3525: insufficient balance');
            self.erc3525_units.write(token_id, token_units - value);
            // emit event
            self.emit(TransferValue { from_token_id: token_id, to_token_id: 0_u256, value });
        }

        #[inline(always)]
        fn _approve_value(
            ref self: ComponentState<TContractState>,
            token_id: u256,
            operator: ContractAddress,
            value: u256
        ) {
            match self._find_operator_index(token_id, operator) {
                OperatorIndex::Contain(x) => {
                    // if operator already approved update value
                    self
                        .erc3525_unit_level_approvals
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
                        .erc3525_unit_level_approvals
                        .write((token_id, x), ApprovedUnitsTrait::new(value, operator));
                }
            }
            self.emit(ApprovalValue { token_id, operator, value });
        }

        #[inline(always)]
        fn _spend_allownce(
            ref self: ComponentState<TContractState>,
            token_id: u256,
            operator: ContractAddress,
            value: u256
        ) {
            // does not check if operator is a zero address
            // method will revert if index returned is from a empty slot, means operator not approved
            let index = self
                ._find_operator_index(token_id, operator)
                .expect_contains('ERC3525: insufficient allowance');
            let mut value_approvals = self.erc3525_unit_level_approvals.read((token_id, index));
            // spend units , method alrady checks for value exceeding units
            value_approvals.spend_units(value);
            self.erc3525_unit_level_approvals.write((token_id, index), value_approvals);
            //  emit event
            self.emit(ApprovalValue { token_id, operator, value: value_approvals.units });
        }

        // @dev transfers value from a token_id to address
        //  checks if `to` address has a token with the same slot as `from_token_id`
        //  if it does not then mint a new token with the same slot and transfer value to it
        //  else transfer value to the token with the same slot
        //  DOES NOT check validity of from_token_id
        //  DOES Not spend allowance
        #[inline(always)]
        fn _transfer_value_to_address(
            ref self: ComponentState<TContractState>,
            from_token_id: u256,
            to: ContractAddress,
            value: u256
        ) -> u256 {
            // assert valid to adderss
            assert(to.is_non_zero(), 'ERC3525: invalid address');
            // find token_id with same slot to transfer if not generate new token_id and mint
            let token_id = match self._find_same_slot_token_id(from_token_id, to) {
                Option::Some(x) => x,
                Option::None(_) => {
                    let new_token_id = self._generate_new_token_id();
                    self._mint(to, new_token_id, self.erc3525_slot.read(from_token_id), 0);
                    new_token_id
                },
            };
            // this function emits TransferValue event
            self._transfer_value(from_token_id, token_id, value);
            token_id
        }

        // @dev transfers value from a token_id to another token_id
        //  DOES NOT check validity of from_token_id 
        //  DOES NOT check approval of from_token_id 
        //  DOES NOT spend approval allowance
        //  DOES check validity of to_token_id
        //  DOES check if value exceed from_token_id units
        //  EMITS TransferValue event
        #[inline(always)]
        fn _transfer_value(
            ref self: ComponentState<TContractState>,
            from_token_id: u256,
            to_token_id: u256,
            value: u256
        ) {
            // checks if to_token_id exist
            assert(self.get_erc721_mut()._exist(to_token_id), 'ERC3525: invalid tokenId');
            // assert from and to tokenIds are different
            assert(from_token_id != to_token_id, 'ERC3525: cant transfer self');
            // checks tokenIds have the same slot
            assert(
                self.erc3525_slot.read(from_token_id) == self.erc3525_slot.read(to_token_id),
                'ERC3525: different slots'
            );
            // asserts that value does not exceend balance
            let from_units = self.erc3525_units.read(from_token_id);
            assert(from_units >= value, 'ERC3525: insufficient balance');
            // decrease from units and increase to units
            self.erc3525_units.write(from_token_id, from_units - value);
            self.erc3525_units.write(to_token_id, self.erc3525_units.read(to_token_id) + value);
            // emit event
            self.emit(TransferValue { from_token_id, to_token_id, value });
        }


        // @dev clear all operator value approvals for token_id
        //  Mainly used for transfer functions outside of ERC3525
        //  when transfering or burning a token
        fn _clear_value_approvals(ref self: ComponentState<TContractState>, token_id: u256) {
            let mut index = 0;
            loop {
                // if zero break else clear approval slot
                match self.erc3525_unit_level_approvals.read((token_id, index)).is_zero() {
                    bool::False => {
                        self
                            .erc3525_unit_level_approvals
                            .write((token_id, index), Zeroable::zero());
                        index += 1;
                    },
                    bool::True => { break; }
                };
            }
        }
    }

    // -------------------------------------------------------------------------- //
    //                              Private Functions                             //
    // -------------------------------------------------------------------------- //

    #[generate_trait]
    impl ERC3525PrivateImpl<
        TContractState,
        +HasComponent<TContractState>,
        +ERC721Component::HasComponent<TContractState>,
        +ERC721EnumComponent::HasComponent<TContractState>,
        +Drop<TContractState>
    > of ERC3525PrivateTrait<TContractState> {
        // @dev loops through token_id operators to find operator
        fn _find_operator_index(
            self: @ComponentState<TContractState>, token_id: u256, operator: ContractAddress
        ) -> OperatorIndex<u16> {
            let mut index: u16 = 0;
            // if operator found break else loop
            // until empty slot is found 
            let new_index = loop {
                let value_approvals = self.erc3525_unit_level_approvals.read((token_id, index));
                if value_approvals.is_zero() {
                    break OperatorIndex::Empty(index);
                } else if value_approvals.operator == operator {
                    break OperatorIndex::Contain(index);
                }
                index += 1;
            };
            new_index
        }

        // @dev loops through `to` address owned tokens to find a token with same slot
        fn _find_same_slot_token_id(
            self: @ComponentState<TContractState>, from_token_id: u256, to: ContractAddress
        ) -> Option<u256> {
            let mut index = 0;
            let slot = self.erc3525_slot.read(from_token_id);
            let erc721_enum = self.get_erc721_enum();

            let found_token_id = loop {
                // use internal function so function wont revert on out of bounds index
                match erc721_enum._token_of_owner_by_index(to, index) {
                    Option::Some(x) => {
                        // if x == from_token_id or slot not the same  skip
                        // else break and return token_id
                        if x == from_token_id || self.erc3525_slot.read(x) != slot {
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

        // @dev assumes highest token id is the last token minted
        //  else loop and find the next available token
        //  this is gas inefficient so if ussing this function should ensure that tokens are minted sequentially
        fn _generate_new_token_id(self: @ComponentState<TContractState>) -> u256 {
            // if not loop and find the next available token
            let highest = self.erc3525_max_token_id.read();
            let mut new_token_id = highest + 1_u256;

            let erc721 = self.get_erc721();
            loop {
                if !erc721._exist(new_token_id) {
                    break ();
                }
                new_token_id += 1_u256;
            };
            new_token_id
        }

        #[inline(always)]
        fn _check_max_token_id(ref self: ComponentState<TContractState>, token_id: u256) {
            // if token_id is greater than max_token_id update max_token_id
            if token_id > self.erc3525_max_token_id.read() {
                self.erc3525_max_token_id.write(token_id);
            }
        }

        // @dev mints a new token without any assertions
        // does not actually mint a token just updates 3525 storage
        #[inline(always)]
        fn _unsafe_mint(
            ref self: ComponentState<TContractState>,
            to: ContractAddress,
            token_id: u256,
            slot_id: u256,
            value: u256
        ) {
            // check if token_id is greater than max_token_id
            // if it is set mac token id 
            self._check_max_token_id(token_id);

            self.erc3525_slot.write(token_id, slot_id);
            self.erc3525_units.write(token_id, value);
            // emit event
            self.emit(SlotChanged { token_id, old_slot: 0, new_slot: slot_id });
            self.emit(TransferValue { from_token_id: 0, to_token_id: token_id, value });
        }

        #[inline(always)]
        fn _check_on_erc3525_received(
            self: @ComponentState<TContractState>,
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

    #[generate_trait]
    impl GetERC721Enum<
        TContractState,
        +HasComponent<TContractState>,
        +ERC721EnumComponent::HasComponent<TContractState>,
        +Drop<TContractState>
    > of GetERC721EnumTrait<TContractState> {
        #[inline(always)]
        fn get_erc721_enum(
            self: @ComponentState<TContractState>
        ) -> @ERC721EnumComponent::ComponentState<TContractState> {
            let contract = self.get_contract();
            ERC721EnumComponent::HasComponent::<TContractState>::get_component(contract)
        }

        #[inline(always)]
        fn get_erc721_enum_mut(
            ref self: ComponentState<TContractState>
        ) -> ERC721EnumComponent::ComponentState<TContractState> {
            let mut contract = self.get_contract_mut();
            ERC721EnumComponent::HasComponent::<TContractState>::get_component_mut(ref contract)
        }
    }
}
