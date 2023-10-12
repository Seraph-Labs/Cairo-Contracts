use starknet::ContractAddress;
use seraphlabs::tokens::erc2114::utils::AttrType;

#[starknet::interface]
trait IERC2114InvMock<TContractState> {
    //src5 
    fn supports_interface(self: @TContractState, interface_id: felt252) -> bool;
    // 721 functions
    fn balance_of(self: @TContractState, owner: ContractAddress) -> u256;
    fn owner_of(self: @TContractState, token_id: u256) -> ContractAddress;
    fn approve(ref self: TContractState, approved: ContractAddress, token_id: u256);
    fn set_approval_for_all(ref self: TContractState, operator: ContractAddress, approved: bool);
    // 721 enum functions
    fn token_of_owner_by_index(self: @TContractState, owner: ContractAddress, index: u256) -> u256;
    // 3525 functions
    fn slot_of(self: @TContractState, token_id: u256) -> u256;
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

    // 2114 inv functions
    fn equipped_attribute_value(self: @TContractState, token_id: u256, attr_id: u64) -> felt252;

    fn is_inside_inventory(self: @TContractState, token_id: u256, child_id: u256) -> bool;

    fn token_supply_in_inventory(self: @TContractState, token_id: u256, criteria: u256) -> u64;

    fn inventory_of(self: @TContractState, token_id: u256) -> Span<u256>;

    fn inventory_attributes_of(self: @TContractState, slot_id: u256) -> Span<u64>;

    fn slot_criteria_capacity(self: @TContractState, slot_id: u256, criteria: u256) -> u64;

    fn edit_inventory(ref self: TContractState, token_id: u256, child_id: u256, equipped: bool);

    fn set_slot_criteria(ref self: TContractState, slot_id: u256, criteria: u256, capacity: u64);

    fn set_inventory_attributes(ref self: TContractState, slot_id: u256, attr_ids: Span<u64>);

    // 2114 inv other implemented functions
    // this is the ERC2114Inv mofiied version of the function
    // left the original in to test edit inventory
    fn scalar_transfer_from_2(
        ref self: TContractState, from: ContractAddress, token_id: u256, to_token_id: u256
    );

    // this is the ERC2114Inv mofiied version of the function
    // left the original in to test edit inventory
    fn scalar_remove_from_2(ref self: TContractState, from_token_id: u256, token_id: u256);

    fn mint_pill(
        ref self: TContractState, to: ContractAddress, token_id: u256, medical_bill: felt252
    );

    fn mint_ing(
        ref self: TContractState,
        to: ContractAddress,
        token_id: u256,
        ing: felt252,
        medical_bill: felt252
    );

    fn mint_bg(
        ref self: TContractState,
        to: ContractAddress,
        token_id: u256,
        bg: felt252,
        medical_bill: felt252
    );
}

#[starknet::contract]
mod ERC2114InvMock {
    use seraphlabs::tokens::erc2114::erc2114::ERC2114Component::ERC2114InternalTrait;
    use super::ContractAddress;
    use super::AttrType;
    use seraphlabs::tokens::erc2114::{ERC2114Component, extensions::ERC2114InvComponent};
    use seraphlabs::tokens::erc721::{ERC721Component, extensions::ERC721EnumComponent};
    use seraphlabs::tokens::erc3525::ERC3525Component;
    use seraphlabs::tokens::src5::SRC5Component;

