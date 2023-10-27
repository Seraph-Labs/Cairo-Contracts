// SPDX-License-Identifier: AGPL-3.0
// SeraphLabs Contracts for Cairo >=v2.3.0-rc0 (tokens/erc2114/extensions/inventory.cairo)

#[starknet::component]
mod ERC2114InventoryComponent {
    use seraphlabs::tokens::erc2114::erc2114::ERC2114Component::ERC2114PrivateTrait;
    use seraphlabs::tokens::constants;
    use seraphlabs::tokens::erc2114::{interface, utils::Errors};
    use interface::{ITraitCatalogDispatcher, ITraitCatalogDispatcherTrait};
    use seraphlabs::arrays::SeraphSpanTrait;
    use seraphlabs::tokens::erc2114::utils::{AttrType, AttrTypeTrait};
    use seraphlabs::tokens::erc2114::utils::{AttrPack, AttrPackTrait};
    use seraphlabs::tokens::erc721::ERC721Component;
    use seraphlabs::tokens::erc721::extensions::ERC721EnumComponent;
    use seraphlabs::tokens::erc3525::ERC3525Component;
    use seraphlabs::tokens::erc2114::ERC2114Component;
    use seraphlabs::tokens::src5::SRC5Component;
    use SRC5Component::SRC5InternalImpl;
    use ERC721Component::{ERC721InternalImpl, IERC721Impl};
    use ERC3525Component::IERC3525Impl;
    use ERC2114Component::{ERC2114InternalImpl, IERC2114Impl, ERC2114PrivateImpl};
    use starknet::{ContractAddress, get_caller_address};
    use starknet::storage_access::StorePacking;

    #[storage]
    struct Storage {
        ERC2114_token_inv_supply: LegacyMap<(u256, u256), u64>,
        ERC2114_token_inv_equipped: LegacyMap<u256, bool>,
        ERC2114_inv_slot_criteria_capacity: LegacyMap<(u256, u256), u64>,
        ERC2114_index_to_inv_attr_pack: LegacyMap<(u256, u64), AttrPack>
    }

    #[event]
    #[derive(Drop, PartialEq, starknet::Event)]
    enum Event {
        InventorySlotCriteria: InventorySlotCriteria,
        InventoryAttributes: InventoryAttributes,
        InventoryUpdated: InventoryUpdated,
    }

    #[derive(Drop, PartialEq, starknet::Event)]
    struct InventorySlotCriteria {
        #[key]
        slot_id: u256,
        #[key]
        criteria: u256,
        old_capacity: u64,
        new_capacity: u64
    }

    #[derive(Drop, PartialEq, starknet::Event)]
    struct InventoryAttributes {
        #[key]
        slot_id: u256,
        attr_ids: Span<u64>
    }

    #[derive(Drop, PartialEq, starknet::Event)]
    struct InventoryUpdated {
        #[key]
        token_id: u256,
        #[key]
        criteria: u256,
        #[key]
        child_id: u256,
        #[key]
        old_bal: u64,
        #[key]
        new_bal: u64
    }

    // -------------------------------------------------------------------------- //
    //                               For Embeddable                               //
    // -------------------------------------------------------------------------- //

