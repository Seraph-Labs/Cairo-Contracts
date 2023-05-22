// ----------------------------- library imports ---------------------------- //
mod interface;

mod enumerable;
use enumerable::ERC721Enumerable;

mod metadata;
use metadata::ERC721Metadata;

// ------------------------------ base library ------------------------------ //
#[contract]
mod ERC721 {
    // seraphlabs imports
    use seraphlabs_tokens::utils::{constants, erc165::{ERC165, IERC165Dispatcher, IERC165DispatcherTrait}};
    use super::interface;
    use interface::{IERC721ReceiverDispatcher, IERC721ReceiverDispatcherTrait};
    // corelib imports
    use starknet::{
        get_caller_address, contract_address_const, ContractAddress, ContractAddressIntoFelt252
    };
    use array::ArrayTrait;
    use option::OptionTrait;
    use traits::{Into, TryInto};
    use zeroable::Zeroable;

    // -------------------------------------------------------------------------- //
    //                                   Storage                                  //
    // -------------------------------------------------------------------------- //
    struct Storage {
        _owners: LegacyMap::<u256, ContractAddress>,
        _balances: LegacyMap::<ContractAddress, u256>,
        _token_approvals: LegacyMap::<u256, ContractAddress>,
        _operator_approvals: LegacyMap::<(ContractAddress, ContractAddress), bool>,
    }

    // -------------------------------------------------------------------------- //
    //                                   Events                                   //
    // -------------------------------------------------------------------------- //
    #[event]
    fn Transfer(from: ContractAddress, to: ContractAddress, token_id: u256) {}

    #[event]
    fn Approval(owner: ContractAddress, approved: ContractAddress, token_id: u256) {}

    #[event]
    fn ApprovalForAll(owner: ContractAddress, operator: ContractAddress, approved: bool) {}

    // -------------------------------------------------------------------------- //
    //                                    Trait                                   //
    // -------------------------------------------------------------------------- //
    impl ERC721 of interface::IERC721 {
        fn balance_of(owner: ContractAddress) -> u256 {
            _balances::read(owner)
        }

        fn owner_of(token_id: u256) -> ContractAddress {
            _owner_of(token_id).expect('ERC721: invalid tokenId')
        }

        fn get_approved(token_id: u256) -> ContractAddress {
            assert(_exist(token_id), 'ERC721: tokenId does not exist');
            _token_approvals::read(token_id)
        }

        fn is_approved_for_all(owner: ContractAddress, operator: ContractAddress) -> bool {
            _operator_approvals::read((owner, operator))
        }

        fn approve(approved: ContractAddress, token_id: u256) {
            let owner: ContractAddress = _owner_of(token_id).expect('ERC721: invalid tokenId');
            let caller: ContractAddress = get_caller_address();
            assert(caller == owner, 'ERC721: invalid owner');
            _approve(approved, token_id);
        }

        fn set_approval_for_all(operator: ContractAddress, approved: bool) {
            _set_approval_for_all(operator, approved);
        }

        fn safe_transfer_from(
            from: ContractAddress, to: ContractAddress, token_id: u256, data: Array::<felt252>
        ) {
            let caller: ContractAddress = get_caller_address();
            assert(_is_approved_or_owner(caller, token_id), 'ERC721: caller is not approved');
            _safe_transfer(from, to, token_id, data);
        }

        fn transfer_from(from: ContractAddress, to: ContractAddress, token_id: u256) {
            let caller: ContractAddress = get_caller_address();
            assert(_is_approved_or_owner(caller, token_id), 'ERC721: caller is not approved');
            _transfer(from, to, token_id);
        }
    }
    // -------------------------------------------------------------------------- //
    //                               view functions                               //
    // -------------------------------------------------------------------------- //
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
    //                                  externals                                 //
    // -------------------------------------------------------------------------- //
    #[external]
    fn initializer() { 
        ERC165::register_interface(constants::IERC721_ID);
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
        from: ContractAddress, to: ContractAddress, token_id: u256, data: Array<felt252>
    ) {
        ERC721::safe_transfer_from(from, to, token_id, data)
    }

    #[external]
    fn transfer_from(from: ContractAddress, to: ContractAddress, token_id: u256) {
        ERC721::transfer_from(from, to, token_id)
    }

    // -------------------------------------------------------------------------- //
    //                                  Internals                                 //
    // -------------------------------------------------------------------------- //

