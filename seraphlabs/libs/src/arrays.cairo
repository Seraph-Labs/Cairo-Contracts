// ----------------------------- library modules ---------------------------- //

// --------------------------------- imports -------------------------------- //
use array::{Array, ArrayTrait};
use traits::{Into,TryInto};
use core::option::OptionTrait;

trait SeraphArrayTrait<T> {
    fn reverse(ref self : Array<T>);
}

impl ArrayImpl<T, impl TDrop: Drop<T>> of SeraphArrayTrait<T>{
    fn reverse(ref self : Array<T>){
        let cur_arr_len = self.len();
        let mut index = 0;
        loop {
            if index >= cur_arr_len {
                break ();
            }
            // pop the front value out of the array
            let front_val = self.pop_front().unwrap();
            // now append it back to the array
            self.append(front_val);
            index += 1;
        }
    }
}
