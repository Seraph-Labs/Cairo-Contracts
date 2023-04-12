// ----------------------------- library imports ---------------------------- //
mod interface;
mod enumerable;

// ------------------------------ base library ------------------------------ //
#[contract]
mod ERC721{
    // seraphlabs imports
    use seraphlabs_utils::constants;
    use super::interface;
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
    impl ERC721Metadata of interface::IERC721MetaData{
        fn name() -> felt252{
            _name::read()
        }

        fn symbol() -> felt252{
            _symbol::read()
        }
    }

    impl ERC721 of interface::IERC721{

        fn balance_of(owner : ContractAddress) -> u256{
            _balances::read(owner)
        }

        fn owner_of(tokenId : u256) -> ContractAddress{
            _owner_of(tokenId).expect('ERC721: invalid tokenId')
        }

        fn get_approved(tokenId : u256) -> ContractAddress{
            assert(_exist(tokenId),'ERC721: tokenId does not exist');
            _token_approvals::read(tokenId)
        }

        fn is_approved_for_all(owner : ContractAddress, operator : ContractAddress) -> bool{
            _operator_approvals::read((owner,operator))
        }

        fn approve(approved : ContractAddress, tokenId : u256){
            let owner : ContractAddress = _owner_of(tokenId).expect('ERC721: invalid tokenId');
            let caller : ContractAddress = get_caller_address();
            assert(caller == owner, 'ERC721: invalid owner');
            _approve(approved,tokenId);
        }

        fn set_approval_for_all(operator : ContractAddress, approved : bool){
            _set_approval_for_all(operator,approved);
        }

        fn safe_transfer_from(from : ContractAddress, to : ContractAddress, tokenId : u256, data : Array::<felt252>){
            let caller : ContractAddress = get_caller_address();
            assert(_is_approved_or_owner(caller, tokenId), 'ERC721: caller is not approved');
            _safe_transfer(from,to,tokenId,data);
        }

        fn transfer_from(from : ContractAddress, to : ContractAddress, tokenId : u256){
            let caller : ContractAddress = get_caller_address();
            assert(_is_approved_or_owner(caller, tokenId), 'ERC721: caller is not approved');
            _transfer(from, to, tokenId);
        }
    }
    // -------------------------------------------------------------------------- //
    //                               view functions                               //
    // -------------------------------------------------------------------------- //
    #[view]
    fn name() -> felt252{
        ERC721Metadata::name()
    }

    #[view]
    fn symbol() -> felt252{
        ERC721Metadata::symbol()
    }

    #[view]
    fn balance_of(owner: ContractAddress) -> u256 {
        ERC721::balance_of(owner)
    }

    #[view]
    fn owner_of(tokenId: u256) -> ContractAddress {
        ERC721::owner_of(tokenId)
    }

    #[view]
    fn get_approved(tokenId: u256) -> ContractAddress {
        ERC721::get_approved(tokenId)
    }

    #[view]
    fn is_approved_for_all(owner: ContractAddress, operator: ContractAddress) -> bool {
        ERC721::is_approved_for_all(owner, operator)
    }
    // -------------------------------------------------------------------------- //
    //                                  externals                                 //
    // -------------------------------------------------------------------------- //
    #[external]
    fn approve(to: ContractAddress, tokenId: u256) {
        ERC721::approve(to, tokenId)
    }

    #[external]
    fn set_approval_for_all(operator: ContractAddress, approved: bool) {
        ERC721::set_approval_for_all(operator, approved)
    }

    #[external]
    fn safe_transfer_from(
        from: ContractAddress, to: ContractAddress, tokenId: u256, data: Array<felt252>
    ) {
        ERC721::safe_transfer_from(from, to, tokenId, data)
    }

    #[external]
    fn transfer_from(from: ContractAddress, to: ContractAddress, tokenId: u256) {
        ERC721::transfer_from(from, to, tokenId)
    }

    // -------------------------------------------------------------------------- //
    //                                  Internals                                 //
    // -------------------------------------------------------------------------- //
    fn initializer(name : felt252, symbol : felt252){
        _name::write(name);
        _symbol::write(symbol);
        //TODO add erc165 functions
    }

