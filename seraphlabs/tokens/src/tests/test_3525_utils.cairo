use starknet::ContractAddress;
use zeroable::Zeroable;
use integer::BoundedInt;
use option::OptionTrait;
use traits::{Into, TryInto};
use seraphlabs_tokens::erc3525::utils::{ApprovedUnits, ApprovedUnitsTrait};

#[contract]
mod ApproveUnitsTest {
    use super::ContractAddress;
    use super::{ApprovedUnits, ApprovedUnitsTrait};

    struct Storage {
        approved_units: LegacyMap::<u128, ApprovedUnits>, 
    }

    #[view]
    fn get_approved_units(index: u128) -> ApprovedUnits {
        approved_units::read(index)
    }

    #[external]
    fn approve_units(index: u128, units: u256, operator: ContractAddress) {
        approved_units::write(index, ApprovedUnitsTrait::new(units, operator));
    }
}

#[test]
#[available_gas(2000000)]
fn test_approve_units_storage() {
    let data = ApproveUnitsTest::get_approved_units(1_u128);
    assert(data.units == BoundedInt::<u256>::min(), 'units should be 0');
    assert(data.operator == Zeroable::zero(), 'operator should be 0');

    let units: u256 = 10.into();
    let operator: ContractAddress =
        0x066b6f9b1da6cfdaf09a5456ab8b61359a08bc2d961533950dc8943ac3d7f301
        .try_into()
        .unwrap();

    ApproveUnitsTest::approve_units(1_u128, units, operator);
    let data = ApproveUnitsTest::get_approved_units(1_u128);

    assert(data.units == units, 'units should be 10');
    assert(data.operator == operator, 'operator should be address');
}

#[test]
#[available_gas(2000000)]
fn test_approve_units_traits() {
    // test zeroanle
    let data = Zeroable::<ApprovedUnits>::zero();
    assert(data.units == BoundedInt::<u256>::min(), 'units should be 0');
    assert(data.operator == Zeroable::<ContractAddress>::zero(), 'operator should be 0');
    assert(data.is_zero(), 'should be zero');
    assert(!data.is_non_zero(), 'should be zero');

    let units: u256 = 10.into();
    let operator: ContractAddress =
        0x066b6f9b1da6cfdaf09a5456ab8b61359a08bc2d961533950dc8943ac3d7f301
        .try_into()
        .unwrap();

    let data = ApprovedUnitsTrait::new(units, operator);
    let data2 = ApprovedUnitsTrait::new(0.into(), operator);

    assert(data.units == units, 'units should be 10');
    assert(data.operator == operator, 'operator should be address');
    assert(!data.is_zero(), 'should be non zero');
    assert(data.is_non_zero(), 'should be non zero');
    assert(!data2.is_zero(), 'should be non zero');
    assert(data2.is_non_zero(), 'should be non zero');
    assert(data != data2, 'should not be equal');
}
