// ----------------------------- library modules ---------------------------- //

// --------------------------------- imports -------------------------------- //
use array::{Array, ArrayTrait, SpanTrait};
use traits::{Into,TryInto};
use option::OptionTrait;


trait SeraphArrayTrait<T> {
    fn reverse(ref self : Array<T>);
    fn concat(ref self : Array<T>, ref arr : Array<T>);
}

impl ArrayImpl<T, impl TDrop: Drop<T>, impl TCopy: Copy<T>> of SeraphArrayTrait<T>{
    fn reverse(ref self : Array<T>){
        if self.len() <=1{
            return ();
        }
        // create Span so we can pop_back value
        let mut span = self.span();
        loop{
            if span.len() <= 0{
                break ();
            }
            // add last value of span to array
            self.append(*span.pop_back().unwrap());
            // pop out arrays first value;
            self.pop_front();
        }
    }

    fn concat(ref self : Array<T>, ref arr : Array<T>){
        loop{
            match arr.pop_front(){
                Option::Some(val) => self.append(val),
                Option::None(()) => {break ();},
            };
        }
    }
}
