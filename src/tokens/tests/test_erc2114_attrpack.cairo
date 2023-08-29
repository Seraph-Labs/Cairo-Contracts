use seraphlabs::tokens::erc2114::utils::AttrType;
use seraphlabs::tokens::erc2114::utils::{AttrBase, AttrBaseTrait};
use seraphlabs::tokens::erc2114::utils::{AttrPack, AttrPackTrait};
use seraphlabs::utils::testing::{vars, helper};
use starknet::storage_access::StorePacking;
use starknet::ContractAddress;
use starknet::testing::{set_caller_address, set_contract_address};
use traits::{Into, TryInto};
use option::OptionTrait;
use array::{ArrayTrait, SpanTrait};
use zeroable::Zeroable;
use integer::BoundedInt;
use serde::Serde;
use debug::{print, PrintTrait};

#[starknet::interface]
trait IMock<TContractState> {
    fn attrBase_to_storage(ref self: TContractState, index: u64, attr: AttrBase);
    fn value_to_storage(ref self: TContractState, index: u64, name: felt252, attr_type: AttrType);
    fn pack_to_storage(ref self: TContractState, index: u64, attr_ids: Span<u64>);
    fn get_attr_pack(self: @TContractState, index: u64) -> AttrPack;
}

#[starknet::contract]
mod Mock {
    use super::AttrType;
    use super::{AttrPack, AttrPackTrait};
    use super::{AttrBase, AttrBaseTrait};
    use super::StorePacking;
    use super::ContractAddress;
    use super::Zeroable;
    use super::IMock;
    use super::{ArrayTrait, SpanTrait};


    #[storage]
    struct Storage {
        attr_item: LegacyMap<u64, AttrBase>,
        packed_attr: LegacyMap<u64, AttrPack>,
        attr_name: LegacyMap<u64, felt252>,
        attr_type: LegacyMap<u64, AttrType>
    }

    #[external(v0)]
    impl IMockImpl of IMock<ContractState> {
        fn attrBase_to_storage(ref self: ContractState, index: u64, attr: AttrBase) {
            self.attr_item.write(index, attr);
        }

        fn value_to_storage(
            ref self: ContractState, index: u64, name: felt252, attr_type: AttrType
        ) {
            self.attr_name.write(index, name);
            self.attr_type.write(index, attr_type);
        }

        fn pack_to_storage(ref self: ContractState, index: u64, attr_ids: Span<u64>) {
            let mut attr_ids = attr_ids;
            let attr_pack = AttrPackTrait::new(attr_ids);
            self.packed_attr.write(index, attr_pack);
        }

        fn get_attr_pack(self: @ContractState, index: u64) -> AttrPack {
            self.packed_attr.read(index)
        }
    }
}

fn setup() -> ContractAddress {
    let mut calldata = ArrayTrait::new();
    helper::deploy(Mock::TEST_CLASS_HASH, calldata)
}

#[test]
#[available_gas(2000000)]
fn test_storing_3_attr_pack() {
    let mock_address = setup();
    let mock = IMockDispatcher { contract_address: mock_address };

    mock.pack_to_storage(1, array![10, BoundedInt::<u64>::max(), 2114].span());
    let attr_pack = mock.get_attr_pack(1);
    assert(attr_pack.len == 3, 'invalid len');
    assert(attr_pack.has_attr(2114), 'has attr failed');
    assert(attr_pack.get_attr_id(0) == 10, 'invalid attr at pos 0');
    assert(attr_pack.get_attr_id(1) == BoundedInt::max(), 'invalid attr at pos 1');
    assert(attr_pack.get_attr_id(2) == 2114, 'invalid attr at pos 2');

    let attr_ids = attr_pack.unpack_all();
    assert(attr_ids.len() == 3, 'invalid len');
    assert(*attr_ids.at(0) == 10, 'invalid attr at pos 0');
    assert(*attr_ids.at(1) == BoundedInt::<u64>::max(), 'invalid attr at pos 1');
    assert(*attr_ids.at(2) == 2114, 'invalid attr at pos 2');
}


#[test]
#[available_gas(2000000)]
fn test_storing_2_attr_pack() {
    let mock_address = setup();
    let mock = IMockDispatcher { contract_address: mock_address };

    mock.pack_to_storage(1, array![20, BoundedInt::<u64>::max()].span());
    let attr_pack = mock.get_attr_pack(1);
    assert(attr_pack.len == 2, 'invalid len');
    assert(attr_pack.has_attr(20), 'has attr failed');
    assert(attr_pack.get_attr_id(0) == 20, 'invalid attr at pos 0');
    assert(attr_pack.get_attr_id(1) == BoundedInt::max(), 'invalid attr at pos 1');

    let attr_ids = attr_pack.unpack_all();
    assert(attr_ids.len() == 2, 'invalid len');
    assert(*attr_ids.at(0) == 20, 'invalid attr at pos 0');
    assert(*attr_ids.at(1) == BoundedInt::<u64>::max(), 'invalid attr at pos 1');
}