    #[embeddable_as(ERC2114InvImpl)]
    impl ERC2114Inv<
        TContractState,
        +HasComponent<TContractState>,
        +ERC2114Component::HasComponent<TContractState>,
        +ERC3525Component::HasComponent<TContractState>,
        +ERC721Component::HasComponent<TContractState>,
        +ERC721EnumComponent::HasComponent<TContractState>,
        +Drop<TContractState>
    > of interface::IERC2114Inventory<ComponentState<TContractState>> {
        fn equipped_attribute_value(
            self: @ComponentState<TContractState>, token_id: u256, attr_id: u64
        ) -> felt252 {
            IERC2114InvImpl::equipped_attribute_value(self, token_id, attr_id)
        }

        fn is_inside_inventory(
            self: @ComponentState<TContractState>, token_id: u256, child_id: u256
        ) -> bool {
            IERC2114InvImpl::is_inside_inventory(self, token_id, child_id)
        }

        fn token_supply_in_inventory(
            self: @ComponentState<TContractState>, token_id: u256, criteria: u256
        ) -> u64 {
            IERC2114InvImpl::token_supply_in_inventory(self, token_id, criteria)
        }

        fn inventory_of(self: @ComponentState<TContractState>, token_id: u256) -> Span<u256> {
            IERC2114InvImpl::inventory_of(self, token_id)
        }

        fn inventory_attributes_of(
            self: @ComponentState<TContractState>, slot_id: u256
        ) -> Span<u64> {
            IERC2114InvImpl::inventory_attributes_of(self, slot_id)
        }

        fn slot_criteria_capacity(
            self: @ComponentState<TContractState>, slot_id: u256, criteria: u256
        ) -> u64 {
            IERC2114InvImpl::slot_criteria_capacity(self, slot_id, criteria)
        }

        fn edit_inventory(
            ref self: ComponentState<TContractState>, token_id: u256, child_id: u256, equipped: bool
        ) {
            IERC2114InvImpl::edit_inventory(ref self, token_id, child_id, equipped);
        }

        fn set_slot_criteria(
            ref self: ComponentState<TContractState>, slot_id: u256, criteria: u256, capacity: u64
        ) {
            IERC2114InvImpl::set_slot_criteria(ref self, slot_id, criteria, capacity);
        }

        fn set_inventory_attributes(
            ref self: ComponentState<TContractState>, slot_id: u256, attr_ids: Span<u64>
        ) {
            IERC2114InvImpl::set_inventory_attributes(ref self, slot_id, attr_ids);
        }
    }
    // -------------------------------------------------------------------------- //
    //                                 Initalizer                                 //
    // -------------------------------------------------------------------------- //

    #[generate_trait]
    impl ERC2114InvInitializerImpl<
        TContractState,
        +HasComponent<TContractState>,
        +SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>
    > of ERC2114InvInitializerTrait<TContractState> {
        fn initializer(ref self: ComponentState<TContractState>) {
            let mut src5 = self.get_src5_mut();
            src5.register_interface(constants::IERC2114_INVENTORY_ID);
        }
    }

    // -------------------------------------------------------------------------- //
    //                             External Functions                             //
    // -------------------------------------------------------------------------- //

