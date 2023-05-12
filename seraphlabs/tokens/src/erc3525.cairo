// ----------------------------- library imports ---------------------------- //
mod interface;
mod utils;
use utils::{ApprovedUnits, ApprovedUnitsTrait, OperatorIndex, OperatorIndexTrait};
// ------------------------------ base library ------------------------------ //
//? assumes the use of ERC721Ennumerable
#[contract]
mod ERC3525 {
    // seraphlabs imports
    use seraphlabs_utils::constants;
    use seraphlabs_tokens::{
        ERC721, ERC721Enumerable as ERC721Enum, erc3525::{
        ApprovedUnits, ApprovedUnitsTrait, OperatorIndex, OperatorIndexTrait
        }
    };
    use super::interface;
    // corelib imports
    use starknet::{
        get_caller_address, contract_address_const, ContractAddress, ContractAddressIntoFelt252
    };
    use array::ArrayTrait;
    use option::OptionTrait;
    use traits::{Into, TryInto};
    use zeroable::Zeroable;
    use integer::BoundedInt;

    // -------------------------------------------------------------------------- //
    //                                   Storage                                  //
    // -------------------------------------------------------------------------- //
    struct Storage {
        decimals: u8,
        slot: LegacyMap::<u256, u256>,
        units: LegacyMap::<u256, u256>,
        // (token_id, index) -> (units, operator)
        unit_level_approvals: LegacyMap::<(u256, u16), ApprovedUnits>,
    }

    // -------------------------------------------------------------------------- //
    //                                   Events                                   //
    // -------------------------------------------------------------------------- //
    #[event]
    fn TransferValue(from_token_id: u256, to_token_id: u256, value: u256) {}

    #[event]
    fn ApprovalValue(token_id: u256, operator: ContractAddress, value: u256) {}

    #[event]
    fn SlotChanged(token_id: u256, old_slot: u256, new_slot: u256) {}

    // -------------------------------------------------------------------------- //
    //                                    Trait                                   //
    // -------------------------------------------------------------------------- //
    impl ERC3525Impl of interface::IERC3525 {
        fn value_decimals() -> u8 {
            decimals::read()
        }

        fn value_of(token_id: u256) -> u256 {
            units::read(token_id)
        }

        fn slot_of(token_id: u256) -> u256 {
            slot::read(token_id)
        }

        fn approve_value(token_id: u256, operator: ContractAddress, value: u256) {
            let caller = get_caller_address();
            assert(!caller.is_zero(), 'ERC3525: invalid caller');
            assert(!operator.is_zero(), 'ERC3525: invalid operator');
            let owner = ERC721::owner_of(token_id);
            // assert owner is not operator
            assert(owner != operator, 'ERC3525: approval to owner');
            // assert caller is approved or owner 
            assert(ERC721::_is_approved_or_owner(caller, token_id), 'ERC3525: caller not approved');
            _approve_value(token_id, operator, value);
        }

        fn allowance(token_id: u256, operator: ContractAddress) -> u256 {
            let index = _find_operator_index(token_id, operator);
            match index {
                OperatorIndex::Contain(x) => {
                    unit_level_approvals::read((token_id, x)).units
                },
                OperatorIndex::Empty(_) => {
                    BoundedInt::min()
                }
            }
        }

        fn transfer_value_from(from_token_id : u256, to : ContractAddress, value : u256) -> u256 {
            assert (value != 0.into(), 'ERC3525: invalid value');
            let token_id = _transfer_value_to_address(from_token_id, to, value);
            // TODO add check for ERC3525Received
            token_id
        }
    }

    // -------------------------------------------------------------------------- //
    //                               view functions                               //
    // -------------------------------------------------------------------------- //
    fn value_decimals() -> u8 {
        ERC3525Impl::value_decimals()
    }

    fn value_of(token_id: u256) -> u256 {
        ERC3525Impl::value_of(token_id)
    }

    fn slot_of(token_id: u256) -> u256 {
        ERC3525Impl::slot_of(token_id)
    }

    fn allowance(token_id: u256, operator: ContractAddress) -> u256 {
        ERC3525Impl::allowance(token_id, operator)
    }
    // -------------------------------------------------------------------------- //
    //                                  Externals                                 //
    // -------------------------------------------------------------------------- //

    fn approve_value(token_id: u256, operator: ContractAddress, value: u256) {
        ERC3525Impl::approve_value(token_id, operator, value)
    }

    fn transfer_value_from(from_token_id : u256, to : ContractAddress, value : u256) -> u256 {
        ERC3525Impl::transfer_value_from(from_token_id, to, value)
    }

    fn _mint(to : ContractAddress, token_id : u256, slot_id : u256, value : u256){
        // assert valid to address
        assert(!to.is_zero(), 'ERC3525: invalid to address');
        // assert token_id does not exist
        assert(!ERC721::_exist(token_id), 'ERC3525: token already exist');
        assert(token_id != 0.into(), 'ERC3525: invalid token_id');
        // mint token
        _mint_new(to, token_id, slot_id, value);
        //TODO add check for ERC3525Received
    }

    fn _mint_value(to_token_id : u256, value : u256){
        assert (ERC721::_exist(to_token_id), 'ERC3525: invalid tokenId');
        assert (value != 0.into(), 'ERC3525: invalid value');
        // increase to units
        units::write(to_token_id, units::read(to_token_id) + value);
        TransferValue(0.into(), to_token_id, value);
    }