#[test]
#[available_gas(2000000)]
fn test_storing_1_attr_pack() {
    let mock_address = setup();
    let mock = IMockDispatcher { contract_address: mock_address };

    mock.pack_to_storage(1, array![2114].span());
    let attr_pack = mock.get_attr_pack(1);
    assert(attr_pack.len == 1, 'invalid len');
    assert(attr_pack.has_attr(2114), 'has attr failed');
    assert(attr_pack.get_attr_id(0) == 2114, 'invalid attr at pos 0');

    let attr_ids = attr_pack.unpack_all();
    assert(attr_ids.len() == 1, 'invalid len');
    assert(*attr_ids.at(0) == 2114, 'invalid attr at pos 0');
}

#[test]
#[available_gas(2000000)]
fn test_storing_empty_attr_pack() {
    let mock_address = setup();
    let mock = IMockDispatcher { contract_address: mock_address };

    let attr_pack = mock.get_attr_pack(1);
    assert(attr_pack.len == 0, 'invalid len');
    assert(attr_pack.pack == 0, 'invalid pack');
}

#[test]
#[available_gas(2000000)]
fn test_remove_from_attr_pack() {
    let mock_address = setup();
    let mock = IMockDispatcher { contract_address: mock_address };

    mock.pack_to_storage(1, array![10, BoundedInt::<u64>::max(), 2114].span());
    let mut attr_pack = mock.get_attr_pack(1);
    assert(attr_pack.len == 3, 'invalid len');
    assert(attr_pack.get_attr_id(0) == 10, 'invalid attr at pos 0');
    assert(attr_pack.get_attr_id(1) == BoundedInt::max(), 'invalid attr at pos 1');
    assert(attr_pack.get_attr_id(2) == 2114, 'invalid attr at pos 2');

    attr_pack.remove_from_pack(BoundedInt::<u64>::max());
    assert(attr_pack.len == 2, 'invalid len');
    assert(attr_pack.get_attr_id(0) == 10, 'invalid attr at pos 0');
    assert(attr_pack.get_attr_id(1) == 2114, 'invalid attr at pos 1');

    attr_pack.remove_from_pack(10);
    assert(attr_pack.len == 1, 'invalid len');
    assert(attr_pack.get_attr_id(0) == 2114, 'invalid attr at pos 0');

    attr_pack.remove_from_pack(2114);
    assert(attr_pack.len == 0, 'invalid len');
    assert(attr_pack.pack == 0, 'invalid pack');
}

#[test]
#[available_gas(2000000)]
fn test_add_to_pack() {
    let mock_address = setup();
    let mock = IMockDispatcher { contract_address: mock_address };

    let mut attr_pack = mock.get_attr_pack(1);
    assert(attr_pack.len == 0, 'invalid len');
    assert(attr_pack.pack == 0, 'invalid pack');

    attr_pack.add_to_pack(2114);
    assert(attr_pack.len == 1, 'invalid len');
    assert(attr_pack.get_attr_id(0) == 2114, 'invalid attr at pos 0');

    attr_pack.add_to_pack(BoundedInt::<u64>::max());
    assert(attr_pack.len == 2, 'invalid len');
    assert(attr_pack.get_attr_id(0) == 2114, 'invalid attr at pos 0');
    assert(attr_pack.get_attr_id(1) == BoundedInt::max(), 'invalid attr at pos 1');

    attr_pack.add_to_pack(2000000);
    assert(attr_pack.len == 3, 'invalid len');
    assert(attr_pack.get_attr_id(0) == 2114, 'invalid attr at pos 0');
    assert(attr_pack.get_attr_id(1) == BoundedInt::max(), 'invalid attr at pos 1');
    assert(attr_pack.get_attr_id(2) == 2000000, 'invalid attr at pos 2');
}

#[test]
#[available_gas(2000000)]
fn test_add_batch_to_pack() {
    let mock_address = setup();
    let mock = IMockDispatcher { contract_address: mock_address };

    let mut attr_pack = mock.get_attr_pack(1);
    assert(attr_pack.len == 0, 'invalid len');
    assert(attr_pack.pack == 0, 'invalid pack');

    attr_pack.add_batch_to_pack(array![2114, BoundedInt::<u64>::max(), 2000000].span());
    assert(attr_pack.len == 3, 'invalid len');
    assert(attr_pack.get_attr_id(0) == 2114, 'invalid attr at pos 0');
    assert(attr_pack.get_attr_id(1) == BoundedInt::max(), 'invalid attr at pos 1');
    assert(attr_pack.get_attr_id(2) == 2000000, 'invalid attr at pos 2');
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC2114: AttrPack is full',))]
fn test_add_batch_to_pack_full() {
    let mut attr_pack = AttrPackTrait::new(array![2114].span());
    attr_pack.add_batch_to_pack(array![21142, BoundedInt::<u64>::max(), 2000000].span());
}
