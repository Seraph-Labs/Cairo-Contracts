// ----------------------------- library modules ---------------------------- //

// --------------------------------- imports -------------------------------- //
use array::{Array, ArrayTrait, SpanTrait};
use traits::{Into,TryInto};
use option::OptionTrait;


trait SeraphArrayTrait<T> {
    fn reverse(ref self : Array<T>);
}

impl ArrayImpl<T, impl TDrop: Drop<T>, impl TCopy: Copy<T>> of SeraphArrayTrait<T>{
    fn reverse(ref self : Array<T>){
        if self.len() <=1{
            return ();
        }

        let mut span = self.span();
        loop{
            if span.len() <= 0{
                break ();
            }
            //let val = span.pop_back().unwrap();
            self.append(*span.pop_back().unwrap());
            self.pop_front();
        }
    }
}
