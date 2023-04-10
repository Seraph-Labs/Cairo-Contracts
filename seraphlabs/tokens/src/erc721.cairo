use starknet::ContractAddress;
use array::ArrayTrait;

#[abi]
trait IERC721{
    fn balance_of(owner : ContractAddress) -> u256;
    fn owner_of(tokenId : u256) -> ContractAddress;
    fn get_approved(tokenId : u256) -> ContractAddress;
    fn is_approved_for_all(owner : ContractAddress, operator : ContractAddress) -> bool;
    fn safe_transfer_from(from : ContractAddress, to : ContractAddress, tokenId : u256, data: Array::<felt252>);
    fn transfer_from(from : ContractAddress, to : ContractAddress, tokenId: u256);
    fn approve(approved : ContractAddress, tokenId : u256);
    fn set_approval_for_all(operator : ContractAddress, approved : bool);
}

#[abi]
trait IERC721MetaData{
    fn name() -> felt252;
    fn symbol() -> felt252;
    //! implement tokenuri function
}


#[contract]
mod ERC721{
    // seraphlabs imports
    use seraphlabs_tokens::erc721;

    // imports
    use starknet::get_caller_address;
    use starknet::contract_address_const;
    use starknet::ContractAddressIntoFelt252;
    use starknet::ContractAddressZeroable;
    use super::ContractAddress;
    use super::ArrayTrait;
    use option::OptionTrait;
    use traits::Into;
    use traits::TryInto;
    use zeroable::Zeroable;

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
    impl ERC721 of erc721::IERC721MetaData{
        fn name() -> felt252{
            _name::read()
        }

        fn symbol() -> felt252{
            _symbol::read()
        }
    }

    impl ERC721 of erc721::IERC721{

        fn balance_of(owner : ContractAddress) -> u256{
            _balances::read(owner)
        }

        fn owner_of(tokenId : u256) -> ContractAddress{
            _owner_of(tokenId).expect('ERC721: invalid tokenId')
        }

        fn get_approved(tokenId : u256) -> ContractAddress{
            _assert_exist(tokenId);
            _token_approvals::read(tokenId)
        }

        fn is_approved_for_all(owner : ContractAddress, operator : ContractAddress) -> bool{
            _operator_approvals::read((owner,operator))
        }

        fn safe_transfer_from(from : ContractAddress, to : ContractAddress, tokenId : u256, data : Array::<felt252>){
            let caller : ContractAddress = get_caller_address();
            assert(_is_approved_or_owner(caller, tokenId), 'ERC721: caller is not approved');

        }

    }
    // -------------------------------------------------------------------------- //
    //                                  Internals                                 //
    // -------------------------------------------------------------------------- //

    fn _assert_exist(tokenId : u256){
        let owner : ContractAddress = _owners::read(tokenId);
        assert(!owner.is_zero(), 'ERC721: tokenId does not exist');
    }

    fn _owner_of(tokenId : u256) -> Option<ContractAddress>{
        let owner : ContractAddress = _owners::read(tokenId);
        match owner.is_zero(){
            bool::False(()) => Option::Some(Owner),
            bool::True(()) => Option::None(()),
        }
    }

    fn _is_approved_or_owner(spender : ContractAddress, tokenId : u256) -> bool{
        let owner : ContractAddress = _owner_of(tokenId).expect('ERC721: invalid tokenId');
        owner == spender | spender == _token_approvals::read(tokenId) | _operator_approvals::read((owner,spender))
    }

    
    fn _transfer(from : ContractAddress, to : ContractAddress, tokenId : u256){
        let owner : ContractAddress = _owner_of(tokenId).expect('ERC721: invalid tokenId');
        assert(owner == from, 'ERC721: invalid sender');
        assert(!to.is_zero(), 'ERC721: invalid to address');

        // clear approvals
        _token_approvals::write(tokenId, Zeroable::zero());

        // update balances
        _balances::write(to, _balances::read(to) - 1_u256);
        _balances::write(from, _balances::read(from) + 1_u256);

        // update owner
        _owners::write(tokenId, to);

        // emit event
        Transfer(from, to, tokenId);
    }
}