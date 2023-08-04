use core::option::OptionTrait;
use seraphlabs::arrays::SeraphArrayTrait;
use array::{ArrayTrait, Array};
use traits::{Into, TryInto, DivRem};
use zeroable::Zeroable;

trait IntergerToAsciiTrait<T, U> {
    fn to_ascii(self: T) -> U;
}

// converts intergers into an array of its individual ascii values
trait IntergerToAsciiArrayTrait<T> {
    fn to_ascii_array(self: T) -> Array<felt252>;
    fn to_inverse_ascii_array(self: T) -> Array<felt252>;
}

// converts intergers into an array of its individual ascii values
// e.g. 123 -> [49, 50, 51]
impl IntergerToAsciiArrayTraitImpl<
    T,
    impl TNumericLiteral: NumericLiteral<T>,
    impl TPartialOrd: PartialOrd<T>,
    impl TDivRem: DivRem<T>,
    impl TInto: Into<T, felt252>,
    impl TryInto: TryInto<felt252, T>,
    impl TTryIntoZero: TryInto<T, NonZero<T>>,
    impl TZeroable: Zeroable<T>,
    impl TDrop: Drop<T>,
    impl TCopy: Copy<T>,
> of IntergerToAsciiArrayTrait<T> {
    fn to_ascii_array(self: T) -> Array<felt252> {
        let mut new_arr = self.to_inverse_ascii_array();
        new_arr.reverse();
        new_arr
    }

    fn to_inverse_ascii_array(self: T) -> Array<felt252> {
        let mut new_arr = ArrayTrait::<felt252>::new();
        if self <= TryInto::<felt252, T>::try_into(9).unwrap() {
            new_arr.append(self.into() + 48);
            return new_arr;
        }

        let mut num = self;
        loop {
            if num <= Zeroable::<T>::zero() {
                break ();
            }
            let (quotient, remainder) = DivRem::div_rem(
                num, TryInto::<felt252, T>::try_into(10).unwrap().try_into().expect('Division by 0')
            );
            new_arr.append(remainder.into() + 48);
            num = quotient;
        };
        new_arr
    }
}

// gneric implementation for small intergers <u128 
// to transform its intergers into a string represented as a single felt252
// e.g. 1000 -> "1000"
impl SmallIntergerToAsciiTraitImpl<
    T,
    impl TNumericLiteral: NumericLiteral<T>,
    impl TPartialOrd: PartialOrd<T>,
    impl TDivRem: DivRem<T>,
    impl TInto: Into<T, felt252>,
    impl TTryInto: TryInto<felt252, T>,
    impl TTryIntoZero: TryInto<T, NonZero<T>>,
    impl TZeroable: Zeroable<T>,
    impl TDrop: Drop<T>,
    impl TCopy: Copy<T>,
> of IntergerToAsciiTrait<T,felt252> {
    fn to_ascii(self: T) -> felt252 {
        if self <= TryInto::<felt252, T>::try_into(9).unwrap() {
            return self.into() + 48;
        }

        let inverse_ascii_arr = self.to_inverse_ascii_array();
        let len = inverse_ascii_arr.len();
        let mut index = 0;
        let mut ascii: felt252 = 0;
        loop {
            if index >= len {
                break ();
            }
            // recursively keep getting the index from the end of the array
            let l_index = len - index - 1;
            ascii = ascii * 256 + *inverse_ascii_arr[l_index];
            index += 1;
        };
        ascii
    }
}

// gneric implementation for big intergers u128 
// to transform its intergers into a string represented as multiple felt252 if there is overflow
// e.g. max_num + 123 -> ["max_num", "123"]
impl BigIntergerToAsciiTraitImpl<
    T,
    impl TNumericLiteral: NumericLiteral<T>,
    impl TPartialOrd: PartialOrd<T>,
    impl TDivRem: DivRem<T>,
    impl TInto: Into<T, felt252>,
    impl TTryInto: TryInto<felt252, T>,
    impl TTryIntoZero: TryInto<T, NonZero<T>>,
    impl TZeroable: Zeroable<T>,
    impl TDrop: Drop<T>,
    impl TCopy: Copy<T>,
> of IntergerToAsciiTrait<T,Array<felt252>> {
    fn to_ascii(self: T) -> Array<felt252> {
        let mut data = ArrayTrait::<felt252>::new();
        if self <= TryInto::<felt252, T>::try_into(9).unwrap() {
            data.append(self.into() + 48);
            return data;
        }

        let inverse_ascii_arr = self.to_inverse_ascii_array();
        let len = inverse_ascii_arr.len();
        let mut index = 0;
        let mut ascii: felt252 = 0;
        loop {
            if index >= len {
                // if ascii is 0 it means we have already appended the first ascii
                // and theres no need to append it again
                match ascii {
                    0 => (),
                    _ => data.append(ascii),
                }
                break ();
            }
            // recursively keep getting the index from the end of the array
            let l_index = len - index - 1;
            let new_ascii = ascii * 256 + *inverse_ascii_arr[l_index];
            // if index is at 30 it means we have reached the max size of felt252 at 31 characters
            // so we append the current ascii and reset the ascii to 0
            ascii = if index == 30 {
                data.append(new_ascii);
                0
            } else {
                new_ascii
            };
            index += 1;
        };
        data
    }
}

// -------------------------------------------------------------------------- //
//                                  for u256                                  //
// -------------------------------------------------------------------------- //
// have to implement seperately for u256 because 
// it dosent have the same implementations as the generic version
impl U256ToAsciiArrayTraitImpl of IntergerToAsciiArrayTrait<u256> {
    fn to_ascii_array(self: u256) -> Array<felt252> {
        let mut new_arr = self.to_inverse_ascii_array();
        new_arr.reverse();
        new_arr
    }

    fn to_inverse_ascii_array(self: u256) -> Array<felt252> {
        let mut new_arr = ArrayTrait::<felt252>::new();
        if self <= 9 {
            new_arr.append(self.try_into().expect('number overflow felt252') + 48);
            return new_arr;
        }
        let mut num = self;
        loop {
            if num <= 0 {
                break ();
            }
            let (quotient, remainder) = DivRem::div_rem(
                num, 10_u256.try_into().expect('Division by 0')
            );
            new_arr.append(remainder.try_into().expect('number overflow felt252') + 48);
            num = quotient;
        };
        new_arr
    }
}

impl U256ToAsciiTraitImpl of IntergerToAsciiTrait<u256, Array<felt252>> {

    fn to_ascii(self: u256) -> Array<felt252> {
        let mut data = ArrayTrait::<felt252>::new();
        if self <= 9 {
            data.append(self.try_into().expect('number overflow felt252') + 48);
            return data;
        }

        let inverse_ascii_arr = self.to_inverse_ascii_array();
        let len = inverse_ascii_arr.len();
        let mut index = 0;
        let mut ascii: felt252 = 0;
        loop {
            if index >= len {
                // if ascii is 0 it means we have already appended the first ascii
                // and theres no need to append it again
                match ascii {
                    0 => (),
                    _ => data.append(ascii),
                }
                break ();
            }
            // recursively keep getting the index from the end of the array
            let l_index = len - index - 1;
            let new_ascii = ascii * 256 + *inverse_ascii_arr[l_index];
            // if index is currently at 30 it means we have processed the number for index 31
            // this means we have reached the max size of felt252 at 31 characters
            // so we append the current ascii and reset the ascii to 0
            // do the same at index 61 as well because max u256 is 78 characters
            ascii = if index == 30 || index == 61 {
                data.append(new_ascii);
                0
            } else {
                new_ascii
            };
            index += 1;
        };
        data
    }
}