use array::ArrayTrait;
use traits::{Into, TryInto};
use seraphlabs_libs::ascii::IntergerToAsciiTrait;

#[test]
#[available_gas(2000000)]
fn u128_to_ascii(){
    let num : u128 = 123456789012345678901234567890;
    let ascii = num.to_ascii();
    assert (ascii == '123456789012345678901234567890', 'incorect felt');
}

#[test]
#[available_gas(2000000)]
fn u64_to_ascii(){
    let num : u64 = 12345678901234567890;
    let ascii = num.to_ascii();
    assert (ascii == '12345678901234567890', 'incorect felt');
}

#[test]
#[available_gas(2000000)]
fn u32_to_ascii(){
    let num : u32 = 1234567890;
    let ascii = num.to_ascii();
    assert (ascii == '1234567890', 'incorect felt');
}

#[test]
#[available_gas(2000000)]
fn u16_to_ascii(){
    let num : u16 = 12345;
    let ascii = num.to_ascii();
    assert (ascii == '12345', 'incorect felt');
}

#[test]
#[available_gas(2000000)]
fn u8_to_ascii(){
    let num : u8 = 123;
    let ascii = num.to_ascii();
    assert (ascii == '123', 'incorect felt');
}