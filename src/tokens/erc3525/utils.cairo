use starknet::{
    Store, StorageBaseAddress, SyscallResult, storage_read_syscall,
    storage_base_address_from_felt252, storage_write_syscall, storage_address_from_base_and_offset
};
use starknet::{ContractAddress, contract_address::ContractAddressIntoFelt252};
use integer::BoundedInt;

// -------------------------------------------------------------------------- //
//                             ApproveUnitsStruct                             //
// -------------------------------------------------------------------------- //
// used to store operator and approved units of tokenId

#[derive(Copy, Drop, Serde, PartialEq, starknet::Store)]
struct ApprovedUnits {
    units: u256,
    operator: ContractAddress,
}

trait ApprovedUnitsTrait {
    fn new(units: u256, operator: ContractAddress) -> ApprovedUnits;
    fn spend_units(ref self: ApprovedUnits, value: u256);
}

impl ApprovedUnitsImpl of ApprovedUnitsTrait {
    #[inline(always)]
    fn new(units: u256, operator: ContractAddress) -> ApprovedUnits {
        ApprovedUnits { units: units, operator: operator }
    }

    #[inline(always)]
    fn spend_units(ref self: ApprovedUnits, value: u256) {
        if self.units < value {
            panic_with_felt252('ERC3525: Insufficient allowance');
        }

        self.units -= value;
    }
}

// impl StorageAccessApprovedUniits of StorageAccess<ApprovedUnits> {
//     #[inline(always)]
//     fn read(address_domain: u32, base: StorageBaseAddress) -> SyscallResult<ApprovedUnits> {
//         let units = StorageAccess::<u256>::read(address_domain, base)?;
//         let operator_base = storage_base_address_from_felt252(
//             storage_address_from_base_and_offset(base, 2_u8).into()
//         );
//         let operator = StorageAccess::<ContractAddress>::read(address_domain, operator_base)?;
//         Result::Ok(ApprovedUnits { units: units, operator: operator })
//     }

//     #[inline(always)]
//     fn write(
//         address_domain: u32, base: StorageBaseAddress, value: ApprovedUnits
//     ) -> SyscallResult<()> {
//         StorageAccess::<u256>::write(address_domain, base, value.units)?;
//         let operator_base = storage_base_address_from_felt252(
//             storage_address_from_base_and_offset(base, 2_u8).into()
//         );
//         StorageAccess::write(address_domain, operator_base, value.operator)
//     }
// }

impl ApprovedUnitsZeroable of Zeroable<ApprovedUnits> {
    #[inline(always)]
    fn zero() -> ApprovedUnits {
        ApprovedUnits { units: BoundedInt::min(), operator: Zeroable::zero() }
    }

    #[inline(always)]
    fn is_zero(self: ApprovedUnits) -> bool {
        self == ApprovedUnits { units: BoundedInt::min(), operator: Zeroable::zero() }
    }

    #[inline(always)]
    fn is_non_zero(self: ApprovedUnits) -> bool {
        self != ApprovedUnits { units: BoundedInt::min(), operator: Zeroable::zero() }
    }
}

// -------------------------------------------------------------------------- //
//                               Operator Index                               //
// -------------------------------------------------------------------------- //
// used to store index of unit level operator to tokendId
// New means index for a new operator - i.e operator previously does not exist
// Old means index for an old operator - i.e operator previously exists
enum OperatorIndex<T> {
    Contain: T,
    Empty: T
}

trait OperatorIndexTrait<T> {
    fn unwrap(self: OperatorIndex<T>) -> T;
    fn expect_contains(self: OperatorIndex<T>, err: felt252) -> T;
    fn is_empty(self: @OperatorIndex<T>) -> bool;
}

impl OperatorIndexTraitImpl<T, impl TDrop: Drop<T>, impl TCopy: Copy<T>> of OperatorIndexTrait<T> {
    #[inline(always)]
    fn unwrap(self: OperatorIndex<T>) -> T {
        match self {
            OperatorIndex::Contain(x) => x,
            OperatorIndex::Empty(x) => x,
        }
    }

    #[inline(always)]
    fn expect_contains(self: OperatorIndex<T>, err: felt252) -> T {
        match self {
            OperatorIndex::Contain(x) => x,
            OperatorIndex::Empty(_) => panic_with_felt252(err),
        }
    }

    #[inline(always)]
    fn is_empty(self: @OperatorIndex<T>) -> bool {
        match self {
            OperatorIndex::Contain(_) => false,
            OperatorIndex::Empty(_) => true,
        }
    }
}
// Impls for generic types.
impl OperatorIndexCopy<T, impl TCopy: Copy<T>> of Copy<OperatorIndex<T>>;
impl OperatorIndexDrop<T, impl TDrop: Drop<T>> of Drop<OperatorIndex<T>>;
