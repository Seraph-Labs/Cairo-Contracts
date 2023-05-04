use seraphlabs_libs::arrays::SeraphArrayTrait;
use array::ArrayTrait;
use traits::{Into, TryInto};
use integer::{u128_safe_divmod, u64_safe_divmod, u32_safe_divmod, u16_safe_divmod, u8_safe_divmod, u128_as_non_zero, u64_as_non_zero, u32_as_non_zero, u16_as_non_zero, u8_as_non_zero};
use zeroable::Zeroable;

trait IntergerToAsciiTrait<T>{
    fn to_ascii_array(self : T) -> Array<felt252>;
    fn to_inverse_ascii_array(self : T) -> Array<felt252>;
    fn to_ascii(self : T) -> felt252;
}

impl U128ToAsciiTraitImpl of IntergerToAsciiTrait<u128>{
    fn to_ascii_array(self : u128) -> Array<felt252>{
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
        new_arr.reverse();
        new_arr
    }

    fn to_inverse_ascii_array(self : u128) -> Array<felt252>{
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

    fn to_ascii(self : u128) -> felt252{
        if self <= 9{
            return self.into() + 48;
        }

        let inverse_ascii_arr = self.to_inverse_ascii_array();
        let len = inverse_ascii_arr.len();
        let mut index = 0;
        let mut ascii : felt252 = 0;
        loop{
            if index >= len{
                break ();
            }
            // recursively keep getting the index from the end of the array
            let l_index = len - index - 1;
            ascii = ascii * 256 + *inverse_ascii_arr[l_index];
            index +=1;
        };
        ascii
    }
}

impl U64ToAsciiTraitImpl of IntergerToAsciiTrait<u64>{
    fn to_ascii_array(self : u64) -> Array<felt252>{
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
        
        new_arr.reverse();
        new_arr
    }

    fn to_inverse_ascii_array(self : u64) -> Array<felt252>{
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

    fn to_ascii(self : u64) -> felt252{
        if self <= 9{
            return self.into() + 48;
        }

        let inverse_ascii_arr = self.to_inverse_ascii_array();
        let len = inverse_ascii_arr.len();
        let mut index = 0;
        let mut ascii : felt252 = 0;
        loop{
            if index >= len{
                break ();
            }
            // recursively keep getting the index from the end of the array
            let l_index = len - index - 1;
            ascii = ascii * 256 + *inverse_ascii_arr[l_index];
            index +=1;
        };
        ascii
    }
}

impl U32ToAsciiTraitImpl of IntergerToAsciiTrait<u32>{

    fn to_ascii_array(self : u32) -> Array<felt252>{
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
        new_arr.reverse();
        new_arr
    }

    fn to_inverse_ascii_array(self : u32) -> Array<felt252>{
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

    fn to_ascii(self : u32) -> felt252{
        if self <= 9{
            return self.into() + 48;
        }

        let inverse_ascii_arr = self.to_inverse_ascii_array();
        let len = inverse_ascii_arr.len();
        let mut index = 0;
        let mut ascii : felt252 = 0;
        loop{
            if index >= len{
                break ();
            }
            // recursively keep getting the index from the end of the array
            let l_index = len - index - 1;
            ascii = ascii * 256 + *inverse_ascii_arr[l_index];
            index +=1;
        };
        ascii
    }
}

impl U16ToAsciiTraitImpl of IntergerToAsciiTrait<u16>{

    fn to_ascii_array(self : u16) -> Array<felt252>{
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
        new_arr.reverse();
        new_arr
    }

    fn to_inverse_ascii_array(self : u16) -> Array<felt252>{
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

    fn to_ascii(self : u16) -> felt252{
        if self <= 9{
            return self.into() + 48;
        }

        let inverse_ascii_arr = self.to_inverse_ascii_array();
        let len = inverse_ascii_arr.len();
        let mut index = 0;
        let mut ascii : felt252 = 0;
        loop{
            if index >= len{
                break ();
            }
            // recursively keep getting the index from the end of the array
            let l_index = len - index - 1;
            ascii = ascii * 256 + *inverse_ascii_arr[l_index];
            index +=1;
        };
        ascii
    }
}

impl U8ToAsciiTraitImpl of IntergerToAsciiTrait<u8>{
    fn to_ascii_array(self : u8) -> Array<felt252>{
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
        new_arr.reverse();
        new_arr
    }

    fn to_inverse_ascii_array(self : u8) -> Array<felt252>{
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

    fn to_ascii(self : u8) -> felt252{
        if self <= 9{
            return self.into() + 48;
        }

        let inverse_ascii_arr = self.to_inverse_ascii_array();
        let len = inverse_ascii_arr.len();
        let mut index = 0;
        let mut ascii : felt252 = 0;
        loop{
            if index >= len{
                break ();
            }
            // recursively keep getting the index from the end of the array
            let l_index = len - index - 1;
            ascii = ascii * 256 + *inverse_ascii_arr[l_index];
            index +=1;
        };
        ascii
    }
}