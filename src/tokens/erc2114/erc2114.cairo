// SPDX-License-Identifier: AGPL-3.0
// SeraphLabs Contracts for Cairo >=v2.3.0-rc0 (tokens/erc2114/erc2114.cairo)
#[starknet::component]
mod ERC2114Component {
    use seraphlabs::tokens::constants;
    use seraphlabs::tokens::erc2114::interface;
    use seraphlabs::arrays::SeraphArrayTrait;
    use interface::{ITraitCatalogDispatcher, ITraitCatalogDispatcherTrait};
    use seraphlabs::tokens::erc2114::utils::Errors;
    use seraphlabs::tokens::erc2114::utils::{AttrType, AttrTypeTrait};
    use seraphlabs::tokens::erc2114::utils::{AttrBase, AttrBaseTrait};
    use seraphlabs::tokens::erc2114::utils::{AttrPack, AttrPackTrait};
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
        get_caller_address, get_contract_address, ContractAddress, ContractAddressIntoFelt252
    };
    use starknet::storage_access::StorePacking;

    #[storage]
    struct Storage {
        ERC2114_trait_catalog_contract: ContractAddress,
        ERC2114_attr_base: LegacyMap<u64, AttrBase>,
        ERC2114_token_attr_value: LegacyMap<(u256, u64), felt252>,
        ERC2114_token_balance: LegacyMap<u256, u256>,
        ERC2114_token_parent: LegacyMap<u256, u256>,
        ERC2114_index_to_token_child: LegacyMap<(u256, u256), u256>,
        ERC2114_index_to_token_attr_pack: LegacyMap<(u256, u64), AttrPack>
    }

    #[event]
    #[derive(Drop, PartialEq, starknet::Event)]
    enum Event {
        TraitCatalogAttached: TraitCatalogAttached,
        ScalarTransfer: ScalarTransfer,
        ScalarRemove: ScalarRemove,
        AttributeCreated: AttributeCreated,
        TokenAttributeUpdate: TokenAttributeUpdate
    }

    #[derive(Drop, PartialEq, starknet::Event)]
    struct TraitCatalogAttached {
        #[key]
        from: ContractAddress,
        #[key]
        trait_catalog_addr: ContractAddress,
    }

    #[derive(Drop, PartialEq, starknet::Event)]
    struct ScalarTransfer {
        #[key]
        from: ContractAddress,
        #[key]
        token_id: u256,
        #[key]
        to_token_id: u256
    }

    #[derive(Drop, PartialEq, starknet::Event)]
    struct ScalarRemove {
        #[key]
        from_token_id: u256,
        #[key]
        token_id: u256,
        #[key]
        to: ContractAddress
    }

    #[derive(Drop, PartialEq, starknet::Event)]
    struct AttributeCreated {
        #[key]
        attr_id: u64,
        #[key]
        attr_type: AttrType,
        name: felt252
    }

    #[derive(Drop, PartialEq, starknet::Event)]
    struct TokenAttributeUpdate {
        #[key]
        token_id: u256,
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

    #[embeddable_as(ERC2114Impl)]
    impl ERC2114<
        TContractState,
        +HasComponent<TContractState>,
        +ERC721Component::HasComponent<TContractState>,
        +ERC721EnumComponent::HasComponent<TContractState>,
        +Drop<TContractState>
    > of interface::IERC2114<ComponentState<TContractState>> {
        fn get_trait_catalog(self: @ComponentState<TContractState>) -> ContractAddress {
            IERC2114Impl::get_trait_catalog(self)
        }

        fn token_balance_of(self: @ComponentState<TContractState>, token_id: u256) -> u256 {
            IERC2114Impl::token_balance_of(self, token_id)
        }

        fn token_of(self: @ComponentState<TContractState>, token_id: u256) -> u256 {
            IERC2114Impl::token_of(self, token_id)
        }

        fn token_of_token_by_index(
            self: @ComponentState<TContractState>, token_id: u256, index: u256
        ) -> u256 {
            IERC2114Impl::token_of_token_by_index(self, token_id, index)
        }

        fn attribute_name(self: @ComponentState<TContractState>, attr_id: u64) -> felt252 {
            IERC2114Impl::attribute_name(self, attr_id)
        }

        fn attribute_type(self: @ComponentState<TContractState>, attr_id: u64) -> AttrType {
            IERC2114Impl::attribute_type(self, attr_id)
        }

        fn attribute_value(
            self: @ComponentState<TContractState>, token_id: u256, attr_id: u64
        ) -> felt252 {
            IERC2114Impl::attribute_value(self, token_id, attr_id)
        }

        fn attributes_of(self: @ComponentState<TContractState>, token_id: u256) -> Span<u64> {
            IERC2114Impl::attributes_of(self, token_id)
        }

        fn scalar_transfer_from(
            ref self: ComponentState<TContractState>,
            from: ContractAddress,
            token_id: u256,
            to_token_id: u256
        ) {
            IERC2114Impl::scalar_transfer_from(ref self, from, token_id, to_token_id);
        }

        fn scalar_remove_from(
            ref self: ComponentState<TContractState>, from_token_id: u256, token_id: u256
        ) {
            IERC2114Impl::scalar_remove_from(ref self, from_token_id, token_id);
        }

        fn create_attribute(
            ref self: ComponentState<TContractState>,
            attr_id: u64,
            attr_type: AttrType,
            name: felt252
        ) {
            IERC2114Impl::create_attribute(ref self, attr_id, attr_type, name);
        }
    }

    // -------------------------------------------------------------------------- //
    //                                 Initalizer                                 //
    // -------------------------------------------------------------------------- //

    #[generate_trait]
    impl ERC2114InitializerImpl<
        TContractState,
        +HasComponent<TContractState>,
        +SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>
    > of ERC2114InitializerTrait<TContractState> {
        fn initializer(ref self: ComponentState<TContractState>, catalog_addr: ContractAddress) {
            self._add_trait_catalog(catalog_addr);
            let mut src5 = self.get_src5_mut();
            src5.register_interface(constants::IERC2114_ID);
        }
    }

    // -------------------------------------------------------------------------- //
    //                             External Functions                             //
    // -------------------------------------------------------------------------- //

    #[generate_trait]
    impl IERC2114Impl<
        TContractState,
        +HasComponent<TContractState>,
        +ERC721Component::HasComponent<TContractState>,
        +ERC721EnumComponent::HasComponent<TContractState>,
        +Drop<TContractState>
    > of IERC2114ImplTrait<TContractState> {
        #[inline(always)]
        fn get_trait_catalog(self: @ComponentState<TContractState>) -> ContractAddress {
            self.ERC2114_trait_catalog_contract.read()
        }

        #[inline(always)]
        fn token_balance_of(self: @ComponentState<TContractState>, token_id: u256) -> u256 {
            self.ERC2114_token_balance.read(token_id)
        }

        #[inline(always)]
        fn token_of(self: @ComponentState<TContractState>, token_id: u256) -> u256 {
            self.ERC2114_token_parent.read(token_id)
        }

        #[inline(always)]
        fn token_of_token_by_index(
            self: @ComponentState<TContractState>, token_id: u256, index: u256
        ) -> u256 {
            self._token_of_token_by_index(token_id, index).expect(Errors::INDEX_OUT_OF_BOUNDS)
        }

        #[inline(always)]
        fn attribute_name(self: @ComponentState<TContractState>, attr_id: u64) -> felt252 {
            let res: AttrBase = self.ERC2114_attr_base.read(attr_id);
            res.name
        }

        #[inline(always)]
        fn attribute_type(self: @ComponentState<TContractState>, attr_id: u64) -> AttrType {
            let res: AttrBase = self.ERC2114_attr_base.read(attr_id);
            res.val_type
        }

        #[inline(always)]
        fn attribute_value(
            self: @ComponentState<TContractState>, token_id: u256, attr_id: u64
        ) -> felt252 {
            let value = self.ERC2114_token_attr_value.read((token_id, attr_id));
            let attribute_base: AttrBase = self.ERC2114_attr_base.read(attr_id);
            match attribute_base.val_type {
                AttrType::Empty => { 0 },
                AttrType::String(list_id) => {
                    if list_id.is_zero() || value.is_zero() {
                        value
                    } else {
                        self._get_trait_catalog().trait_list_value_by_index(list_id, value)
                    }
                },
                AttrType::Number(_) => { value }
            }
        }

        #[inline(always)]
        fn attributes_of(self: @ComponentState<TContractState>, token_id: u256) -> Span<u64> {
            self._attributes_of(token_id).span()
        }

        #[inline(always)]
        fn scalar_transfer_from(
            ref self: ComponentState<TContractState>,
            from: ContractAddress,
            token_id: u256,
            to_token_id: u256
        ) {
            // assert to_token_id is valid
            assert(self.get_erc721_mut()._exist(to_token_id), Errors::INVALID_TOKEN_ID);
            // assert token id has no parent
            self._assert_token_no_parent(token_id);
            // transfer token to contract address as arbitrary address to hold token temporarily
            // @dev this function checks validity of token id, approval, and from address
            let mut erc721_enum = self.get_erc721_enum_mut();
            erc721_enum.transfer_from(from, get_contract_address(), token_id);
            // scalar transfer
            self._scalar_transfer(from, token_id, to_token_id);
        }

        #[inline(always)]
        fn scalar_remove_from(
            ref self: ComponentState<TContractState>, from_token_id: u256, token_id: u256
        ) {
            // assert token id is valid
            let mut erc721 = self.get_erc721_mut();
            assert(erc721._exist(token_id), Errors::INVALID_TOKEN_ID);
            // assert token id is child of from_token_id and from_token_id is non zero
            assert(
                self.ERC2114_token_parent.read(token_id) == from_token_id
                    && from_token_id.is_non_zero(),
                Errors::INVALID_PARENT
            );
            // assert owner/approval of final parent is valid
            let final_parent_id = self._get_final_parent(from_token_id);
            assert(
                erc721._is_approved_or_owner(get_caller_address(), final_parent_id),
                Errors::UNAPPROVED_CALLER
            );
            // get owner of final parent id to transfer token back into
            let owner = erc721.owner_of(final_parent_id);
            // transfer token back to owner
            // @dev uses internal functions as token id approvals is still set to contract address
            //  interanl transfer is to avoid approval settings for token id 
            //  as approval for this function is set for final parent id 
            //  Enum transfer has to go first as it checks balance which ERC721 will modify
            let cur_contract = get_contract_address();
            let mut erc721_enum = self.get_erc721_enum_mut();
            erc721_enum._transfer(cur_contract, owner, token_id);
            erc721._transfer(cur_contract, owner, token_id);
            // scalar remove
            self._scalar_remove(from_token_id, token_id, owner);
        }

        #[inline(always)]
        fn create_attribute(
            ref self: ComponentState<TContractState>,
            attr_id: u64,
            attr_type: AttrType,
            name: felt252
        ) {
            // assert attr_id is not zero
            assert(attr_id.is_non_zero(), Errors::INVALID_ATTR_ID);
            // assert that attr_id does not exist
            assert(!self.ERC2114_attr_base.read(attr_id).is_valid(), Errors::ATTR_ID_ALREADY_EXIST);
            // create new attr_base 
            // @dev this function checks if attr type and name is valid
            let attr_base = AttrBaseTrait::new(name, attr_type);
            // if list id is attached check if list id exist
            if attr_base.val_type.get_list_id().is_non_zero() {
                let trait_catalog = self._get_trait_catalog();
                assert(
                    trait_catalog.trait_list_count() >= attr_base.val_type.get_list_id(),
                    Errors::INVALID_LIST_ID
                );
            }
            // add attr_base to storage
            self.ERC2114_attr_base.write(attr_id, attr_base);
            // emit event
            self.emit(AttributeCreated { attr_id, attr_type, name });
        }
    }
    // -------------------------------------------------------------------------- //
    //                             Internal Functions                             //
    // -------------------------------------------------------------------------- //
    #[generate_trait]
    impl ERC2114InternalImpl<
        TContractState,
        +HasComponent<TContractState>,
        +ERC721Component::HasComponent<TContractState>,
        +Drop<TContractState>
    > of ERC2114InternalTrait<TContractState> {
        // @dev ensures that token_id has no parent
        //  used for transfer functions on other token standards 
        //  to ensure token cant be transfered if its owned by a token
        #[inline(always)]
        fn _assert_token_no_parent(self: @ComponentState<TContractState>, token_id: u256) {
            assert(self.ERC2114_token_parent.read(token_id).is_zero(), 'ERC2114: token has parent');
        }

        fn _attributes_of(self: @ComponentState<TContractState>, token_id: u256) -> Array<u64> {
            let mut attr_ids = ArrayTrait::new();
            let mut index = 0;
            loop {
                let attr_pack = self.ERC2114_index_to_token_attr_pack.read((token_id, index));
                if !attr_pack.is_valid() {
                    break;
                }
                // unpack into array
                attr_pack.unpack_into(ref attr_ids);
                index += 1;
            };
            attr_ids
        }

        #[inline(always)]
        fn _token_of_token_by_index(
            self: @ComponentState<TContractState>, token_id: u256, index: u256
        ) -> Option<u256> {
            let child_id = self.ERC2114_index_to_token_child.read((token_id, index));
            match child_id.is_zero() {
                bool::False => Option::Some(child_id),
                bool::True => Option::None,
            }
        }

        // @dev transfer token to another token
        //  DOES NOT check validity of token_id or approval for transfer
        //  DOES NOT actually transfer token to address only sets balances, parent, and index
        #[inline(always)]
        fn _scalar_transfer(
            ref self: ComponentState<TContractState>,
            from: ContractAddress,
            token_id: u256,
            to_token_id: u256
        ) {
            // assert token id not transfering to self
            assert(token_id != to_token_id, 'ERC2114: cant transfer to self');
            // increase balance
            let cur_bal = self.ERC2114_token_balance.read(to_token_id);
            self.ERC2114_token_balance.write(to_token_id, cur_bal + 1);
            // set index
            self.ERC2114_index_to_token_child.write((to_token_id, cur_bal), token_id);
            // set parent
            self.ERC2114_token_parent.write(token_id, to_token_id);
            // emit event
            self.emit(ScalarTransfer { from, token_id, to_token_id });
        }

        // @dev remove token to another token
        //  DOES NOT check validity of token_id or approval for removal
        //  DOES NOT actually remove token to address only sets balances, parent, and index
        #[inline(always)]
        fn _scalar_remove(
            ref self: ComponentState<TContractState>,
            from_token_id: u256,
            token_id: u256,
            to: ContractAddress
        ) {
            // assert token id is child of from_token_id
            assert(
                self.ERC2114_token_parent.read(token_id) == from_token_id, Errors::INVALID_PARENT
            );
            // decrease balance
            let new_bal = self.ERC2114_token_balance.read(from_token_id) - 1;
            self.ERC2114_token_balance.write(from_token_id, new_bal);
            // unset index
            let cur_index = self._get_index_of_child_token(token_id);
            // if cur_index is not last index
            if cur_index != new_bal {
                // get last token id
                let last_token_id = self
                    .ERC2114_index_to_token_child
                    .read((from_token_id, new_bal));
                // set last token id to current index
                self.ERC2114_index_to_token_child.write((from_token_id, cur_index), last_token_id);
            }
            // unset last index to zero 
            self.ERC2114_index_to_token_child.write((from_token_id, new_bal), 0);
            // unset parent
            self.ERC2114_token_parent.write(token_id, 0);
            // emit event
            self.emit(ScalarRemove { from_token_id, token_id, to });
        }

        // @dev add attr_ids with corresponding values to token
        #[inline(always)]
        fn _add_attributes_to_token(
            ref self: ComponentState<TContractState>,
            token_id: u256,
            attr_ids: Span<u64>,
            values: Span<felt252>
        ) {
            // assert token_id exist
            assert(self.get_erc721_mut()._exist(token_id), Errors::INVALID_TOKEN_ID);
            // if attr_ids is empty return
            if attr_ids.len().is_zero() {
                return;
            }
            // @dev add corresponding values to token attr_ids 
            // this function emits TokenAttributeUpdate events
            // this function checks validity of attr_ids and values and ensure attr_ids are not repeats
            // returns new set of attr_ids that should be added to token to avoid repeats
            let new_attr_ids = self._add_token_attr_values(token_id, attr_ids, values);
            // add atr_ids to token
            self._attach_attr_ids_to_token(token_id, new_attr_ids);
        }

        // @dev remove attr_ids with corresponding values from token
        //  if attr_id is of type Number value can be subtracted
        //  if attr_id is of type String value can only be set to zero for removal
        #[inline(always)]
        fn _remove_attributes_from_token(
            ref self: ComponentState<TContractState>,
            token_id: u256,
            attr_ids: Span<u64>,
            values: Span<felt252>
        ) {
            // assert token_id exist
            assert(self.get_erc721_mut()._exist(token_id), Errors::INVALID_TOKEN_ID);
            // if attr_ids is empty return
            if attr_ids.len().is_zero() {
                return;
            }
            // @dev subtract corresponding values from token attr_ids 
            // this function emits TokenAttributeUpdate events
            // this function checks validity of attr_ids and values
            // returns new set of attr_ids that should be removed from token to avoid repeats
            let subtracted_attr_ids = self._subtract_token_attr_values(token_id, attr_ids, values);
            // remove atr_ids from token
            self._detach_attr_ids_from_token(token_id, subtracted_attr_ids);
        }

        // TODO: burn function for 2114
        fn _burn(ref self: ComponentState<TContractState>, token_id: u256) {
            // assert to_token_id is valid
            assert(self.get_erc721_mut()._exist(token_id), Errors::INVALID_TOKEN_ID);
            // assert token id has no parent
            self._assert_token_no_parent(token_id);
        // TODO: assert no children or clear out children
        // TODO: clear all attributes
        // TODO: burn token
        }
    }
    // -------------------------------------------------------------------------- //
    //                              Private Functions                             //
    // -------------------------------------------------------------------------- //
    #[generate_trait]
    impl ERC2114PrivateImpl<
        TContractState, +HasComponent<TContractState>
    > of ERC2114PrivateTrait<TContractState> {
        #[inline(always)]
        fn _get_trait_catalog(self: @ComponentState<TContractState>) -> ITraitCatalogDispatcher {
            let catalog_addr = self.ERC2114_trait_catalog_contract.read();
            assert(catalog_addr.is_non_zero(), Errors::INVALID_TRAIT_CATALOG);
            ITraitCatalogDispatcher { contract_address: catalog_addr }
        }

        // @dev get the index of token id in its parent
        fn _get_index_of_child_token(
            self: @ComponentState<TContractState>, token_id: u256
        ) -> u256 {
            let parent_id = self.ERC2114_token_parent.read(token_id);
            assert(parent_id.is_non_zero(), 'ERC2114: token has no parent');
            let mut index = 0;
            loop {
                if self.ERC2114_index_to_token_child.read((parent_id, index)) == token_id {
                    break;
                }
                index += 1;
            };
            index
        }

        // @dev get the final parent of token id
        // final parent is the last token in the chain of onwership that is not owned by any token
        fn _get_final_parent(self: @ComponentState<TContractState>, token_id: u256) -> u256 {
            let mut child_id = token_id;
            let final_parent_id = loop {
                let parent_id = self.ERC2114_token_parent.read(child_id);
                if parent_id.is_zero() {
                    break child_id;
                }
                child_id = parent_id;
            };
            final_parent_id
        }

        // @dev finds an available index that has space to store x ammount of attr_ids 
        // index is based on len of pack to determine if new index is needed or not
        fn _find_spot_for_attr_pack(
            self: @ComponentState<TContractState>, token_id: u256, ammount: u8
        ) -> u64 {
            // assert ammount needed to store is valid
            assert(ammount > 0 && ammount <= 3, Errors::INVALID_ATTR_PACK);
            let mut index: u64 = 0;
            loop {
                let pack: AttrPack = self.ERC2114_index_to_token_attr_pack.read((token_id, index));
                if pack.len + ammount <= 3 {
                    break;
                }
                index += 1;
            };
            index
        }

        // @dev finds the index that stores attr_id in token attr_packs
        //  DOES NOT check validity of attr_id or token_id 
        // if fails to find index will Panic
        fn _find_index_of_attr_in_token(
            self: @ComponentState<TContractState>, token_id: u256, attr_id: u64
        ) -> u64 {
            let mut index = 0;
            loop {
                let attr_pack = self.ERC2114_index_to_token_attr_pack.read((token_id, index));
                // if attr pack is not valid means index is out of bounds
                assert(attr_pack.is_valid(), 'ERC2114: failed to find attr_id');
                if attr_pack.has_attr(attr_id) {
                    break;
                }
                index += 1;
            };
            index
        }

        #[inline(always)]
        fn _add_trait_catalog(
            ref self: ComponentState<TContractState>, catalog_addr: ContractAddress
        ) {
            // assert added address is valid and has trait catalog interface
            assert(
                ISRC5Dispatcher { contract_address: catalog_addr }
                    .supports_interface(constants::ITRAIT_CATALOG_ID),
                Errors::INVALID_TRAIT_CATALOG
            );
            // set trait catalog address
            self.ERC2114_trait_catalog_contract.write(catalog_addr);
            // emit event
            self
                .emit(
                    TraitCatalogAttached {
                        from: get_caller_address(), trait_catalog_addr: catalog_addr
                    }
                );
        }

        // @dev adds batch of attr_ids to token attr_packs
        // DOES NOT check validity of attr_ids or if attr_ids have already been added
        fn _attach_attr_ids_to_token(
            ref self: ComponentState<TContractState>, token_id: u256, attr_ids: Span<u64>
        ) {
            // if attr_ids is empty return
            if attr_ids.len().is_zero() {
                return;
            }
            // get quotiont and remainder of attr_ids.len() / 3 
            // to see how many attr_packs can be generated
            let (q, r) = DivRem::div_rem(attr_ids.len(), 3_u32.try_into().expect('Division by 0'));
            // get the index of tokens attr_pack that can store attr_pack of size 3
            // this is used to avoid constant looping to find index
            let mut l_index_attr_pack = self._find_spot_for_attr_pack(token_id, 3);
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
                            .ERC2114_index_to_token_attr_pack
                            .write((token_id, l_index_attr_pack), AttrPackTrait::new(slice));
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
                    ._find_spot_for_attr_pack(token_id, r.try_into().unwrap());
                let mut attr_pack = self
                    .ERC2114_index_to_token_attr_pack
                    .read((token_id, index_attr_pack));
                // add attr_ids to attr_pack
                attr_pack.add_batch_to_pack(slice);
                self.ERC2114_index_to_token_attr_pack.write((token_id, index_attr_pack), attr_pack);
            }
        }

        // @dev removes a single attr id from token attr_packs
        // DOES NOT check validity of attr_id
        // @param 'l_index' is the last index of token attr_pack that is empty
        //  used to avoid recomputing l_index for batch removals 
        #[inline(always)]
        fn _detach_attr_id_from_token(
            ref self: ComponentState<TContractState>, ref l_index: u64, token_id: u256, attr_id: u64
        ) {
            // assert attr_id value has been set to zero
            assert(
                self.ERC2114_token_attr_value.read((token_id, attr_id)).is_zero(),
                'ERC2114: attr_id cant remove'
            );
            // get index that stores attr_id
            let index = self._find_index_of_attr_in_token(token_id, attr_id);
            let mut cur_attr_pack: AttrPack = self
                .ERC2114_index_to_token_attr_pack
                .read((token_id, index));
            // if cur attr pack is > 1 means attr_pack spot does not need to be replaced
            if cur_attr_pack.len > 1 {
                // remove attr_id from attr_pack
                cur_attr_pack.remove_from_pack(attr_id);
                self.ERC2114_index_to_token_attr_pack.write((token_id, index), cur_attr_pack);
                return;
            } else {
                // minus last index to get new supposed last index of empty spot
                l_index -= 1;
                // if index is not last index
                // replace cur_attr_pack index with last_attr_pack
                if index != l_index {
                    let last_attr_pack = self
                        .ERC2114_index_to_token_attr_pack
                        .read((token_id, l_index));
                    self.ERC2114_index_to_token_attr_pack.write((token_id, index), last_attr_pack);
                }
                // set last index to zero
                self
                    .ERC2114_index_to_token_attr_pack
                    .write((token_id, l_index), AttrPack { pack: 0, len: 0 });
            }
        }

        // @dev removes batch of attr_ids to token attr_packs
        // DOES NOT check validity of attr_ids 
        // ASSUMES token has attr_ids
        fn _detach_attr_ids_from_token(
            ref self: ComponentState<TContractState>, token_id: u256, mut attr_ids: Span<u64>
        ) {
            // get last index of token attr_packs
            let mut l_index = self._find_spot_for_attr_pack(token_id, 3);
            loop {
                match attr_ids.pop_front() {
                    Option::Some(attr_id) => {
                        self._detach_attr_id_from_token(ref l_index, token_id, *attr_id);
                    },
                    Option::None(_) => { break; }
                };
            };
        }

        // @dev adds batch of attr_ids and corresponding values to token
        // checks validity of value
        // if attr_id is of type string and exist MUST FAIL
        // if attr_Id is of type number add it to token current value
        // @return `new_attr_ids` a new set of attr_ids that should be added to token  
        //  `new_attr_ids` attr ids that should be added and does not exist with token yet 
        fn _add_token_attr_values(
            ref self: ComponentState<TContractState>,
            token_id: u256,
            mut attr_ids: Span<u64>,
            mut values: Span<felt252>
        ) -> Span<u64> {
            // assert that values and attr_ids len are the same length and length is not zero
            assert(attr_ids.len() == values.len(), Errors::INVALID_ID_OR_VALUE);
            let mut new_attr_ids = ArrayTrait::new();
            // loop through attr_ids and values and add them to token
            loop {
                match attr_ids.pop_front() {
                    Option::Some(attr_id) => {
                        let cur_value = self.ERC2114_token_attr_value.read((token_id, *attr_id));
                        let value = *values.pop_front().unwrap();
                        let attribute_base: AttrBase = self.ERC2114_attr_base.read(*attr_id);
                        let new_value: felt252 = match attribute_base.val_type {
                            AttrType::Empty => {
                                panic_with_felt252(Errors::INVALID_ATTR_ID);
                                0
                            },
                            AttrType::String(_) => {
                                // assert cur_value is zero to ensure attr id is not own
                                // as string type attributes cant be added only updated
                                assert(cur_value.is_zero(), Errors::ATTR_ID_ALREADY_EXIST);
                                // string type attr_id values cant be summable so return value
                                value
                            },
                            AttrType::Number(_) => {
                                // if its type Number means attr_id value is summable
                                cur_value + value
                            }
                        };
                        // assert new value is not zero
                        assert(new_value.is_non_zero(), Errors::INVALID_ATTR_VALUE);
                        // if new_value equals value means attr_id is new and does not exist with token
                        // so append it to new_attr_ids 
                        if new_value == value {
                            new_attr_ids.append(*attr_id);
                        }
                        // update values, emit events
                        // this function already checks validity of attr_id and its value
                        self._update_token_attr_value(token_id, *attr_id, new_value);
                    },
                    Option::None(_) => { break; }
                };
            };
            new_attr_ids.span()
        }

        // @dev subtracts batch of attr_ids and corresponding values from token
        // if attr_id type is NUMBER value subtracted MUST be lesser or equal than current value
        // if attr_id type is STRING value MUST be 0 as its not subtractable but is for removal
        // @return `subtracted_attr_ids` attr_ids that as their value set to zero
        //  and needs to be removed from  AttrPack
        fn _subtract_token_attr_values(
            ref self: ComponentState<TContractState>,
            token_id: u256,
            mut attr_ids: Span<u64>,
            mut values: Span<felt252>
        ) -> Span<u64> {
            // assert that values and attr_ids len are the same length and length is not zero
            assert(attr_ids.len() == values.len(), Errors::INVALID_ID_OR_VALUE);
            let mut new_attr_ids = ArrayTrait::new();
            // loop through attr_ids and values and subtract them to token
            loop {
                match attr_ids.pop_front() {
                    Option::Some(attr_id) => {
                        let value = *values.pop_front().unwrap();
                        let cur_value = self.ERC2114_token_attr_value.read((token_id, *attr_id));
                        // assert cur_value is non zero
                        assert(cur_value.is_non_zero(), 'ERC2114: attr_id not in token');
                        // assert attr_id is of type Number and subtracted value does not exceed current value
                        // assert attr_id is of String Type only can swap to zero cannot subtract
                        let attribute_base: AttrBase = self.ERC2114_attr_base.read(*attr_id);
                        let new_value = match attribute_base.val_type {
                            AttrType::Empty => {
                                panic_with_felt252(Errors::INVALID_ATTR_ID);
                                0
                            },
                            AttrType::String(_) => {
                                assert(value.is_zero(), Errors::INVALID_ATTR_VALUE);
                                value
                            },
                            AttrType::Number(_) => {
                                assert(
                                    Into::<felt252, u256>::into(value) <= cur_value.into(),
                                    Errors::INVALID_ATTR_VALUE
                                );
                                cur_value - value
                            }
                        };

                        // if new value is zero add to attr_ids array to be removed from AttrPack
                        if new_value.is_zero() {
                            new_attr_ids.append(*attr_id);
                        }

                        // update values, emit events
                        // this function already checks validity of attr_id and its value
                        self._update_token_attr_value(token_id, *attr_id, new_value);
                    },
                    Option::None(_) => { break; }
                };
            };
            new_attr_ids.span()
        }

        // @dev updates token attribute values and emit events 
        // DOES NOT check validity of token_id
        // DOES NOT check if token attr_id value have already been set
        // DOES NOT remove or add attr_id to pack
        // checks valilidty of attr_id and attr_id value 
        #[inline(always)]
        fn _update_token_attr_value(
            ref self: ComponentState<TContractState>, token_id: u256, attr_id: u64, value: felt252
        ) {
            // assert that attr_id exist
            let attr_base = self.ERC2114_attr_base.read(attr_id);
            assert(attr_base.is_valid(), Errors::INVALID_ATTR_ID);
            // if value is the same as current value return
            let cur_attr_value = self.ERC2114_token_attr_value.read((token_id, attr_id));
            if cur_attr_value == value {
                return;
            }

            // if value is not zero and attr_id has list_id attached 
            // check if value which == to index of trait list is valid
            let list_id = attr_base.val_type.get_list_id();
            if value.is_non_zero() && list_id.is_non_zero() {
                // assert value of index in trait list is not zero
                // as it means index in trait list has not been set
                assert(
                    self
                        ._get_trait_catalog()
                        .trait_list_value_by_index(list_id, value)
                        .is_non_zero(),
                    Errors::INVALID_ATTR_VALUE
                );
            }

            // update token attr value
            self.ERC2114_token_attr_value.write((token_id, attr_id), value);
            // emit event
            self
                .emit(
                    TokenAttributeUpdate {
                        token_id,
                        attr_id,
                        attr_type: attr_base.val_type,
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
