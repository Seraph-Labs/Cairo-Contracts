use seraphlabs::math::power::{pow2, pow};
use traits::{Into, TryInto};
use option::OptionTrait;
use integer::BoundedInt;
use debug::{print, PrintTrait};


#[test]
#[available_gas(200000000)]
fn pow_2_test() {
    assert(pow2(BoundedInt::min()) == 1, 'pow 2 failed');
    assert(pow2(8) == BoundedInt::<u8>::max().into() + 1, 'pow 2 u8 failed');
    assert(pow2(16) == BoundedInt::<u16>::max().into() + 1, 'pow 2 u16 failed');
    assert(pow2(32) == BoundedInt::<u32>::max().into() + 1, 'pow 2 u32 failed');
    assert(pow2(64) == BoundedInt::<u64>::max().into() + 1, 'pow 2 u64 failed');
    assert(pow2(128) == BoundedInt::<u128>::max().into() + 1, 'pow 2 u128 failed');
    let max_255_bits =
        57896044618658097711785492504343953926634992332820282019728792003956564819968_u256;
    assert(pow2(BoundedInt::max()) == max_255_bits, 'pow 2 u255 failed');
}

#[test]
#[available_gas(200000000)]
fn pow_test() {
    assert(pow(2, BoundedInt::min()) == 1, 'pow 2 failed');
    assert(pow(2, 8) == BoundedInt::<u8>::max().into() + 1, 'pow u8 failed');
    assert(pow(4, 8) == BoundedInt::<u16>::max().into() + 1, 'pow u16 failed');
    assert(pow(16, 8) == BoundedInt::<u32>::max().into() + 1, 'pow u32 failed');
    assert(pow(16, 16) == BoundedInt::<u64>::max().into() + 1, 'pow u64 failed');
    assert(pow(2, 128) == BoundedInt::<u128>::max().into() + 1, 'pow u128 failed');
    let max_255_bits =
        57896044618658097711785492504343953926634992332820282019728792003956564819968_u256;
    assert(pow(2, BoundedInt::max()) == max_255_bits, 'pow u255 failed');
}
