#[contract]
mod ERC721{
    use starknet::get_caller_address;
    use starknet::contract_address_const;
    use starknet::ContractAddress;
    use traits::Into;
    use traits::TryInto;
    use array::ArrayTrait;
    use zeroable::Zeroable;
    use starknet::ContractAddressIntoFelt252;
    use starknet::ContractAddressZeroable;
    use seraphlabs::tokens::EIP721::interfaces::IERC721;

    // -------------------------------------------------------------------------- //
    //                                   Storage                                  //
    // -------------------------------------------------------------------------- //
    struct Storage{
        _name : felt252,
        _symbol : felt252,
        _owners : LegacyMap::<u256, ContractAddress>,
        _balances : LegacyMap::<ContractAddress, u256>,
        _token_approvals : LegacyMap::<u256, ContractAddress>,
        _operator_approvals : LegacyMap::<(ContractAddress,ContractAddress), bool>,
    }

    // -------------------------------------------------------------------------- //
    //                                   Events                                   //
    // -------------------------------------------------------------------------- //
    #[event]
    fn Transfer(from : ContractAddress, to : ContractAddress, tokenId : u256){}

    #[event]
    fn Approval(owner : ContractAddress, approved : ContractAddress, tokenId : u256){}

    #[event]
    fn ApprovalForAll(owner : ContractAddress, operator : ContractAddress, approved : bool){}

    // -------------------------------------------------------------------------- //
    //                                    Trait                                   //
    // -------------------------------------------------------------------------- //
    impl ERC721 of IERC721{
        fn name() -> felt252{
            _name::read()
        }

        fn symbol() -> felt252{
            _symbol::read()
        }

        fn balance_of(owner : ContractAddress) -> u256{
            assert(!owner.is_zero(), 'ERC721: invalid address');
            _balances::read(owner)
        }

        fn owner_of(tokenId : u256) -> ContractAddress{
            _owner_of(tokenId)
        }

    }
    // -------------------------------------------------------------------------- //
    //                                  Internals                                 //
    // -------------------------------------------------------------------------- //
    fn _owner_of(tokenId : u256) -> ContractAddress{
        let owner : ContractAddress = _owners::read(tokenId);
        assert(!owner.is_zero(), 'ERC721: invalid tokenId');
        owner
    }

}