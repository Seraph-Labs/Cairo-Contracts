// SPDX-License-Identifier: AGPL-3.0
// SeraphLabs Contracts for Cairo >=v2.2.0 (tokens/erc2114/extensions/slot_attribute.cairo)
#[starknet::component]
mod ERC2114SlotAttrComponent {
    use core::array::ArrayTrait;
    use seraphlabs::tokens::constants;
    use seraphlabs::tokens::erc2114::interface;
    use interface::{ITraitCatalogDispatcher, ITraitCatalogDispatcherTrait};
    use seraphlabs::tokens::erc2114::utils::Errors;
    use seraphlabs::tokens::erc2114::utils::{AttrType, AttrTypeTrait};
    use seraphlabs::tokens::erc2114::utils::{AttrPack, AttrPackTrait};
    use seraphlabs::tokens::erc2114::utils::{AttrBase, AttrBaseTrait};
    use seraphlabs::arrays::SeraphArrayTrait;
    use seraphlabs::tokens::erc721::ERC721Component;
    use seraphlabs::tokens::erc721::extensions::ERC721EnumComponent;
    use seraphlabs::tokens::erc2114::ERC2114Component;
    use seraphlabs::tokens::src5::{
        SRC5Component, interface::{ISRC5Dispatcher, ISRC5DispatcherTrait}
    };
    use SRC5Component::SRC5InternalImpl;
    use ERC2114Component::{ERC2114PrivateImpl, IERC2114Impl};
    // corelib imports
    use starknet::{
        get_caller_address, get_contract_address, ContractAddress, ContractAddressIntoFelt252
    };
    use starknet::storage_access::StorePacking;

    #[storage]
    struct Storage {
        slot_attr_value: LegacyMap<(u256, u64), felt252>,
        index_to_slot_attr_pack: LegacyMap<(u256, u64), AttrPack>
    }

    #[event]
    #[derive(Drop, PartialEq, starknet::Event)]
    enum Event {
        SlotAttributeUpdate: SlotAttributeUpdate
    }

    #[derive(Drop, PartialEq, starknet::Event)]
    struct SlotAttributeUpdate {
        #[key]
        slot_id: u256,
        #[key]
        attr_id: u64,
        #[key]
        attr_type: AttrType,
        #[key]
        old_value: felt252,
        #[key]
        new_value: felt252
    }

    // -------------------------------------------------------------------------- //
    //                               For Embeddable                               //
    // -------------------------------------------------------------------------- //

    #[embeddable_as(ERC2114SlotAttrImpl)]
    impl ERC2114SlotAttr<
        TContractState,
        +HasComponent<TContractState>,
        +ERC2114Component::HasComponent<TContractState>,
        +ERC721Component::HasComponent<TContractState>,
        +ERC721EnumComponent::HasComponent<TContractState>,
        +Drop<TContractState>
    > of interface::IERC2114SlotAttribute<ComponentState<TContractState>> {
        fn slot_attribute_value(
            self: @ComponentState<TContractState>, slot_id: u256, attr_id: u64
        ) -> felt252 {
            IERC2114SlotAttrImpl::slot_attribute_value(self, slot_id, attr_id)
        }

        fn slot_attributes_of(self: @ComponentState<TContractState>, slot_id: u256) -> Span<u64> {
            IERC2114SlotAttrImpl::slot_attributes_of(self, slot_id)
        }

        fn set_slot_attribute(
            ref self: ComponentState<TContractState>, slot_id: u256, attr_id: u64, value: felt252
        ) {
            IERC2114SlotAttrImpl::set_slot_attribute(ref self, slot_id, attr_id, value);
        }

        fn batch_set_slot_attribute(
            ref self: ComponentState<TContractState>,
            slot_id: u256,
            attr_ids: Span<u64>,
            values: Span<felt252>
        ) {
            IERC2114SlotAttrImpl::batch_set_slot_attribute(ref self, slot_id, attr_ids, values);
        }
    }

    // -------------------------------------------------------------------------- //
    //                                 Initializer                                //
    // -------------------------------------------------------------------------- //