    fn _exist(tokenId : u256) -> bool{
        let owner : ContractAddress = _owners::read(tokenId);
        !owner.is_zero()
    }

    fn _owner_of(tokenId : u256) -> Option<ContractAddress>{
        let owner : ContractAddress = _owners::read(tokenId);
        match owner.is_zero(){
            bool::False(()) => Option::Some(owner),
            bool::True(()) => Option::None(()),
        }
    }

    fn _is_approved_or_owner(spender : ContractAddress, tokenId : u256) -> bool{
        let owner : ContractAddress = _owner_of(tokenId).expect('ERC721: invalid tokenId');
        owner == spender | spender == _token_approvals::read(tokenId) | _operator_approvals::read((owner,spender))
    }

    fn _transfer(from : ContractAddress, to : ContractAddress, tokenId : u256){
        // ensures tokenId has owner
        let owner : ContractAddress = _owner_of(tokenId).expect('ERC721: invalid tokenId');
        // ensures owner == from
        assert(owner == from, 'ERC721: invalid sender');
        // ensures to is not a zero address
        assert(!to.is_zero(), 'ERC721: invalid address');

        // clear approvals
        _token_approvals::write(tokenId, Zeroable::zero());

        // update balances
        _balances::write(to, _balances::read(to) + 1_u256);
        _balances::write(from, _balances::read(from) - 1_u256);

        // update owner
        _owners::write(tokenId, to);

        // emit event
        Transfer(from, to, tokenId);
    }

    fn _safe_transfer(from : ContractAddress, to : ContractAddress, tokenId : u256, data : Array<felt252>){
        _transfer(from, to, tokenId);
        assert(_check_on_erc721_received(from, to, tokenId, data), 'ERC721: reciever failed');
    }

    fn _approve(to: ContractAddress, tokenId : u256){
        let owner : ContractAddress = _owner_of(tokenId).expect('ERC721: invalid tokenId');
        assert(owner != to, 'ERC721: owner cant approve self');
        _token_approvals::write(tokenId, to);
        Approval(owner, to, tokenId);
    }

    fn _set_approval_for_all(operator : ContractAddress, approved : bool){
        assert(!operator.is_zero(), 'ERC721: invalid address');

        let caller : ContractAddress = get_caller_address();
        assert(caller != operator, 'ERC721: owner cant approve self');

        _operator_approvals::write((caller,operator),approved);
        ApprovalForAll(caller, operator, approved); 
    }

    fn _mint(to : ContractAddress, tokenId : u256){
        assert(!to.is_zero(), 'ERC721: invalid address');
        assert(!_exist(tokenId),'ERC721: tokenId already exist');

        // update balances
        _balances::write(to, _balances::read(to) + 1_u256);
        // update owner
        _owners::write(tokenId, to);
        // emit event
        Transfer(Zeroable::zero(), to, tokenId);
    }

    fn _safe_mint(to : ContractAddress, tokenId : u256, data : Array<felt252>){
        _mint(to, tokenId);
        assert(_check_on_erc721_received(Zeroable::zero(), to, tokenId, data), 'ERC721: reciever failed');
    }

    fn _burn(tokenId : u256){
        // ensures tokenId has owner
        let owner : ContractAddress = _owner_of(tokenId).expect('ERC721: invalid tokenId');

        // clear approvals
        _token_approvals::write(tokenId, Zeroable::zero());

        // update balances
        _balances::write(owner, _balances::read(owner) - 1_u256);

        // update owner
        _owners::write(tokenId, Zeroable::zero());

        // emit event
        Transfer(owner, Zeroable::zero(), tokenId);
    }
    
    //TODO: implemet token_uri function
    // -------------------------------------------------------------------------- //
    //                                   private                                  //
    // -------------------------------------------------------------------------- //
    fn _check_on_erc721_received(
        from: ContractAddress, to: ContractAddress, tokenId: u256, data: Array<felt252>
    ) -> bool {
        //TODO finish function
        bool::True(())
    } 
}