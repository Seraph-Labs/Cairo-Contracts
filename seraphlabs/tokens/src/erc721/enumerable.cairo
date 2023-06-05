#[contract]
mod ERC721Enumerable {
    // seraphlabs imports
    use seraphlabs_tokens::erc721::{ERC721, interface::IERC721Enumerable};
    use seraphlabs_tokens::utils::{constants, erc165::ERC165};
    // corelib imports
    use starknet::ContractAddress;
    use option::OptionTrait;
    use traits::{TryInto, Into};
    use integer::BoundedInt;

    // -------------------------------------------------------------------------- //
    //                                   Storage                                  //
    // -------------------------------------------------------------------------- //
    struct Storage {
        _supply: u256,
        _index_to_tokens: LegacyMap::<u256, u256>,
        _tokens_to_index: LegacyMap::<u256, u256>,
        _owner_index_to_token: LegacyMap::<(ContractAddress, u256), u256>,
        _owner_token_to_index: LegacyMap::<u256, u256>,
    }

    impl ERC721Enumerable of IERC721Enumerable {
        #[inline(always)]
        fn total_supply() -> u256 {
            _supply::read()
        }

        #[inline(always)]
        fn token_by_index(index: u256) -> u256 {
            // assert index is not out of bounds
            let supply = _supply::read();
            assert(index < supply, 'ERC721Enum: index out of bounds');
            _index_to_tokens::read(index)
        }

        #[inline(always)]
        fn token_of_owner_by_index(owner: ContractAddress, index: u256) -> u256 {
            _token_of_owner_by_index(owner, index).expect('ERC721Enum: index out of bounds')
        }
    }

    // -------------------------------------------------------------------------- //
    //                               view functions                               //
    // -------------------------------------------------------------------------- //
    #[view]
    fn total_supply() -> u256 {
        ERC721Enumerable::total_supply()
    }

    #[view]
    fn token_by_index(index: u256) -> u256 {
        ERC721Enumerable::token_by_index(index)
    }

    #[view]
    fn token_of_owner_by_index(owner: ContractAddress, index: u256) -> u256 {
        ERC721Enumerable::token_of_owner_by_index(owner, index)
    }

    // -------------------------------------------------------------------------- //
    //                                  externals                                 //
    // -------------------------------------------------------------------------- //
    #[external]
    fn transfer_from(from: ContractAddress, to: ContractAddress, token_id: u256) {
        _remove_token_from_owner_enum(from, token_id);
        _add_token_to_owner_enum(to, token_id);
        ERC721::transfer_from(from, to, token_id);
    }

    #[external]
    fn safe_transfer_from(
        from: ContractAddress, to: ContractAddress, token_id: u256, data: Array<felt252>
    ) {
        _remove_token_from_owner_enum(from, token_id);
        _add_token_to_owner_enum(to, token_id);
        ERC721::safe_transfer_from(from, to, token_id, data)
    }

    // -------------------------------------------------------------------------- //
    //                                  internals                                 //
    // -------------------------------------------------------------------------- //
    #[internal]
    fn initializer() { 
        ERC165::register_interface(constants::IERC721_ENUMERABLE_ID);
    }

    #[internal]
    fn _mint(to: ContractAddress, token_id: u256) {
        _add_token_to_owner_enum(to, token_id);
        _add_token_to_total_enum(token_id);
        ERC721::_mint(to, token_id);
    }

    #[internal]
    fn _safe_mint(to: ContractAddress, token_id: u256, data: Array<felt252>){
        _add_token_to_owner_enum(to, token_id);
        _add_token_to_total_enum(token_id);
        ERC721::_safe_mint(to, token_id, data);
    }

    #[internal]
    fn _burn(token_id: u256) {
        let owner = ERC721::owner_of(token_id);
        _remove_token_from_owner_enum(owner, token_id);
        _remove_token_from_total_enum(token_id);
        // set owners token_id index to zero
        _owner_token_to_index::write(token_id, BoundedInt::min());
        ERC721::_burn(token_id);
    }

    #[internal]
    fn _token_of_owner_by_index(owner: ContractAddress, index: u256) -> Option<u256> {
        let token_id = _owner_index_to_token::read((owner, index));
        match token_id == BoundedInt::min() {
            bool::False(()) => Option::Some(token_id),
            bool::True(()) => Option::None(()),
        }
    }
    // -------------------------------------------------------------------------- //
    //                                   private                                  //
    // -------------------------------------------------------------------------- //

    #[private]
    fn _add_token_to_total_enum(token_id: u256) {
        let supply = _supply::read();
        // add token_id to totals last index
        _index_to_tokens::write(supply, token_id);
        // add last index to token_id
        _tokens_to_index::write(token_id, supply);
        // add to new_supply
        _supply::write(supply + 1.into());
    }

    #[private]
    fn _remove_token_from_total_enum(token_id: u256) {
        // index starts from zero therefore minus 1
        let last_token_index = _supply::read() - 1.into();
        let cur_token_index = _tokens_to_index::read(token_id);

        if last_token_index != cur_token_index {
            // set last token Id to cur token index
            let last_tokenId = _index_to_tokens::read(last_token_index);
            _index_to_tokens::write(cur_token_index, last_tokenId);
            // set cur token index to last token_id
            _tokens_to_index::write(last_tokenId, cur_token_index);
        }

        // set token at last index to zero
        _index_to_tokens::write(last_token_index, BoundedInt::min());
        // set token_id index to zero
        _tokens_to_index::write(token_id, BoundedInt::min());
        // remove 1 from supply
        _supply::write(last_token_index);
    }

    #[private]
    fn _add_token_to_owner_enum(owner: ContractAddress, token_id: u256) {
        let len = ERC721::balance_of(owner);
        // set token_id to owners last index
        _owner_index_to_token::write((owner, len), token_id);
        // set index to owners token_id
        _owner_token_to_index::write(token_id, len);
    }

    #[private]
    fn _remove_token_from_owner_enum(owner: ContractAddress, token_id: u256) {
        // index starts from zero therefore minus 1
        let last_token_index = ERC721::balance_of(owner) - 1.into();
        let cur_token_index = _owner_token_to_index::read(token_id);

        if last_token_index != cur_token_index {
            // set last token Id to cur token index
            let last_tokenId = _owner_index_to_token::read((owner, last_token_index));
            _owner_index_to_token::write((owner, cur_token_index), last_tokenId);
            // set cur token index to last token_id
            _owner_token_to_index::write(last_tokenId, cur_token_index);
        }
        // set token at owners last index to zero
        _owner_index_to_token::write((owner, last_token_index), BoundedInt::min());
    }
}