    #[generate_trait]
    impl ERC2114SlotAttrInitializerImpl<
        TContractState,
        +HasComponent<TContractState>,
        +SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>
    > of ERC2114SlotAttrInitializerTrait<TContractState> {
        fn initializer(ref self: ComponentState<TContractState>) {
            let mut src5 = self.get_src5_mut();
            src5.register_interface(constants::IERC2114_SLOT_ATTRIBUTE_ID);
        }
    }

    // -------------------------------------------------------------------------- //
    //                             External Functions                             //
    // -------------------------------------------------------------------------- //

    #[generate_trait]
    impl IERC2114SlotAttrImpl<
        TContractState,
        +HasComponent<TContractState>,
        +ERC2114Component::HasComponent<TContractState>,
        +ERC721Component::HasComponent<TContractState>,
        +ERC721EnumComponent::HasComponent<TContractState>,
        +Drop<TContractState>
    > of IERC2114SlotAttrImplTrait<TContractState> {
        #[inline(always)]
        fn slot_attribute_value(
            self: @ComponentState<TContractState>, slot_id: u256, attr_id: u64
        ) -> felt252 {
            let value = self.slot_attr_value.read((slot_id, attr_id));
            let erc2114 = self.get_erc2114();

            let attr_type: AttrType = erc2114.attribute_type(attr_id);
            match attr_type {
                AttrType::Empty => { 0 },
                AttrType::String(list_id) => {
                    if list_id.is_zero() || value.is_zero() {
                        value
                    } else {
                        erc2114._get_trait_catalog().trait_list_value_by_index(list_id, value)
                    }
                },
                AttrType::Number(_) => { value }
            }
        }

        #[inline(always)]
        fn slot_attributes_of(self: @ComponentState<TContractState>, slot_id: u256) -> Span<u64> {
            self._slot_attributes_of(slot_id).span()
        }

        #[inline(always)]
        fn set_slot_attribute(
            ref self: ComponentState<TContractState>, slot_id: u256, attr_id: u64, value: felt252
        ) {
            // checks validity of attr_id and value
            // checks validity of slot_id
            // emits event
            self._set_attributes_to_slot(slot_id, array![attr_id].span(), array![value].span());
        }

        #[inline(always)]
        fn batch_set_slot_attribute(
            ref self: ComponentState<TContractState>,
            slot_id: u256,
            attr_ids: Span<u64>,
            values: Span<felt252>
        ) {
            // checks validity of attr_id and value
            // checks validity of slot_id
            // emits event
            self._set_attributes_to_slot(slot_id, attr_ids, values);
        }
    }
    // -------------------------------------------------------------------------- //
    //                             Internal Functions                             //
    // -------------------------------------------------------------------------- //
    #[generate_trait]
    impl ERC2114SlotAttrInternalImpl<
        TContractState,
        +HasComponent<TContractState>,
        +ERC2114Component::HasComponent<TContractState>,
        +ERC721Component::HasComponent<TContractState>,
        +ERC721EnumComponent::HasComponent<TContractState>,
        +Drop<TContractState>
    > of ERC2114SlotAttrInternalTrait<TContractState> {
        fn _slot_attributes_of(self: @ComponentState<TContractState>, slot_id: u256) -> Array<u64> {
            let mut attr_ids = ArrayTrait::new();
            let mut index = 0;
            loop {
                let attr_pack = self.index_to_slot_attr_pack.read((slot_id, index));
                if !attr_pack.is_valid() {
                    break;
                }
                // unpack into array
                attr_pack.unpack_into(ref attr_ids);
                index += 1;
            };
            attr_ids
        }

        fn _set_attributes_to_slot(
            ref self: ComponentState<TContractState>,
            slot_id: u256,
            attr_ids: Span<u64>,
            values: Span<felt252>
        ) {
            // assert slot_id is valid
            assert(slot_id.is_non_zero(), Errors::INVALID_SLOT_ID);
            // if attr_ids is empty return
            if attr_ids.len().is_zero() {
                return;
            }
            // @dev sets corresponding values to slot attr_ids 
            // this function emits SlotAttributeUpdate events
            // this function checks validity of attr_ids and values 
            // returns new set of attr_ids that should be added to slot to avoid repeats
            let new_attr_ids = self._set_slot_attr_values(slot_id, attr_ids, values);
            // add atr_ids to slot
            self._attach_attr_ids_to_slot(slot_id, new_attr_ids);
        }

        // @dev remove attr_ids with corresponding values from token
        // will panic if attr_id is not in slot_id
        fn _remove_attributes_from_slot(
            ref self: ComponentState<TContractState>, slot_id: u256, attr_ids: Span<u64>
        ) {
            // assert slot_id is valid
            assert(slot_id.is_non_zero(), Errors::INVALID_SLOT_ID);
            // if attr_ids is empty return
            if attr_ids.len().is_zero() {
                return;
            }
            // @dev unsets corresponding values from slot attr_ids 
            // this function emits SlotAttributeUpdate events
            // this function checks validity of attr_ids and values
            self._unset_slot_attr_values(slot_id, attr_ids);
            // remove atr_ids from token
            self._detach_attr_ids_from_slot(slot_id, attr_ids);
        }
    }
    // -------------------------------------------------------------------------- //
    //                              Private Functions                             //
    // -------------------------------------------------------------------------- //
    #[generate_trait]
    impl ERC2114SlotAttrPrivateImpl<
        TContractState,
        +HasComponent<TContractState>,
        +ERC2114Component::HasComponent<TContractState>,
        +ERC721Component::HasComponent<TContractState>,
        +ERC721EnumComponent::HasComponent<TContractState>,
        +Drop<TContractState>
    > of ERC2114SlotAttrPrivateTrait<TContractState> {
        // @dev finds an available index that has space to store x ammount of attr_ids 
        // index is based on len of pack to determine if new index is needed or not
        fn _find_spot_for_slot_attr_pack(
            self: @ComponentState<TContractState>, slot_id: u256, ammount: u8
        ) -> u64 {
            // assert ammount needed to store is valid
            assert(ammount > 0 && ammount <= 3, Errors::INVALID_ATTR_PACK);
            let mut index: u64 = 0;
            loop {
                let pack: AttrPack = self.index_to_slot_attr_pack.read((slot_id, index));
                if pack.len + ammount <= 3 {
                    break;
                }
                index += 1;
            };
            index
        }

        // @dev adds batch of attr_ids to slot attr_packs
        // DOES NOT check validity of attr_ids or if attr_ids have already been added
        fn _attach_attr_ids_to_slot(
            ref self: ComponentState<TContractState>, slot_id: u256, attr_ids: Span<u64>
        ) {
            // if attr_ids is empty return
            if attr_ids.len().is_zero() {
                return;
            }
            // get quotiont and remainder of attr_ids.len() / 3 
            // to see how many attr_packs can be generated
            let (q, r) = DivRem::div_rem(attr_ids.len(), 3_u32.try_into().expect('Division by 0'));
            // get the index of slots attr_pack that can store attr_pack of size 3
            // this is used to avoid constant looping to find index
            let mut l_index_attr_pack = self._find_spot_for_slot_attr_pack(slot_id, 3);
            // instantiate index to use for calculating starting pos for slicing Span
            let mut index = 0;
            loop {
                match index >= q {
                    bool::False => {
                        // slice attr_ids into spans of 3 to create attr_packs
                        // start of slice is based on index * 3 
                        let slice = attr_ids.slice(index * 3, 3);
                        // write attr_pack to storage
                        self
                            .index_to_slot_attr_pack
                            .write((slot_id, l_index_attr_pack), AttrPackTrait::new(slice));
                        // increment index and l_index_attr_pack
                        l_index_attr_pack += 1;
                        index += 1;
                    },
                    bool::True => { break; },
                };
            };
            // if remainder is non zero add left over attr_ids to attr_pack
            if r.is_non_zero() {
                let slice = attr_ids.slice(index * 3, r);
                let index_attr_pack = self
                    ._find_spot_for_slot_attr_pack(slot_id, r.try_into().unwrap());
                let mut attr_pack = self.index_to_slot_attr_pack.read((slot_id, index_attr_pack));
                // add attr_ids to attr_pack
                attr_pack.add_batch_to_pack(slice);
                self.index_to_slot_attr_pack.write((slot_id, index_attr_pack), attr_pack);
            }
        }

        // @dev finds the index that stores attr_id in slot attr_packs
        //  DOES NOT check validity of attr_id or slot_id 
        // if fails to find index will Panic
        fn _find_index_of_attr_in_slot(
            self: @ComponentState<TContractState>, slot_id: u256, attr_id: u64
        ) -> u64 {
            let mut index = 0;
            loop {
                let attr_pack = self.index_to_slot_attr_pack.read((slot_id, index));
                // if attr pack is not valid means index is out of bounds
                assert(attr_pack.is_valid(), 'ERC2114: failed to find attr_id');
                if attr_pack.has_attr(attr_id) {
                    break;
                }
                index += 1;
            };
            index
        }

        // @dev removes a single attr id from slot attr_packs
        // DOES NOT check validity of attr_id
        // @param 'l_index' is the last index of slot attr_pack that is empty
        //  used to avoid recomputing l_index for batch removals 
        fn _detach_attr_id_from_slot(
            ref self: ComponentState<TContractState>, ref l_index: u64, slot_id: u256, attr_id: u64
        ) {
            // assert attr_id value has been set to zero
            assert(
                self.slot_attr_value.read((slot_id, attr_id)).is_zero(),
                'ERC2114: attr_id cant remove'
            );
            // get index that stores attr_id
            let index = self._find_index_of_attr_in_slot(slot_id, attr_id);
            let mut cur_attr_pack: AttrPack = self.index_to_slot_attr_pack.read((slot_id, index));
            // if cur attr pack is > 1 means attr_pack spot does not need to be replaced
            if cur_attr_pack.len > 1 {
                // remove attr_id from attr_pack
                cur_attr_pack.remove_from_pack(attr_id);
                self.index_to_slot_attr_pack.write((slot_id, index), cur_attr_pack);
                return;
            } else {
                // minus last index to get new supposed last index of empty spot
                l_index -= 1;
                // if index is not last index
                // replace cur_attr_pack index with last_attr_pack
                if index != l_index {
                    let last_attr_pack = self.index_to_slot_attr_pack.read((slot_id, l_index));
                    self.index_to_slot_attr_pack.write((slot_id, index), last_attr_pack);
                }
                // set last index to zero
                self
                    .index_to_slot_attr_pack
                    .write((slot_id, l_index), AttrPack { pack: 0, len: 0 });
            }
        }

        // @dev removes batch of attr_ids to slot attr_packs
        // DOES NOT check validity of attr_ids 
        // ASSUMES slot has attr_ids
        fn _detach_attr_ids_from_slot(
            ref self: ComponentState<TContractState>, slot_id: u256, mut attr_ids: Span<u64>
        ) {
            // get last index of slot attr_packs
            let mut l_index = self._find_spot_for_slot_attr_pack(slot_id, 3);
            loop {
                match attr_ids.pop_front() {
                    Option::Some(attr_id) => {
                        self._detach_attr_id_from_slot(ref l_index, slot_id, *attr_id);
                    },
                    Option::None(_) => { break; }
                };
            };
        }


        // @dev set batch of attr_ids and corresponding values to slot
        // checks validity of value
        // if value is zero MUST FAIL
        // if value exist replace value
        // @return `new_attr_ids` a new set of attr_ids that should be added to slot  
        //  `new_attr_ids` attr ids that should be added and does not exist with slot yet 
        fn _set_slot_attr_values(
            ref self: ComponentState<TContractState>,
            slot_id: u256,
            mut attr_ids: Span<u64>,
            mut values: Span<felt252>
        ) -> Span<u64> {
            // assert that values and attr_ids len are the same length and length is not zero
            assert(attr_ids.len() == values.len(), Errors::INVALID_ID_OR_VALUE);
            let mut new_attr_ids = ArrayTrait::new();

            let mut erc2114 = self.get_erc2114_mut();
            // loop through attr_ids and values and add them to slot
            loop {
                match attr_ids.pop_front() {
                    Option::Some(attr_id) => {
                        let cur_value = self.slot_attr_value.read((slot_id, *attr_id));
                        let value = *values.pop_front().unwrap();
                        //assert value is not zero
                        assert(value.is_non_zero(), Errors::INVALID_ATTR_VALUE);

                        let attr_type = erc2114.attribute_type(*attr_id);

                        // if cur_value is zero means attr_id is new to slot
                        // so append it to new_attr_ids 
                        if cur_value.is_zero() {
                            new_attr_ids.append(*attr_id);
                        }
                        // update values, emit events
                        // this function already checks validity of attr_id and its value
                        self._update_slot_attr_value(slot_id, *attr_id, value);
                    },
                    Option::None(_) => { break; }
                };
            };
            new_attr_ids.span()
        }

        // @dev unsets batch of attr_ids and corresponding values from slot
        //  attr_id MUST EXIST in slot
        fn _unset_slot_attr_values(
            ref self: ComponentState<TContractState>, slot_id: u256, mut attr_ids: Span<u64>,
        ) {
            // loop through attr_ids and values and subtract them to slot
            loop {
                match attr_ids.pop_front() {
                    Option::Some(attr_id) => {
                        let cur_value = self.slot_attr_value.read((slot_id, *attr_id));
                        // assert cur_value is non zero
                        assert(cur_value.is_non_zero(), 'ERC2114: attr_id not in slot');
                        // update values, emit events
                        // this function already checks validity of attr_id and its value
                        self._update_slot_attr_value(slot_id, *attr_id, 0);
                    },
                    Option::None(_) => { break; }
                };
            };
        }

        // @dev updates slot attribute values and emit events 
        // DOES NOT check if slot attr_id value have already been set
        // DOES NOT remove or add attr_id to pack
        // checks valilidty of attr_id and attr_id value 
        fn _update_slot_attr_value(
            ref self: ComponentState<TContractState>, slot_id: u256, attr_id: u64, value: felt252
        ) {
            let mut erc2114 = self.get_erc2114_mut();
            let attr_type: AttrType = erc2114.attribute_type(attr_id);
            // check if attr_id is exists
            // TODO: when strings come out change error message 
            assert(!attr_type.is_empty(), Errors::INVALID_ATTR_ID);

            // if value is the same as current value return
            let cur_attr_value = self.slot_attr_value.read((slot_id, attr_id));
            if cur_attr_value == value {
                return;
            }

            // if value is not zero and attr_id has list_id attached 
            // check if value which == to index of trait list is valid
            let list_id = attr_type.get_list_id();
            let trait_cat = erc2114._get_trait_catalog();
            if value.is_non_zero() && list_id.is_non_zero() {
                // assert value of index in trait list is not zero
                // as it means index in trait list has not been set
                assert(
                    trait_cat.trait_list_value_by_index(list_id, value).is_non_zero(),
                    Errors::INVALID_ATTR_VALUE
                );
            }

            // update slot attr value
            self.slot_attr_value.write((slot_id, attr_id), value);
            // emit event
            self
                .emit(
                    SlotAttributeUpdate {
                        slot_id: slot_id,
                        attr_id: attr_id,
                        attr_type: attr_type,
                        old_value: cur_attr_value,
                        new_value: value
                    }
                );
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
    impl GetERC2114<
        TContractState,
        +HasComponent<TContractState>,
        +ERC2114Component::HasComponent<TContractState>,
        +Drop<TContractState>
    > of GetERC2114Trait<TContractState> {
        #[inline(always)]
        fn get_erc2114(
            self: @ComponentState<TContractState>
        ) -> @ERC2114Component::ComponentState<TContractState> {
            let contract = self.get_contract();
            ERC2114Component::HasComponent::<TContractState>::get_component(contract)
        }

        #[inline(always)]
        fn get_erc2114_mut(
            ref self: ComponentState<TContractState>
        ) -> ERC2114Component::ComponentState<TContractState> {
            let mut contract = self.get_contract_mut();
            ERC2114Component::HasComponent::<TContractState>::get_component_mut(ref contract)
        }
    }
}
