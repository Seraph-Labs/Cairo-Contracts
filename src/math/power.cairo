use traits::{Into, TryInto};
use integer::u256_overflow_mul;
use zeroable::Zeroable;

fn pow2(mut power: u8) -> u256 {
    let mut result = 1_u256;
    let mut base = 2_u256;

    let res = loop {
        if power == 0 {
            break result;
        }

        if power % 2 == 1 {
            let (new_result, _) = u256_overflow_mul(result, base);
            result = new_result;
        }

        let (new_base, _) = u256_overflow_mul(base, base);
        base = new_base;
        power /= 2;
    };
    res
}


fn pow(base: u8, mut power: u8) -> u256 {
    if base.is_zero() {
        panic_with_felt252('base cannot be zero');
    }

    let mut result = 1_u256;
    let mut base: u256 = base.into();

    let res = loop {
        if power == 0 {
            break result;
        }

        if power % 2 == 1 {
            let (new_result, _) = u256_overflow_mul(result, base);
            result = new_result;
        }

        let (new_base, _) = u256_overflow_mul(base, base);
        base = new_base;
        power /= 2;
    };
    res
}