    // -------------------------------------------------------------------------- //
    //                                  Internals                                 //
    // -------------------------------------------------------------------------- //
    fn _approve_value(token_id: u256, operator: ContractAddress, value: u256) {
        let index = _find_operator_index(token_id, operator).unwrap();
        unit_level_approvals::write((token_id, index), ApprovedUnitsTrait::new(value, operator));
        ApprovalValue(token_id, operator, value);
    }

    fn _spend_allownce(token_id: u256, operator: ContractAddress, value: u256) {
        //* does not check if operator is a zero address
        // method will revert if index returned is rom a empty slot, means operator not approved
        let index = _find_operator_index(
            token_id, operator
        ).expect_contains('ERC3525: operator not approved');
        let mut value_approvals = unit_level_approvals::read((token_id, index));
        // spend units , method alrady checks for value exceeding units
        value_approvals.spend_units(value);
        unit_level_approvals::write((token_id, index), value_approvals);
        //  emit event
        ApprovalValue(token_id, operator, value_approvals.units);
    }

    fn _transfer_value_to_address(from_token_id: u256, to: ContractAddress, value: u256) -> u256 {
        // assert valid to adderss
        assert(!to.is_zero(), 'ERC3525: invalid address');
        // find token_id with same slot to transfer if not generate new token_id and mint
        let token_id = match _find_same_slot_token_id(from_token_id, to) {
            Option::Some(x) => x,
            Option::None(_) => {
                let new_token_id = _generate_new_token_id();
                _mint_new(to, new_token_id, slot::read(from_token_id), 0.into());
                new_token_id
            },
        };
        _transfer_value(from_token_id, token_id, value);
        token_id
    }

    fn _transfer_value(from_token_id: u256, to_token_id: u256, value: u256) {
        // assert caller is valid
        let caller = get_caller_address();
        assert(!caller.is_zero(), 'ERC3525: invalid caller');
        // checks for tokenId level approval and above
        // if not there check for value level approval and spend allowance
        // functions already check if from_tokenId exist
        if !ERC721::_is_approved_or_owner(
            caller, from_token_id
        ) {
            _spend_allownce(from_token_id, caller, value);
        }
        // checks if to_token_id exist
        assert(ERC721::_exist(to_token_id), 'ERC3525: invalid tokenId');
        // assert from and to tokenIds are different
        assert(from_token_id != to_token_id, 'ERC3525: cant transfer self');
        // checks tokenIds have the same slot
        assert(slot::read(from_token_id) == slot::read(to_token_id), 'ERC3525: different slots');
        // asserts that value does not exceend balance
        let from_units = units::read(from_token_id);
        assert(from_units >= value, 'ERC3525: insufficient balance');
        // decrease from units and increase to units
        units::write(from_token_id, from_units - value);
        units::write(to_token_id, units::read(to_token_id) + value);
        // emit event
        TransferValue(from_token_id, to_token_id, value);
    }

    fn _mint_new(to : ContractAddress, token_id : u256, slot_id : u256, value : u256){
        //? internal mint function does not check for assertions or on ERC3525Received
        ERC721Enum::_mint(to, token_id);
        slot::write(token_id, slot_id);
        units::write(token_id, value);
        // emit event
        SlotChanged(token_id, 0.into(), slot_id);
        TransferValue(0.into(), token_id, value);
    }
    // -------------------------------------------------------------------------- //
    //                                   Private                                  //
    // -------------------------------------------------------------------------- //

    fn _find_operator_index(token_id: u256, operator: ContractAddress) -> OperatorIndex<u16> {
        let mut index: u16 = 0;
        // if operator found break else loop
        // until empty slot is found 
        let new_index = loop {
            let value_approvals = unit_level_approvals::read((token_id, index));
            if value_approvals.is_zero() {
                break OperatorIndex::Empty(index);
            } else if value_approvals.operator == operator {
                break OperatorIndex::Contain(index);
            }
            index += 1;
        };
        new_index
    }

    fn _find_same_slot_token_id(from_token_id: u256, to : ContractAddress) -> Option<u256>{
        let mut index = 0;
        let slot = slot::read(from_token_id);
        let found_token_id = loop{
            // use internal function so function wont revert on out of bounds index
            match ERC721Enum::_token_of_owner_by_index(to, index.into()) {
                Option::Some(x) => {
                    // if x == from_token_id or slot not the same  skip
                    // else break and return token_id
                    if x == from_token_id | slot::read(x) != slot {
                        index += 1;
                        continue;
                    } else{
                        break Option::Some(x);
                    }
                },
                Option::None(_) => {
                    // if None means end of token of owner array reached
                    break Option::None(());
                }
            };
        };
        found_token_id
    }

    fn _generate_new_token_id() -> u256{
        //? assumes next tokenId in supply does not exist
        // if not keep incrementing until tokenId does not exist
        let supply = ERC721Enum::total_supply();
        let mut new_token_id = supply + 1.into();
        loop {
            if !ERC721::_exist(new_token_id) {
                break ();
            }
            new_token_id += 1.into();
        };
        new_token_id
    }

    fn _check_on_erc3525_received(
        operator: ContractAddress,
        from_token_id: u256,
        to_token_id: u256,
        value: u256,
        data: Array<felt252>
    ) -> bool {
        //TODO finish function
        bool::True(())
    }
}