    fn _exist(token_id: u256) -> bool {
        let owner: ContractAddress = _owners::read(token_id);
        !owner.is_zero()
    }

    fn _owner_of(token_id: u256) -> Option<ContractAddress> {
        let owner: ContractAddress = _owners::read(token_id);
        match owner.is_zero() {
            bool::False(()) => Option::Some(owner),
            bool::True(()) => Option::None(()),
        }
    }

    fn _is_approved_or_owner(spender: ContractAddress, token_id: u256) -> bool {
        let owner: ContractAddress = _owner_of(token_id).expect('ERC721: invalid tokenId');
        owner == spender | spender == _token_approvals::read(
            token_id
        ) | _operator_approvals::read((owner, spender))
    }

    fn _transfer(from: ContractAddress, to: ContractAddress, token_id: u256) {
        // ensures tokenId has owner
        let owner: ContractAddress = _owner_of(token_id).expect('ERC721: invalid tokenId');
        // ensures owner == from
        assert(owner == from, 'ERC721: invalid sender');
        // ensures to is not a zero address
        assert(!to.is_zero(), 'ERC721: invalid address');

        // clear approvals
        _token_approvals::write(token_id, Zeroable::zero());

        // update balances
        _balances::write(to, _balances::read(to) + 1.into());
        _balances::write(from, _balances::read(from) - 1.into());

        // update owner
        _owners::write(token_id, to);

        // emit event
        Transfer(from, to, token_id);
    }

    fn _safe_transfer(
        from: ContractAddress, to: ContractAddress, token_id: u256, data: Array<felt252>
    ) {
        _transfer(from, to, token_id);
        assert(_check_on_erc721_received(from, to, token_id, data), 'ERC721: reciever failed');
    }

    fn _approve(to: ContractAddress, token_id: u256) {
        let owner: ContractAddress = _owner_of(token_id).expect('ERC721: invalid tokenId');
        assert(owner != to, 'ERC721: owner cant approve self');
        _token_approvals::write(token_id, to);
        Approval(owner, to, token_id);
    }

    fn _set_approval_for_all(operator: ContractAddress, approved: bool) {
        assert(!operator.is_zero(), 'ERC721: invalid address');

        let caller: ContractAddress = get_caller_address();
        assert(!caller.is_zero(), 'ERC721: invalid address');
        
        assert(caller != operator, 'ERC721: owner cant approve self');

        _operator_approvals::write((caller, operator), approved);
        ApprovalForAll(caller, operator, approved);
    }

    fn _mint(to: ContractAddress, token_id: u256) {
        assert(!to.is_zero(), 'ERC721: invalid address');
        assert(!_exist(token_id), 'ERC721: tokenId already exist');

        // update balances
        _balances::write(to, _balances::read(to) + 1.into());
        // update owner
        _owners::write(token_id, to);
        // emit event
        Transfer(Zeroable::zero(), to, token_id);
    }

    fn _safe_mint(to: ContractAddress, token_id: u256, data: Array<felt252>) {
        _mint(to, token_id);
        assert(
            _check_on_erc721_received(Zeroable::zero(), to, token_id, data),
            'ERC721: reciever failed'
        );
    }

    fn _burn(token_id: u256) {
        // ensures tokenId has owner
        let owner: ContractAddress = _owner_of(token_id).expect('ERC721: invalid tokenId');

        // clear approvals
        _token_approvals::write(token_id, Zeroable::zero());

        // update balances
        _balances::write(owner, _balances::read(owner) - 1.into());

        // update owner
        _owners::write(token_id, Zeroable::zero());

        // emit event
        Transfer(owner, Zeroable::zero(), token_id);
    }

    // -------------------------------------------------------------------------- //
    //                                   private                                  //
    // -------------------------------------------------------------------------- //
    fn _check_on_erc721_received(
        from: ContractAddress, to: ContractAddress, token_id: u256, data: Array<felt252>
    ) -> bool {
        let support_interface = IERC165Dispatcher{contract_address: to}.supports_interface(constants::IERC721_RECEIVER_ID);
        match support_interface{
            bool::False(()) => IERC165Dispatcher { contract_address: to }.supports_interface(constants::IACCOUNT_ID),
            bool::True(()) => {
                IERC721ReceiverDispatcher {
                    contract_address: to
                }.on_erc721_received(
                    get_caller_address(), from, token_id, data
                ) == constants::IERC721_RECEIVER_ID
            },
        }
    }
}
