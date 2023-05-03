use seraphlabs_utils::arrays::ArrayReverseTrait;
use array::ArrayTrait;
use traits::{Into, TryInto};
use integer::{u128_safe_divmod, u64_safe_divmod, u32_safe_divmod, u16_safe_divmod, u8_safe_divmod, u128_as_non_zero, u64_as_non_zero, u32_as_non_zero, u16_as_non_zero, u8_as_non_zero};
use zeroable::Zeroable;
use core::option::OptionTrait;

trait IntergerToAsciiTrait<T>{
    fn to_ascii(self : T) -> Array<felt252>;
}

impl U128ToAsciiTraitImpl of IntergerToAsciiTrait<u128>{
    fn to_ascii(self : u128) -> Array<felt252>{
        let mut new_arr = ArrayTrait::<felt252>::new();
        if self <= 9{
            new_arr.append(self.into() + 48);
            return new_arr;
        }
        let mut num = self;
        loop{
            if num <= 0{
                break ();
            }
           
            let (quotient, remainder) = u128_safe_divmod(num, u128_as_non_zero(10));
            new_arr.append(remainder.into() + 48);
            num = quotient;
        };
        
        new_arr
    }
}

impl U64ToAsciiTraitImpl of IntergerToAsciiTrait<u64>{
    fn to_ascii(self : u64) -> Array<felt252>{
        let mut new_arr = ArrayTrait::<felt252>::new();
        if self <= 9{
            new_arr.append(self.into() + 48);
            return new_arr;
        }
        let mut num = self;
        loop{
            if num <= 0{
                break ();
            }
           
            let (quotient, remainder) = u64_safe_divmod(num, u64_as_non_zero(10));
            new_arr.append(remainder.into() + 48);
            num = quotient;
        };
        
        new_arr
    }
}

impl U32ToAsciiTraitImpl of IntergerToAsciiTrait<u32>{
    fn to_ascii(self : u32) -> Array<felt252>{
        let mut new_arr = ArrayTrait::<felt252>::new();
        if self <= 9{
            new_arr.append(self.into() + 48);
            return new_arr;
        }
        let mut num = self;
        loop{
            if num <= 0{
                break ();
            }
           
            let (quotient, remainder) = u32_safe_divmod(num, u32_as_non_zero(10));
            new_arr.append(remainder.into() + 48);
            num = quotient;
        };
        
        new_arr
    }
}

impl U16ToAsciiTraitImpl of IntergerToAsciiTrait<u16>{
    fn to_ascii(self : u16) -> Array<felt252>{
        let mut new_arr = ArrayTrait::<felt252>::new();
        if self <= 9{
            new_arr.append(self.into() + 48);
            return new_arr;
        }
        let mut num = self;
        loop{
            if num <= 0{
                break ();
            }
           
            let (quotient, remainder) = u16_safe_divmod(num, u16_as_non_zero(10));
            new_arr.append(remainder.into() + 48);
            num = quotient;
        };
        
        new_arr
    }
}

impl U8ToAsciiTraitImpl of IntergerToAsciiTrait<u8>{
    fn to_ascii(self : u8) -> Array<felt252>{
        let mut new_arr = ArrayTrait::<felt252>::new();
        if self <= 9{
            new_arr.append(self.into() + 48);
            return new_arr;
        }
        let mut num = self;
        loop{
            if num <= 0{
                break ();
            }
           
            let (quotient, remainder) = u8_safe_divmod(num, u8_as_non_zero(10));
            new_arr.append(remainder.into() + 48);
            num = quotient;
        };
        
        new_arr
    }
}