    use ERC721Component::{IERC721Impl, ERC721InitializerImpl};
    use ERC721EnumComponent::{IERC721EnumImpl, ERC721EnumInternalImpl, ERC721EnumInitializerImpl};
    use ERC3525Component::{ERC3525InitializerImpl, ERC3525InternalImpl, IERC3525Impl};
    use ERC2114Component::{ERC2114InternalImpl, ERC2114InitializerImpl, IERC2114Impl};
    use ERC2114InvComponent::{ERC2114InvInternalImpl, ERC2114InvInitializerImpl};

    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: ERC721EnumComponent, storage: erc721_enum, event: ERC721EnumEvent);
    component!(path: ERC3525Component, storage: erc3525, event: ERC3525Event);
    component!(path: ERC2114Component, storage: erc2114, event: ERC2114Event);
    component!(path: ERC2114InvComponent, storage: erc2114_inv, event: ERC2114InvEvent);

    #[abi(embed_v0)]
    impl SRC5 = SRC5Component::SRC5Impl<ContractState>;

    #[abi(embed_v0)]
    impl ERC2114 = ERC2114Component::ERC2114Impl<ContractState>;

    #[abi(embed_v0)]
    impl ERC2114Inv = ERC2114InvComponent::ERC2114InvImpl<ContractState>;


    #[storage]
    struct Storage {
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        erc721_enum: ERC721EnumComponent::Storage,
        #[substorage(v0)]
        erc3525: ERC3525Component::Storage,
        #[substorage(v0)]
        erc2114: ERC2114Component::Storage,
        #[substorage(v0)]
        erc2114_inv: ERC2114InvComponent::Storage,
    }

    #[event]
    #[derive(Drop, PartialEq, starknet::Event)]
    enum Event {
        SRC5Event: SRC5Component::Event,
        ERC721Event: ERC721Component::Event,
        ERC721EnumEvent: ERC721EnumComponent::Event,
        ERC3525Event: ERC3525Component::Event,
        ERC2114Event: ERC2114Component::Event,
        ERC2114InvEvent: ERC2114InvComponent::Event,
    }

    #[constructor]
    fn constructor(ref self: ContractState, trait_catalog: ContractAddress, val: bool) {
        self.erc721.initializer();
        self.erc721_enum.initializer();
        self.erc2114.initializer(trait_catalog);
        self.erc3525.initializer(18);
        self.erc2114_inv.initializer();
        if val {
            // create attributes
            // create attr_id 1 -> name: from list_id 1
            // 1. pill, 2.ingredient, 3.background
            self.create_attribute(1, AttrType::String(1), 'name');
            // attr_id 2 -> ingredient: any value
            self.create_attribute(2, AttrType::String(0), 'ingredient');
            // attr_id 3 -> background: list_id 2
            // 1. yellow, 2.pink, 3.purple
            self.create_attribute(3, AttrType::String(2), 'background');
            self.create_attribute(4, AttrType::Number(0), 'medical_bill');
        }
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
    }

    #[generate_trait]
    #[external(v0)]
    impl Base3525Impl of Base3525Trait {
        fn slot_of(self: @ContractState, token_id: u256) -> u256 {
            self.erc3525.slot_of(token_id)
        }
    }

    #[generate_trait]
    #[external(v0)]
    impl Base2114InvImpl of Base2114InvTrait {
        fn scalar_transfer_from_2(
            ref self: ContractState, from: ContractAddress, token_id: u256, to_token_id: u256
        ) {
            self.erc2114_inv.scalar_transfer_from(from, token_id, to_token_id);
        }

        fn scalar_remove_from_2(ref self: ContractState, from_token_id: u256, token_id: u256) {
            self.erc2114_inv.scalar_remove_from(from_token_id, token_id);
        }

        fn mint_pill(
            ref self: ContractState, to: ContractAddress, token_id: u256, medical_bill: felt252
        ) {
            // mint token slot 1 value 0
            self.erc3525._mint(to, token_id, 1, 0);
            // add pill attribute name
            if medical_bill.is_zero() {
                // add attr_id 1 -> name at index 1 which is pill
                self.erc2114._add_attributes_to_token(token_id, array![1].span(), array![1].span());
                return;
            }

            // add attr_id 1 -> name at index 1 which is pill
            // add attr_id 4 -> medical bill 
            self
                .erc2114
                ._add_attributes_to_token(
                    token_id, array![1, 4].span(), array![1, medical_bill].span()
                );
        }

        fn mint_ing(
            ref self: ContractState,
            to: ContractAddress,
            token_id: u256,
            ing: felt252,
            medical_bill: felt252
        ) {
            // mint token slot 2 value 0
            self.erc3525._mint(to, token_id, 2, 0);
            assert(ing.is_non_zero(), 'ing is zero');
            // add pill attribute name
            if medical_bill.is_zero() {
                // add attr_id 1 -> name at index 2 which is ing
                // add attr_id 2 -> ingredient at 
                self
                    .erc2114
                    ._add_attributes_to_token(token_id, array![1, 2].span(), array![2, ing].span());
                return;
            }

            // add attr_id 1 -> name at index 2 which is ing
            // add attr_id 2 -> ingredient at 
            // add attr_id 4 -> medical bill 
            self
                .erc2114
                ._add_attributes_to_token(
                    token_id, array![1, 2, 4].span(), array![2, ing, medical_bill].span()
                );
        }

        fn mint_bg(
            ref self: ContractState,
            to: ContractAddress,
            token_id: u256,
            bg: felt252,
            medical_bill: felt252
        ) {
            // mint token slot 3 value 0
            self.erc3525._mint(to, token_id, 3, 0);
            assert(bg.is_non_zero(), 'bg is zero');
            // add pill attribute name
            if medical_bill.is_zero() {
                // add attr_id 1 -> name at index 3 which is bg
                // add attr_id 3 -> background  
                self
                    .erc2114
                    ._add_attributes_to_token(token_id, array![1, 3].span(), array![3, bg].span());
                return;
            }

            // add attr_id 1 -> name at index 3 which is bg
            // add attr_id 3 -> background at 
            // add attr_id 4 -> medical bill 
            self
                .erc2114
                ._add_attributes_to_token(
                    token_id, array![1, 3, 4].span(), array![3, bg, medical_bill].span()
                );
        }
    }
}
