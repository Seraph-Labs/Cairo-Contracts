#[contract]
mod Mock3525Contract {
    use seraphlabs_tokens::erc721::{ERC721, ERC721Enumerable as ERC721Enum};
    use seraphlabs_tokens::erc3525::ERC3525;
    use seraphlabs_tokens::utils::erc165::ERC165;
    use starknet::ContractAddress;
    use array::ArrayTrait;
    use option::OptionTrait;


    #[constructor]
    fn constructor(value_decimals: u8) {
        ERC721::initializer();
        ERC721Enum::initializer();
        ERC3525::initializer(value_decimals);
    }

    #[view]
    fn supports_interface(interface_id: u32) -> bool {
        ERC165::supports_interface(interface_id)
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

    #[view]
    fn value_decimals() -> u8 {
        ERC3525::value_decimals()
    }

    #[view]
    fn value_of(token_id: u256) -> u256 {
        ERC3525::value_of(token_id)
    }

    #[view]
    fn slot_of(token_id: u256) -> u256 {
        ERC3525::slot_of(token_id)
    }

    #[view]
    fn allowance(token_id: u256, operator: ContractAddress) -> u256 {
        ERC3525::allowance(token_id, operator)
    }

    // -------------------------------------------------------------------------- //
    //                                  Externals                                 //
    // -------------------------------------------------------------------------- //

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
        ERC3525::_clear_value_approvals(token_id);
        ERC721Enum::safe_transfer_from(from, to, token_id, data)
    }

    #[external]
    fn transfer_from(from: ContractAddress, to: ContractAddress, token_id: u256) {
        ERC3525::_clear_value_approvals(token_id);
        ERC721Enum::transfer_from(from, to, token_id)
    }

    #[external]
    fn approve_value(token_id: u256, operator: ContractAddress, value: u256) {
        ERC3525::approve_value(token_id, operator, value)
    }

    #[external]
    fn transfer_value_from(from_token_id: u256, to: ContractAddress, value: u256) -> u256 {
        ERC3525::transfer_value_from(from_token_id, to, value)
    }

    #[external]
    fn mint(to: ContractAddress, token_id: u256, slot_id: u256, value: u256) {
        ERC3525::_mint(to, token_id, slot_id, value)
    }

    #[external]
    fn mint_value(to_token_id: u256, value: u256) {
        ERC3525::_mint_value(to_token_id, value)
    }

    #[external]
    fn burn(token_id: u256) {
        ERC3525::_burn(token_id)
    }

    #[external]
    fn burn_value(token_id: u256, value: u256) {
        ERC3525::_burn_value(token_id, value)
    }
}
