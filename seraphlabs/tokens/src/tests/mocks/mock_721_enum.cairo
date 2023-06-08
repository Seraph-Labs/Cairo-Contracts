#[contract]
mod Mock721EnumContract {
    use seraphlabs_tokens::erc721::{ERC721, ERC721Metadata, ERC721Enumerable as ERC721Enum};
    use seraphlabs_tokens::utils::erc165::ERC165;
    use starknet::ContractAddress;
    use array::ArrayTrait;
    use option::OptionTrait;


    #[constructor]
    fn constructor(name: felt252, symbol: felt252) {
        ERC721Metadata::initializer(name, symbol);
        ERC721::initializer();
        ERC721Enum::initializer();
    }

    #[view]
    fn supports_interface(interface_id: u32) -> bool {
        ERC165::supports_interface(interface_id)
    }

    #[view]
    fn name() -> felt252 {
        ERC721Metadata::name()
    }

    #[view]
    fn symbol() -> felt252 {
        ERC721Metadata::symbol()
    }

    #[view]
    fn token_uri(token_id: u256) -> Array<felt252> {
        ERC721Metadata::token_uri(token_id)
    }

    #[view]
    fn balance_of(owner: ContractAddress) -> u256 {
        ERC721::balance_of(owner)
    }

    #[view]
    fn owner_of(token_id: u256) -> ContractAddress {
        ERC721::owner_of(token_id)
    }

    #[view]
    fn get_approved(token_id: u256) -> ContractAddress {
        ERC721::get_approved(token_id)
    }

    #[view]
    fn is_approved_for_all(owner: ContractAddress, operator: ContractAddress) -> bool {
        ERC721::is_approved_for_all(owner, operator)
    }

    #[view]
    fn total_supply() -> u256 {
        ERC721Enum::total_supply()
    }

    #[view]
    fn token_by_index(index: u256) -> u256 {
        ERC721Enum::token_by_index(index)
    }

    #[view]
    fn token_of_owner_by_index(owner: ContractAddress, index: u256) -> u256 {
        ERC721Enum::token_of_owner_by_index(owner, index)
    }

    // -------------------------------------------------------------------------- //
    //                                  Externals                                 //
    // -------------------------------------------------------------------------- //

    #[external]
    fn set_base_uri(base_uri: Array<felt252>) {
        ERC721Metadata::set_base_uri(base_uri);
    }

    #[external]
    fn approve(to: ContractAddress, token_id: u256) {
        ERC721::approve(to, token_id)
    }

    #[external]
    fn set_approval_for_all(operator: ContractAddress, approved: bool) {
        ERC721::set_approval_for_all(operator, approved)
    }

    #[external]
    fn safe_transfer_from(
        from: ContractAddress, to: ContractAddress, token_id: u256, data: Span<felt252>
    ) {
        ERC721Enum::safe_transfer_from(from, to, token_id, data)
    }

    #[external]
    fn transfer_from(from: ContractAddress, to: ContractAddress, token_id: u256) {
        ERC721Enum::transfer_from(from, to, token_id)
    }

    #[external]
    fn mint(to: ContractAddress, token_id: u256) {
        ERC721Enum::_mint(to, token_id)
    }

    #[external]
    fn burn(token_id: u256) {
        ERC721Enum::_burn(token_id)
    }
}
