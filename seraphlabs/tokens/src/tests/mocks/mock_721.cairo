#[contract]
mod Mock721Contract{
    use seraphlabs_tokens::erc721::{ERC721, ERC721Metadata};
    use starknet::ContractAddress;
    use array::ArrayTrait;
    use option::OptionTrait;


    #[constructor]
    fn constructor(name : felt252, symbol : felt252){
        ERC721Metadata::initializer(name, symbol);
        ERC721::initializer();
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
        ERC721::safe_transfer_from(from, to, token_id, data)
    }

    #[external]
    fn transfer_from(from: ContractAddress, to: ContractAddress, token_id: u256) {
        ERC721::transfer_from(from, to, token_id)
    }

    #[external]
    fn mint(to: ContractAddress, token_id: u256) {
        ERC721::_mint(to, token_id)
    }

    #[external]
    fn burn(token_id: u256) {
        ERC721::_burn(token_id)
    }
}
