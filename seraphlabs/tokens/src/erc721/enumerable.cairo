// ----------------------------- library imports ---------------------------- //
use super::ERC721;
use super::interface;

// ------------------------------ base library ------------------------------ //
#[contract]
mod ERC721Enumerable{
    // seraphlabs imports
    use seraphlabs_utils::constants;
    use super::interface::IERC721Enumerable;
    use super::ERC721;
    // starknet imports
    use starknet::get_caller_address;
    use starknet::contract_address_const;
    use starknet::ContractAddressIntoFelt252;
    use starknet::ContractAddressZeroable;
    use starknet::ContractAddress;
    // others
    use array::ArrayTrait;
    use option::OptionTrait;
    use traits::Into;
    use traits::TryInto;
    use zeroable::Zeroable;

    // -------------------------------------------------------------------------- //
    //                                   Storage                                  //
    // -------------------------------------------------------------------------- //
    struct Storage{
        _supply : u256,
        _index_to_tokens : LegacyMap::<u256,u256>,
        _tokens_to_index : LegacyMap::<u256,u256>,
        _owner_index_to_token : LegacyMap::<(ContractAddress, u256), u256>,
        _owner_token_to_index : LegacyMap::<u256,u256>,
    }
}