    #[generate_trait]
    impl IERC2114InvImpl<
        TContractState,
        +HasComponent<TContractState>,
        +ERC2114Component::HasComponent<TContractState>,
        +ERC3525Component::HasComponent<TContractState>,
        +ERC721Component::HasComponent<TContractState>,
        +ERC721EnumComponent::HasComponent<TContractState>,
        +Drop<TContractState>
    > of IERC2114InvImplTrait<TContractState> {
        #[inline(always)]
        fn equipped_attribute_value(
            self: @ComponentState<TContractState>, token_id: u256, attr_id: u64
        ) -> felt252 {
            let erc2114 = self.get_erc2114();
            let attr_type: AttrType = erc2114.attribute_type(attr_id);
            // if attr_id does not exist return 0
            match attr_type {
                AttrType::Empty => { 0 },
                AttrType::String(list_id) => {
                    // might be a index or actual value depending on if it has a list_id
                    let value = self._find_equipped_attr_string_value(token_id, attr_id);
                    if list_id.is_zero() || value.is_zero() {
                        value
                    } else {
                        erc2114._get_trait_catalog().trait_list_value_by_index(list_id, value)
                    }
                },
                AttrType::Number(_) => {
                    let mut sum_val: felt252 = 0;
                    self._sum_equipped_attr_number_value(token_id, attr_id, ref sum_val);
                    sum_val
                }
            }
        }

        #[inline(always)]
        fn is_inside_inventory(
            self: @ComponentState<TContractState>, token_id: u256, child_id: u256
        ) -> bool {
            // assert token_id exists
            assert(self.get_erc721()._exist(token_id), Errors::INVALID_TOKEN_ID);
            self._is_inside_inventory(token_id, child_id)
        }

        #[inline(always)]
        fn token_supply_in_inventory(
            self: @ComponentState<TContractState>, token_id: u256, criteria: u256
        ) -> u64 {
            self.ERC2114_token_inv_supply.read((token_id, criteria))
        }

        #[inline(always)]
        fn inventory_of(self: @ComponentState<TContractState>, token_id: u256) -> Span<u256> {
            // assert token exists
            assert(self.get_erc721()._exist(token_id), Errors::INVALID_TOKEN_ID);
            // get inventory
            self._inventory_of(token_id).span()
        }

        #[inline(always)]
        fn inventory_attributes_of(
            self: @ComponentState<TContractState>, slot_id: u256
        ) -> Span<u64> {
            self._inventory_attributes_of(slot_id).span()
        }

        #[inline(always)]
        fn slot_criteria_capacity(
            self: @ComponentState<TContractState>, slot_id: u256, criteria: u256
        ) -> u64 {
            self.ERC2114_inv_slot_criteria_capacity.read((slot_id, criteria))
        }

        #[inline(always)]
        fn edit_inventory(
            ref self: ComponentState<TContractState>, token_id: u256, child_id: u256, equipped: bool
        ) {
            // assert child_id exists 
            let mut erc721 = self.get_erc721_mut();
            assert(erc721._exist(token_id), Errors::INVALID_TOKEN_ID);
            // get final_parent_id to check for approval
            // assumes that token_id is parent 
            // will check in the last update inventory function  
            let mut erc2114 = self.get_erc2114_mut();
            let final_parent_id = erc2114._get_final_parent(token_id);
            // assert approval
            assert(
                erc721._is_approved_or_owner(get_caller_address(), final_parent_id),
                Errors::UNAPPROVED_CALLER
            );
            // get equipped status of child
            let is_equipped: bool = self.ERC2114_token_inv_equipped.read(child_id);
            assert(is_equipped != equipped, 'ERC2114: inventory up to date');
            // update inventory
            // this functions checks if token_id is child_id direct parent
            // this function checks if inventory has space if its a equip
            // this function emits event
            self._update_token_inventory(token_id, child_id);
        }

        #[inline(always)]
        fn set_slot_criteria(
            ref self: ComponentState<TContractState>, slot_id: u256, criteria: u256, capacity: u64
        ) {
            // assert that capacity is bigger than current capacity
            // inventory should only expand and not decrease
            let cur_capacity = self.ERC2114_inv_slot_criteria_capacity.read((slot_id, criteria));
            assert(cur_capacity < capacity, Errors::INVALID_SLOT_CAPACITY);
            // update slot criteria
            self._edit_slot_criteria(slot_id, criteria, capacity);
        }

        #[inline(always)]
        fn set_inventory_attributes(
            ref self: ComponentState<TContractState>, slot_id: u256, attr_ids: Span<u64>
        ) {
            // assert that attr_ids is not the same as current attr_ids
            let cur_attr_ids = self._inventory_attributes_of(slot_id).span();
            assert(cur_attr_ids != attr_ids, 'ERC2114: attr_ids already set');
            // assert that attr_ids are valid and have no duplicates
            self._assert_valid_inventory_attr_ids(attr_ids);
            // attach attr_ids to inventory
            // this function EMITS InventoryAttributes event
            // returns last modified attr_pack index + 1 to clear attr_packs after
            let start_index = self._attach_attr_ids_to_inventory(slot_id, attr_ids);
            // clear attr_packs after start_index if any
            self._clear_inventory_attributes(slot_id, start_index);
        }
    }

    // -------------------------------------------------------------------------- //
    //                             Internal Functions                             //
    // -------------------------------------------------------------------------- //

