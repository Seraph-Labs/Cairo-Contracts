use starknet::ContractAddress;
use seraphlabs::tokens::erc2114::utils::AttrType;

#[starknet::interface]
trait IERC2114Mock<TContractState> {
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

    // @dev private 2114 functions for testing purposes
    fn add_attributes_to_token(
        ref self: TContractState, token_id: u256, attr_ids: Span<u64>, values: Span<felt252>
    );
    fn remove_attributes_from_token(
        ref self: TContractState, token_id: u256, attr_ids: Span<u64>, values: Span<felt252>
    );
}

#[starknet::contract]
mod ERC2114Mock {
    use seraphlabs::tokens::erc2114::ERC2114;
    use seraphlabs::tokens::erc721::{ERC721, extensions::ERC721Enumerable as ERC721Enum};
    use seraphlabs::tokens::src5::SRC5;
    use super::ContractAddress;
    use super::AttrType;

    #[storage]
    struct Storage {}

    #[constructor]
    fn constructor(ref self: ContractState, trait_catalog: ContractAddress) {
        let mut erc721_unsafe_state = ERC721::unsafe_new_contract_state();
        ERC721::InternalImpl::initializer(ref erc721_unsafe_state);
        let mut erc721_enum_unsafe_state = ERC721Enum::unsafe_new_contract_state();
        ERC721Enum::InternalImpl::initializer(ref erc721_enum_unsafe_state);
        let mut erc2114_unsafe_state = ERC2114::unsafe_new_contract_state();
        ERC2114::InternalImpl::initializer(ref erc2114_unsafe_state, trait_catalog);
    }

    #[external(v0)]
    fn supports_interface(self: @ContractState, interface_id: felt252) -> bool {
        let unsafe_state = SRC5::unsafe_new_contract_state();
        SRC5::ISRC5Impl::supports_interface(@unsafe_state, interface_id)
    }

    #[generate_trait]
    #[external(v0)]
    impl Base721Impl of Base721Trait {
        fn balance_of(self: @ContractState, owner: ContractAddress) -> u256 {
            let erc721_unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::IERC721Impl::balance_of(@erc721_unsafe_state, owner)
        }

        fn owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            let erc721_unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::IERC721Impl::owner_of(@erc721_unsafe_state, token_id)
        }

        fn get_approved(self: @ContractState, token_id: u256) -> ContractAddress {
            let erc721_unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::IERC721Impl::get_approved(@erc721_unsafe_state, token_id)
        }

        fn is_approved_for_all(
            self: @ContractState, owner: ContractAddress, operator: ContractAddress
        ) -> bool {
            let erc721_unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::IERC721Impl::is_approved_for_all(@erc721_unsafe_state, owner, operator)
        }

        fn approve(ref self: ContractState, approved: ContractAddress, token_id: u256) {
            let mut erc721_unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::IERC721Impl::approve(ref erc721_unsafe_state, approved, token_id);
        }

