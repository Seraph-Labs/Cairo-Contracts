// ----------------------------- library imports ---------------------------- //
use super::ERC721;
use super::interface;

// fn main(){
//     let x = ERC721Impl::transfer_from();
// }

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
    // corelib
    use array::ArrayTrait;
    use option::OptionTrait;
    use traits::Into;
    use traits::TryInto;
    use zeroable::Zeroable;
    use integer::BoundedInt;

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

    impl ERC721Enumerable of IERC721Enumerable{
        #[inline(always)]
        fn total_supply() -> u256{
            _supply::read()
        }
        
        #[inline(always)]
        fn token_by_index(index : u256) -> u256{
            // assert index is not out of bounds
            let supply = _supply::read();
            assert(index < supply, 'ERC721Enum: index out of bounds');
            _index_to_tokens::read(index)
        }

        #[inline(always)]
        fn token_of_owner_by_index(owner : ContractAddress, index : u256) -> u256{
            // assert owner index is not out of bounds
            let balance = ERC721::balance_of(owner);
            assert(index < balance,'ERC721Enum: index out of bounds');
            _owner_index_to_token::read((owner,index))
        }
    }

    // -------------------------------------------------------------------------- //
    //                               view functions                               //
    // -------------------------------------------------------------------------- //
    #[view]
    fn total_supply() -> u256{
        ERC721Enumerable::total_supply()
    }

    #[view]
    fn token_by_index(index : u256) -> u256{
        ERC721Enumerable::token_by_index(index)
    }

    #[view]
    fn token_of_owner_by_index(owner : ContractAddress, index : u256) -> u256{
        ERC721Enumerable::token_of_owner_by_index(owner, index)
    }

    // -------------------------------------------------------------------------- //
    //                                  externals                                 //
    // -------------------------------------------------------------------------- //

    fn transfer_from(from : ContractAddress, to : ContractAddress, tokenId : u256){
        _remove_token_from_owner_enum(from,tokenId);
        _add_token_to_owner_enum(to,tokenId);
        ERC721::transfer_from(from,to,tokenId);
    }

    fn safe_transfer_from(
        from: ContractAddress, to: ContractAddress, tokenId: u256, data: Array<felt252>
    ) {
        _remove_token_from_owner_enum(from,tokenId);
        _add_token_to_owner_enum(to,tokenId);
        ERC721::safe_transfer_from(from, to, tokenId, data)
    }

    // -------------------------------------------------------------------------- //
    //                                  internals                                 //
    // -------------------------------------------------------------------------- //

    fn _mint(to : ContractAddress, tokenId : u256){
        _add_token_to_owner_enum(to,tokenId);
        _add_token_to_total_enum(tokenId);
        ERC721::_mint(to, tokenId);
    }

    fn _burn(tokenId : u256){
        let owner = ERC721::owner_of(tokenId);
        _remove_token_from_owner_enum(owner, tokenId);
        _remove_token_from_total_enum(tokenId);
        // set owners tokenId index to zero
        _owner_token_to_index::write(tokenId, BoundedInt::min());
        ERC721::_burn(tokenId);
    }

    // -------------------------------------------------------------------------- //
    //                                   private                                  //
    // -------------------------------------------------------------------------- //
    fn _add_token_to_total_enum(tokenId : u256){
        let supply = _supply::read();
        // add tokenId to totals last index
        _index_to_tokens::write(supply,tokenId);
        // add last index to tokenId
        _tokens_to_index::write(tokenId,supply);
        // add to new_supply
        _supply::write(supply + 1.into());
    }

    fn _remove_token_from_total_enum(tokenId : u256){
        // index starts from zero therefore minus 1
        let last_token_index = _supply::read() - 1.into();
        let cur_token_index = _tokens_to_index::read(tokenId);

        if last_token_index != cur_token_index{
            // set last token Id to cur token index
            let last_tokenId = _index_to_tokens::read(last_token_index);
            _index_to_tokens::write(cur_token_index, last_tokenId);
            // set cur token index to last tokenId
            _tokens_to_index::write(last_tokenId, cur_token_index);
        }

        // set token at last index to zero
        _index_to_tokens::write(last_token_index,BoundedInt::min());
        // set tokenId index to zero
        _tokens_to_index::write(tokenId, BoundedInt::min());
        // remove 1 from supply
        _supply::write(last_token_index);
    }

    fn _add_token_to_owner_enum(owner : ContractAddress, tokenId : u256){
        let len = ERC721::balance_of(owner);
        // set tokenId to owners last index
        _owner_index_to_token::write((owner, len), tokenId);
        // set index to owners tokenId
        _owner_token_to_index::write(tokenId,len);
    }

    fn _remove_token_from_owner_enum(owner : ContractAddress, tokenId : u256){
        // index starts from zero therefore minus 1
        let last_token_index  = ERC721::balance_of(owner) - 1.into();
        let cur_token_index = _owner_token_to_index::read(tokenId);

        if last_token_index != cur_token_index {
            // set last token Id to cur token index
            let last_tokenId = _owner_index_to_token::read((owner, last_token_index));
            _owner_index_to_token::write((owner,cur_token_index),last_tokenId);
            // set cur token index to last tokenId
            _owner_token_to_index::write(last_tokenId, cur_token_index);
        }
        // set token at owners last index to zero
        _owner_index_to_token::write((owner,last_token_index),BoundedInt::min());
    }
    
    
}