    #[generate_trait]
    impl ERC2114InvInternalImpl<
        TContractState,
        +HasComponent<TContractState>,
        +ERC2114Component::HasComponent<TContractState>,
        +ERC3525Component::HasComponent<TContractState>,
        +ERC721Component::HasComponent<TContractState>,
        +ERC721EnumComponent::HasComponent<TContractState>,
        +Drop<TContractState>
    > of ERC2114InvInternalTrait<TContractState> {
        #[inline(always)]
        fn scalar_transfer_from(
            ref self: ComponentState<TContractState>,
            from: ContractAddress,
            token_id: u256,
            to_token_id: u256
        ) {
            // scalar transfer token before checking if can equip
            let mut erc2114 = self.get_erc2114_mut();
            erc2114.scalar_transfer_from(from, token_id, to_token_id);
            // try and equip child
            self._try_inventory_equip(to_token_id, token_id);
        }

        #[inline(always)]
        fn scalar_remove_from(
            ref self: ComponentState<TContractState>, from_token_id: u256, token_id: u256
        ) {
            // Must check for unequip first before scalar remove
            // as cant unequip if token not parent
            self._try_inventory_unequip(from_token_id, token_id);
            // scalar remove token
            let mut erc2114 = self.get_erc2114_mut();
            erc2114.scalar_remove_from(from_token_id, token_id);
        }

        // @dev does not check if token_id is valid
        #[inline(always)]
        fn _is_inside_inventory(
            self: @ComponentState<TContractState>, token_id: u256, child_id: u256
        ) -> bool {
            // check if child is in token_id backpack
            // if no return false if true check if its equipped
            let erc2114 = self.get_erc2114();
            match erc2114.token_of(child_id) == token_id {
                bool::False => false,
                bool::True => self.ERC2114_token_inv_equipped.read(child_id),
            }
        }

        // @dev gets the tokens inventory 
        //  DOES NOT check validity of token_id
        fn _inventory_of(self: @ComponentState<TContractState>, token_id: u256) -> Array<u256> {
            // initalize empty array
            let mut inventory = array![];
            let erc2114 = self.get_erc2114();
            let mut index = 0;
            // loop through and if its in inventory add to array
            loop {
                // read directly from storage to avoid index out of bounds to save gas
                let child_id: u256 = erc2114.ERC2114_index_to_token_child.read((token_id, index));
                // if child id is zero means we reach end of list thus break
                match child_id.is_zero() {
                    bool::False => {
                        // if its in inventory add to array
                        if self.ERC2114_token_inv_equipped.read(child_id) {
                            inventory.append(child_id);
                        }
                        index += 1;
                    },
                    bool::True => { break; }
                };
            };
            inventory
        }

        fn _inventory_attributes_of(
            self: @ComponentState<TContractState>, slot_id: u256
        ) -> Array<u64> {
            let mut attr_ids = ArrayTrait::new();
            let mut index = 0;
            loop {
                let pack: AttrPack = self.ERC2114_index_to_inv_attr_pack.read((slot_id, index));
                if pack.len.is_zero() {
                    break;
                }
                // unpack into array
                pack.unpack_into(ref attr_ids);
                index += 1;
            };
            attr_ids
        }


        // @dev try and equip child to token inventory
        //  mainly use for sclartransfer
        //  DOES NOT check validity of token_id or child_id
        //  WILL FAIL if token_id is not child_id direct parent
        #[inline(always)]
        fn _try_inventory_equip(
            ref self: ComponentState<TContractState>, token_id: u256, child_id: u256
        ) {
            let mut erc3525 = self.get_erc3525_mut();
            // get token_id slot
            let slot_id = erc3525.slot_of(token_id);
            // get criteria of child 
            let criteria = erc3525.slot_of(child_id);
            // if inventory is full or child is already equipped return
            if self._is_inventory_full(slot_id, token_id, criteria)
                || self.ERC2114_token_inv_equipped.read(child_id) {
                return ();
            } else {
                // update inventory
                // this function checks if child is in token_id backpack
                self._update_token_inventory(token_id, child_id);
            }
        }

        // @dev try and unequip child from token inventory
        //  mainly use for scalarremove
        //  DOES NOT check validity of token_id or child_id
        //  WILL FAIL if token_id is not child_id direct parent
        #[inline(always)]
        fn _try_inventory_unequip(
            ref self: ComponentState<TContractState>, token_id: u256, child_id: u256
        ) {
            // if child id is not equipped return 
            if !self.ERC2114_token_inv_equipped.read(child_id) {
                return ();
            } else {
                // update inventory
                // this function checks if child is in token_id backpack
                self._update_token_inventory(token_id, child_id);
            }
        }
    }

    // -------------------------------------------------------------------------- //
    //                              Private Fuctions                              //
    // -------------------------------------------------------------------------- //

