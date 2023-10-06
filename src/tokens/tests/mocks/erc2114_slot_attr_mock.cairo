use starknet::ContractAddress;
use seraphlabs::tokens::erc2114::utils::AttrType;

#[starknet::interface]
trait IERC2114SlotAttrMock<TContractState> {
    //src5 
    fn supports_interface(self: @TContractState, interface_id: felt252) -> bool;
    // 721 functions
    fn balance_of(self: @TContractState, owner: ContractAddress) -> u256;
    fn owner_of(self: @TContractState, token_id: u256) -> ContractAddress;
    fn get_approved(self: @TContractState, token_id: u256) -> ContractAddress;
    fn is_approved_for_all(
        self: @TContractState, owner: ContractAddress, operator: ContractAddress
    ) -> bool;
    fn approve(ref self: TContractState, approved: ContractAddress, token_id: u256);
    fn set_approval_for_all(ref self: TContractState, operator: ContractAddress, approved: bool);
    // 721 enum functions
    fn token_of_owner_by_index(self: @TContractState, owner: ContractAddress, index: u256) -> u256;
    fn transfer_from(
        ref self: TContractState, from: ContractAddress, to: ContractAddress, token_id: u256
    );
    fn mint(ref self: TContractState, to: ContractAddress, token_id: u256);
    // 2114 functions
    fn get_trait_catalog(self: @TContractState) -> ContractAddress;

    fn token_balance_of(self: @TContractState, token_id: u256) -> u256;

    fn token_of(self: @TContractState, token_id: u256) -> u256;

    fn token_of_token_by_index(self: @TContractState, token_id: u256, index: u256) -> u256;

    fn attribute_name(self: @TContractState, attr_id: u64) -> felt252;

    fn attribute_type(self: @TContractState, attr_id: u64) -> AttrType;

    fn attribute_value(self: @TContractState, token_id: u256, attr_id: u64) -> felt252;

    fn attributes_of(self: @TContractState, token_id: u256) -> Span<u64>;

    fn scalar_transfer_from(
        ref self: TContractState, from: ContractAddress, token_id: u256, to_token_id: u256
    );

    fn scalar_remove_from(ref self: TContractState, from_token_id: u256, token_id: u256);

    fn create_attribute(ref self: TContractState, attr_id: u64, attr_type: AttrType, name: felt252);

    // 2114 slot attribute functions
    fn slot_attribute_value(self: @TContractState, slot_id: u256, attr_id: u64) -> felt252;

    fn slot_attributes_of(self: @TContractState, slot_id: u256) -> Span<u64>;

    fn set_slot_attribute(ref self: TContractState, slot_id: u256, attr_id: u64, value: felt252);

    fn batch_set_slot_attribute(
        ref self: TContractState, slot_id: u256, attr_ids: Span<u64>, values: Span<felt252>
    );
    // @dev private 2114 slot attribute functions for testing purposes
    fn remove_attributes_from_slot(ref self: TContractState, slot_id: u256, attr_ids: Span<u64>);
}

#[starknet::contract]
mod ERC2114SlotAttrMock {
    use super::ContractAddress;
    use super::AttrType;
    use seraphlabs::tokens::erc2114::{ERC2114Component, extensions::ERC2114SlotAttrComponent};
    use seraphlabs::tokens::erc721::{ERC721Component, extensions::ERC721EnumComponent};
    use seraphlabs::tokens::src5::SRC5Component;

    use ERC721Component::{IERC721Impl, ERC721InitializerImpl};
    use ERC721EnumComponent::{IERC721EnumImpl, ERC721EnumInternalImpl, ERC721EnumInitializerImpl};
    use ERC2114Component::{ERC2114InternalImpl, ERC2114InitializerImpl};
    use ERC2114SlotAttrComponent::{ERC2114SlotAttrInternalImpl, ERC2114SlotAttrInitializerImpl};

    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: ERC721EnumComponent, storage: erc721_enum, event: ERC721EnumEvent);
    component!(path: ERC2114Component, storage: erc2114, event: ERC2114Event);
    component!(
        path: ERC2114SlotAttrComponent, storage: erc2114_slot_attr, event: ERC2114SlotAttrEvent
    );

    #[abi(embed_v0)]
    impl SRC5 = SRC5Component::SRC5Impl<ContractState>;

    #[abi(embed_v0)]
    impl ERC2114 = ERC2114Component::ERC2114Impl<ContractState>;

    #[abi(embed_v0)]
    impl ERC2114SlotAttr =
        ERC2114SlotAttrComponent::ERC2114SlotAttrImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        erc721_enum: ERC721EnumComponent::Storage,
        #[substorage(v0)]
        erc2114: ERC2114Component::Storage,
        #[substorage(v0)]
        erc2114_slot_attr: ERC2114SlotAttrComponent::Storage,
    }

    #[event]
    #[derive(Drop, PartialEq, starknet::Event)]
    enum Event {
        SRC5Event: SRC5Component::Event,
        ERC721Event: ERC721Component::Event,
        ERC721EnumEvent: ERC721EnumComponent::Event,
        ERC2114Event: ERC2114Component::Event,
        ERC2114SlotAttrEvent: ERC2114SlotAttrComponent::Event,
    }

    #[constructor]
    fn constructor(ref self: ContractState, trait_catalog: ContractAddress) {
        self.erc721.initializer();
        self.erc721_enum.initializer();
        self.erc2114.initializer(trait_catalog);
        self.erc2114_slot_attr.initializer();
    }

    #[generate_trait]
    #[external(v0)]
    impl Base721Impl of Base721Trait {
        fn balance_of(self: @ContractState, owner: ContractAddress) -> u256 {
            self.erc721.balance_of(owner)
        }

        fn owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            self.erc721.owner_of(token_id)
        }

        fn get_approved(self: @ContractState, token_id: u256) -> ContractAddress {
            self.erc721.get_approved(token_id)
        }

        fn is_approved_for_all(
            self: @ContractState, owner: ContractAddress, operator: ContractAddress
        ) -> bool {
            self.erc721.is_approved_for_all(owner, operator)
        }

        fn approve(ref self: ContractState, approved: ContractAddress, token_id: u256) {
            self.erc721.approve(approved, token_id);
        }

        fn set_approval_for_all(
            ref self: ContractState, operator: ContractAddress, approved: bool
        ) {
            self.erc721.set_approval_for_all(operator, approved);
        }
    }

    #[generate_trait]
    #[external(v0)]
    impl Base721EnumImpl of Base721EnumTrait {
        fn token_of_owner_by_index(
            self: @ContractState, owner: ContractAddress, index: u256
        ) -> u256 {
            self.erc721_enum.token_of_owner_by_index(owner, index)
        }

        fn transfer_from(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            self.erc2114._assert_token_no_parent(token_id);
            self.erc721_enum.transfer_from(from, to, token_id);
        }

        fn mint(ref self: ContractState, to: ContractAddress, token_id: u256) {
            self.erc721_enum._mint(to, token_id);
        }
    }

    #[generate_trait]
    #[external(v0)]
    impl Base2114SlotAttrImpl of Base2114SlotAttrTrait {
        fn remove_attributes_from_slot(
            ref self: ContractState, slot_id: u256, attr_ids: Span<u64>
        ) {
            self.erc2114_slot_attr._remove_attributes_from_slot(slot_id, attr_ids);
        }
    }
}
