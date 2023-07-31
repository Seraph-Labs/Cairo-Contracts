use starknet::ContractAddress;
#[starknet::interface]
trait IERC721Mock<TContractState> {
    //src5 
    fn supports_interface(self: @TContractState, interface_id: felt252) -> bool;
    // Metadata functions
    fn name(self: @TContractState) -> felt252;
    fn symbol(self: @TContractState) -> felt252;
    fn token_uri(self: @TContractState, token_id: u256) -> Array<felt252>;
    fn set_base_uri(ref self: TContractState, base_uri: Array<felt252>);
    // 721 functions
    fn balance_of(self: @TContractState, owner: ContractAddress) -> u256;
    fn owner_of(self: @TContractState, token_id: u256) -> ContractAddress;
    fn get_approved(self: @TContractState, token_id: u256) -> ContractAddress;
    fn is_approved_for_all(
        self: @TContractState, owner: ContractAddress, operator: ContractAddress
    ) -> bool;
    fn approve(ref self: TContractState, approved: ContractAddress, token_id: u256);
    fn set_approval_for_all(ref self: TContractState, operator: ContractAddress, approved: bool);
    fn safe_transfer_from(
        ref self: TContractState,
        from: ContractAddress,
        to: ContractAddress,
        token_id: u256,
        data: Span<felt252>
    );
    fn transfer_from(
        ref self: TContractState, from: ContractAddress, to: ContractAddress, token_id: u256
    );
    fn mint(ref self: TContractState, to: ContractAddress, token_id: u256);
    fn safe_mint(
        ref self: TContractState, to: ContractAddress, token_id: u256, data: Span<felt252>
    );
    fn burn(ref self: TContractState, token_id: u256);
}

#[starknet::contract]
mod ERC721Mock {
    use seraphlabs::tokens::erc721::{ERC721, extensions::ERC721Metadata};
    use seraphlabs::tokens::src5::SRC5;
    use super::ContractAddress;

    #[storage]
    struct Storage {}

    #[constructor]
    fn constructor(ref self: ContractState, name: felt252, symbol: felt252) {
        let mut erc721_unsafe_state = ERC721::unsafe_new_contract_state();
        ERC721::InternalImpl::initializer(ref erc721_unsafe_state);
        let mut erc721_metadata_unsafe_state = ERC721Metadata::unsafe_new_contract_state();
        ERC721Metadata::InternalImpl::initializer(ref erc721_metadata_unsafe_state, name, symbol);
    }

    #[external(v0)]
    fn supports_interface(self: @ContractState, interface_id: felt252) -> bool {
        let unsafe_state = SRC5::unsafe_new_contract_state();
        SRC5::ISRC5Impl::supports_interface(@unsafe_state, interface_id)
    }

    #[generate_trait]
    #[external(v0)]
    impl MetadataImpl of MetadataTrait {
        fn name(self: @ContractState) -> felt252 {
            let erc721_metadata_unsafe_state = ERC721Metadata::unsafe_new_contract_state();
            ERC721Metadata::IERC721MetadataImpl::name(@erc721_metadata_unsafe_state)
        }

        fn symbol(self: @ContractState) -> felt252 {
            let erc721_metadata_unsafe_state = ERC721Metadata::unsafe_new_contract_state();
            ERC721Metadata::IERC721MetadataImpl::symbol(@erc721_metadata_unsafe_state)
        }

        fn token_uri(self: @ContractState, token_id: u256) -> Array<felt252> {
            let erc721_metadata_unsafe_state = ERC721Metadata::unsafe_new_contract_state();
            ERC721Metadata::IERC721MetadataImpl::token_uri(@erc721_metadata_unsafe_state, token_id)
        }

        fn set_base_uri(ref self: ContractState, base_uri: Array<felt252>) {
            let mut erc721_metadata_unsafe_state = ERC721Metadata::unsafe_new_contract_state();
            ERC721Metadata::InternalImpl::_set_base_uri(ref erc721_metadata_unsafe_state, base_uri);
        }
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

        fn safe_transfer_from(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            data: Span<felt252>
        ) {
            let mut erc721_unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::IERC721Impl::safe_transfer_from(
                ref erc721_unsafe_state, from, to, token_id, data
            );
        }

        fn transfer_from(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            let mut erc721_unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::IERC721Impl::transfer_from(ref erc721_unsafe_state, from, to, token_id);
        }

        fn mint(ref self: ContractState, to: ContractAddress, token_id: u256) {
            let mut erc721_unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::InternalImpl::_mint(ref erc721_unsafe_state, to, token_id);
        }

        fn safe_mint(
            ref self: ContractState, to: ContractAddress, token_id: u256, data: Span<felt252>
        ) {
            let mut erc721_unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::InternalImpl::_safe_mint(ref erc721_unsafe_state, to, token_id, data);
        }

        fn burn(ref self: ContractState, token_id: u256) {
            let mut erc721_unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::InternalImpl::_burn(ref erc721_unsafe_state, token_id);
        }
    }
}