    #[generate_trait]
    impl ERC2114InvPrivateImpl<
        TContractState,
        +HasComponent<TContractState>,
        +ERC2114Component::HasComponent<TContractState>,
        +ERC3525Component::HasComponent<TContractState>,
        +ERC721Component::HasComponent<TContractState>,
        +ERC721EnumComponent::HasComponent<TContractState>,
        +Drop<TContractState>
    > of ERC2114InvPrivateTrait<TContractState> {
        #[inline(always)]
        fn _assert_inventory_has_space(
            self: @ComponentState<TContractState>, slot_id: u256, token_id: u256, criteria: u256,
        ) {
            let capacity = self.ERC2114_inv_slot_criteria_capacity.read((slot_id, criteria));
            let supply = self.ERC2114_token_inv_supply.read((token_id, criteria));
            assert(capacity > supply, Errors::INVENTORY_NO_SPACE);
        }

        #[inline(always)]
        fn _assert_token_is_parent(
            self: @ComponentState<TContractState>, token_id: u256, child_id: u256
        ) {
            let parent_id = self.get_erc2114().token_of(child_id);
            assert(parent_id.is_non_zero() && parent_id == token_id, Errors::INVALID_PARENT);
        }

        // @dev assert that attr_ids are valid and have no duplicates
        fn _assert_valid_inventory_attr_ids(
            self: @ComponentState<TContractState>, mut attr_ids: Span<u64>
        ) {
            let erc2114 = self.get_erc2114();
            loop {
                match attr_ids.pop_front() {
                    Option::Some(attr_id) => {
                        // assert attr_id exists
                        let val_type: AttrType = erc2114.attribute_type(*attr_id);
                        assert(!val_type.is_empty(), Errors::INVALID_ATTR_ID);
                        // assert attr_id is not already in attr_ids
                        assert(!attr_ids.contains(*attr_id), 'ERC2114: duplicate attr_id');
                    },
                    Option::None => { break; },
                }
            }
        }

        #[inline(always)]
        fn _is_inventory_full(
            self: @ComponentState<TContractState>, slot_id: u256, token_id: u256, criteria: u256,
        ) -> bool {
            let capacity = self.ERC2114_inv_slot_criteria_capacity.read((slot_id, criteria));
            let supply = self.ERC2114_token_inv_supply.read((token_id, criteria));
            supply >= capacity
        }

        // @dev checks if attr_id is in inventory attrobutes
        //  DOES NOT check if attr_id is valid
        fn _is_inventory_attribute(
            self: @ComponentState<TContractState>, slot_id: u256, attr_id: u64
        ) -> bool {
            let mut index = 0;
            loop {
                let pack: AttrPack = self.ERC2114_index_to_inv_attr_pack.read((slot_id, index));
                // if no attr_id is found at the end return false
                if pack.len.is_zero() {
                    break false;
                }
                //  if attr_id is found return true
                // else increment index 
                match pack.has_attr(attr_id) {
                    bool::False => index += 1,
                    bool::True => { break true; }
                };
            }
        }

        // @dev sums attr_id value of token_id and its inventory
        //  DOES NOT check if attr_id is of type Number
        fn _sum_equipped_attr_number_value(
            self: @ComponentState<TContractState>,
            token_id: u256,
            attr_id: u64,
            ref sum_val: felt252
        ) {
            let erc2114 = self.get_erc2114();
            // read straight from storage to save gas as its assume to be number type
            // add attr_id value to sum_val
            sum_val += erc2114.ERC2114_token_attr_value.read((token_id, attr_id));
            // check if attr_id is a inventory attribute 
            // if false return as it means referenced token cant inherit this attr_id
            let slot_id = self.get_erc3525().slot_of(token_id);
            if !self._is_inventory_attribute(slot_id, attr_id) {
                return;
            }
            // loop through token inventory to sum attr_id value 
            let mut index = 0;
            loop {
                // read directly from storage to avoid index out of bounds to save gas
                let child_id: u256 = erc2114.ERC2114_index_to_token_child.read((token_id, index));
                // if child_id is 0 means we reach end of index
                if child_id.is_zero() {
                    break;
                }
                index += 1;
                // check if child is in inventory
                // if child is not in inventory continue
                // else recursively sum value of attr_id in child inventory
                let is_equipped: bool = self.ERC2114_token_inv_equipped.read(child_id);
                match is_equipped {
                    bool::False => { continue; },
                    bool::True => {
                        // recursively sum value of attr_id in token_id equipped child_id inventory
                        self._sum_equipped_attr_number_value(child_id, attr_id, ref sum_val);
                    }
                };
            };
        }

        // @dev finds attr_id string value for tokenid in its inventory
        //  if string attr_id is attached to a list, it returns the index to that list not the actual value
        //  DOES NOT check if attr_id is of type string
        // @return the index of the list_id or if none associated return the actual attr_id value
        fn _find_equipped_attr_string_value(
            self: @ComponentState<TContractState>, token_id: u256, attr_id: u64
        ) -> felt252 {
            // check if token has attr_id value
            // if it does return it as token can only have one string value
            let erc2114 = self.get_erc2114();
            // read straight from the 
            let value: felt252 = erc2114.ERC2114_token_attr_value.read((token_id, attr_id));
            if value.is_non_zero() {
                return value;
            }
            // check if attr_id is a inventory attribute
            // if not inventory attribute return 0
            let slot_id = self.get_erc3525().slot_of(token_id);
            if !self._is_inventory_attribute(slot_id, attr_id) {
                return 0;
            }
            // loop through token inventory and try to find attr_id value
            // in its equipped tokens
            let mut index = 0;
            loop {
                // read directly from storage to avoid index out of bounds to save gas
                let child_id: u256 = erc2114.ERC2114_index_to_token_child.read((token_id, index));
                // if child_id is 0 means we reach end of index
                if child_id.is_zero() {
                    break 0;
                }

                index += 1;
                // check if child is in inventory
                // if child is not in inventory continue
                // else recursively find value of attr_id in child inventory
                if !self.ERC2114_token_inv_equipped.read(child_id) {
                    continue;
                } else {
                    // recursively find value of attr_id in token_id equipped child_id inventory
                    let attr_value = self._find_equipped_attr_string_value(child_id, attr_id);
                    // check if child inventory has returned value 
                    // if it does return it if not move to next equipped child
                    if attr_value.is_non_zero() {
                        break attr_value;
                    }
                };
            }
        }

        // @dev updates token inventory based on whther child is already equipped or not
        //  DOES NOT check validity of token_id or child_id
        //  DOES MOT Check if caller has approval
        //  DOES check if child is in token_id backpack
        //  DOES Check if inventory has space
        //  EMITS InventoryUpdated Event
        #[inline(always)]
        fn _update_token_inventory(
            ref self: ComponentState<TContractState>, token_id: u256, child_id: u256
        ) {
            // assert that child id is in token id backpack
            self._assert_token_is_parent(token_id, child_id);
            // get criteria that child would be in
            let mut erc3525 = self.get_erc3525_mut();
            let criteria = erc3525.slot_of(child_id);
            // get old balance
            let old_bal = self.ERC2114_token_inv_supply.read((token_id, criteria));
            // if child is in backpack check if its equipped 
            // if it is unequip if its not equip it
            let is_equipped: bool = self.ERC2114_token_inv_equipped.read(child_id);
            let new_bal = match is_equipped {
                bool::False => {
                    // assert inventory has space
                    let slot_id = erc3525.slot_of(token_id);
                    self._assert_inventory_has_space(slot_id, token_id, criteria);
                    // equip child
                    self.ERC2114_token_inv_equipped.write(child_id, true);
                    old_bal + 1
                },
                bool::True => {
                    // unequip child
                    self.ERC2114_token_inv_equipped.write(child_id, false);
                    old_bal - 1
                },
            };
            // update inverntory supply
            self.ERC2114_token_inv_supply.write((token_id, criteria), new_bal);
            // emit event
            self.emit(InventoryUpdated { token_id, criteria, child_id, old_bal, new_bal });
        }

        // @dev updates the inventory slot criteria capacity
        //  DOES NOT check validity of slot_id, criteria, or capacity
        //  EMITS InventorySlotCriteria Event
        #[inline(always)]
        fn _edit_slot_criteria(
            ref self: ComponentState<TContractState>, slot_id: u256, criteria: u256, capacity: u64
        ) {
            // skip if old_capacity is the same as capacity
            let old_capacity = self.ERC2114_inv_slot_criteria_capacity.read((slot_id, criteria));
            if old_capacity == capacity {
                return ();
            }
            // update capacity
            self.ERC2114_inv_slot_criteria_capacity.write((slot_id, criteria), capacity);
            // emit event
            self
                .emit(
                    InventorySlotCriteria {
                        slot_id: slot_id,
                        criteria: criteria,
                        old_capacity: old_capacity,
                        new_capacity: capacity
                    }
                );
        }

        // @dev adds batch of attr_ids to inventory attr_packs
        //  DOES NOT check validity of attr_ids or if attr_ids have already been added
        //  DOES NOT reset the attr_packs of previous inventory attributes
        //  EMITS InventoryAttributes Event
        // @return index of last attr_pack added + 1 
        fn _attach_attr_ids_to_inventory(
            ref self: ComponentState<TContractState>, slot_id: u256, attr_ids: Span<u64>
        ) -> u64 {
            // instantiate index to use for calculating starting pos for slicing Span
            // and to get index of last attr_pack added
            let mut index = 0;
            // if attr_ids is not empty add attr_ids to inventory attr_packs
            if attr_ids.len().is_non_zero() {
                // get quotiont and remainder of attr_ids.len() / 3 
                // to see how many attr_packs can be generated
                let (q, r) = DivRem::div_rem(
                    attr_ids.len(), 3_u32.try_into().expect('Division by 0')
                );
                loop {
                    match index >= q {
                        bool::False => {
                            // slice attr_ids into spans of 3 to create attr_packs
                            // start of slice is based on index * 3 
                            let slice = attr_ids.slice(index * 3, 3);
                            // write attr_pack to storage
                            self
                                .ERC2114_index_to_inv_attr_pack
                                .write((slot_id, index.into()), AttrPackTrait::new(slice));
                            // increment index and l_index
                            index += 1;
                        },
                        bool::True => { break; },
                    };
                };
                // if remainder is non zero add left over attr_ids to attr_pack
                if r.is_non_zero() {
                    let slice = attr_ids.slice(index * 3, r);
                    self
                        .ERC2114_index_to_inv_attr_pack
                        .write((slot_id, index.into()), AttrPackTrait::new(slice));
                    index += 1;
                }
            }
            // emit event
            self.emit(InventoryAttributes { slot_id, attr_ids });
            // return index
            index.into()
        }

        // @dev clears inventory attributes starting from index
        fn _clear_inventory_attributes(
            ref self: ComponentState<TContractState>, slot_id: u256, start_index: u64
        ) {
            let mut index = start_index;
            // keep clearing attrpacks at index until index returns empty attrpack
            // which means we are at the end of the attrpacks list
            loop {
                let pack: AttrPack = self.ERC2114_index_to_inv_attr_pack.read((slot_id, index));
                match pack.len.is_zero() {
                    bool::False => {
                        // clear attr_pack
                        self.ERC2114_index_to_inv_attr_pack.write((slot_id, index), 0.into());
                        // increase index
                        index += 1;
                    },
                    bool::True => { break; },
                };
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
    impl GetER3525<
        TContractState,
        +HasComponent<TContractState>,
        +ERC3525Component::HasComponent<TContractState>,
        +Drop<TContractState>
    > of GetERC3525Trait<TContractState> {
        #[inline(always)]
        fn get_erc3525(
            self: @ComponentState<TContractState>
        ) -> @ERC3525Component::ComponentState<TContractState> {
            let contract = self.get_contract();
            ERC3525Component::HasComponent::<TContractState>::get_component(contract)
        }
        #[inline(always)]
        fn get_erc3525_mut(
            ref self: ComponentState<TContractState>
        ) -> ERC3525Component::ComponentState<TContractState> {
            let mut contract = self.get_contract_mut();
            ERC3525Component::HasComponent::<TContractState>::get_component_mut(ref contract)
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