        fn set_approval_for_all(
            ref self: ContractState, operator: ContractAddress, approved: bool
        ) {
            let mut erc721_unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::IERC721Impl::set_approval_for_all(ref erc721_unsafe_state, operator, approved);
        }
    }

    #[generate_trait]
    #[external(v0)]
    impl Base721EnumImpl of Base721EnumTrait {
        fn token_of_owner_by_index(
            self: @ContractState, owner: ContractAddress, index: u256
        ) -> u256 {
            let erc721_enum_unsafe_state = ERC721Enum::unsafe_new_contract_state();
            ERC721Enum::IERC721EnumImpl::token_of_owner_by_index(
                @erc721_enum_unsafe_state, owner, index
            )
        }

        fn transfer_from(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            let erc2114_unsafe_state = ERC2114::unsafe_new_contract_state();
            ERC2114::InternalImpl::_assert_token_no_parent(@erc2114_unsafe_state, token_id);

            let mut erc721_enum_unsafe_state = ERC721Enum::unsafe_new_contract_state();
            ERC721Enum::InternalImpl::transfer_from(
                ref erc721_enum_unsafe_state, from, to, token_id
            );
        }

        fn mint(ref self: ContractState, to: ContractAddress, token_id: u256) {
            let mut unsafe_state = ERC721Enum::unsafe_new_contract_state();
            ERC721Enum::InternalImpl::_mint(ref unsafe_state, to, token_id);
        }
    }


    #[generate_trait]
    #[external(v0)]
    impl Base2114impl of Base2114Trait {
        fn get_trait_catalog(self: @ContractState) -> ContractAddress {
            let erc2114_unsafe_state = ERC2114::unsafe_new_contract_state();
            ERC2114::IERC2114Impl::get_trait_catalog(@erc2114_unsafe_state)
        }

        fn token_balance_of(self: @ContractState, token_id: u256) -> u256 {
            let erc2114_unsafe_state = ERC2114::unsafe_new_contract_state();
            ERC2114::IERC2114Impl::token_balance_of(@erc2114_unsafe_state, token_id)
        }

        fn token_of(self: @ContractState, token_id: u256) -> u256 {
            let erc2114_unsafe_state = ERC2114::unsafe_new_contract_state();
            ERC2114::IERC2114Impl::token_of(@erc2114_unsafe_state, token_id)
        }

        fn token_of_token_by_index(self: @ContractState, token_id: u256, index: u256) -> u256 {
            let erc2114_unsafe_state = ERC2114::unsafe_new_contract_state();
            ERC2114::IERC2114Impl::token_of_token_by_index(@erc2114_unsafe_state, token_id, index)
        }

        fn attribute_name(self: @ContractState, attr_id: u64) -> felt252 {
            let erc2114_unsafe_state = ERC2114::unsafe_new_contract_state();
            ERC2114::IERC2114Impl::attribute_name(@erc2114_unsafe_state, attr_id)
        }

        fn attribute_type(self: @ContractState, attr_id: u64) -> AttrType {
            let erc2114_unsafe_state = ERC2114::unsafe_new_contract_state();
            ERC2114::IERC2114Impl::attribute_type(@erc2114_unsafe_state, attr_id)
        }

        fn attribute_value(self: @ContractState, token_id: u256, attr_id: u64) -> felt252 {
            let erc2114_unsafe_state = ERC2114::unsafe_new_contract_state();
            ERC2114::IERC2114Impl::attribute_value(@erc2114_unsafe_state, token_id, attr_id)
        }

        fn attributes_of(self: @ContractState, token_id: u256) -> Span<u64> {
            let erc2114_unsafe_state = ERC2114::unsafe_new_contract_state();
            ERC2114::IERC2114Impl::attributes_of(@erc2114_unsafe_state, token_id)
        }

        fn scalar_transfer_from(
            ref self: ContractState, from: ContractAddress, token_id: u256, to_token_id: u256
        ) {
            let mut erc2114_unsafe_state = ERC2114::unsafe_new_contract_state();
            ERC2114::IERC2114Impl::scalar_transfer_from(
                ref erc2114_unsafe_state, from, token_id, to_token_id
            );
        }

        fn scalar_remove_from(ref self: ContractState, from_token_id: u256, token_id: u256) {
            let mut erc2114_unsafe_state = ERC2114::unsafe_new_contract_state();
            ERC2114::IERC2114Impl::scalar_remove_from(
                ref erc2114_unsafe_state, from_token_id, token_id
            );
        }

        fn create_attribute(
            ref self: ContractState, attr_id: u64, attr_type: AttrType, name: felt252
        ) {
            let mut erc2114_unsafe_state = ERC2114::unsafe_new_contract_state();
            ERC2114::IERC2114Impl::create_attribute(
                ref erc2114_unsafe_state, attr_id, attr_type, name
            );
        }

        fn add_attributes_to_token(
            ref self: ContractState, token_id: u256, attr_ids: Span<u64>, values: Span<felt252>
        ) {
            let mut erc2114_unsafe_state = ERC2114::unsafe_new_contract_state();
            ERC2114::InternalImpl::_add_attributes_to_token(
                ref erc2114_unsafe_state, token_id, attr_ids, values
            );
        }

        fn remove_attributes_from_token(
            ref self: ContractState, token_id: u256, attr_ids: Span<u64>, values: Span<felt252>
        ) {
            let mut erc2114_unsafe_state = ERC2114::unsafe_new_contract_state();
            ERC2114::InternalImpl::_remove_attributes_from_token(
                ref erc2114_unsafe_state, token_id, attr_ids, values
            );
        }
    }
}
