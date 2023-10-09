use array::{ArrayTrait, SpanTrait};
use traits::{Into, TryInto};
use option::OptionTrait;


#[generate_trait]
impl ArrayImpl<T, impl TDrop: Drop<T>, impl TCopy: Copy<T>> of SeraphArrayTrait<T> {
    fn reverse(ref self: Array<T>) {
        if self.len() <= 1 {
            return ();
        }
        // create Span so we can pop_back value
        let mut span = self.span();
        loop {
            match span.pop_back() {
                Option::Some(val) => {
                    // add last value of span to array
                    self.append(*val);
                    // pop out arrays first value;
                    self.pop_front();
                },
                Option::None(()) => { break; },
            };
        }
    }

    fn append_array(ref self: Array<T>, ref values: Array<T>) {
        loop {
            match values.pop_front() {
                Option::Some(val) => self.append(val),
                Option::None(()) => { break (); },
            };
        }
    }

    fn append_span(ref self: Array<T>, ref values: Span<T>) {
        loop {
            match values.pop_front() {
                Option::Some(val) => self.append(*val),
                Option::None(()) => { break (); },
            };
        }
    }
}

#[generate_trait]
impl SpanImpl<T, impl TDrop: Drop<T>, impl TCopy: Copy<T>> of SeraphSpanTrait<T> {
    fn contains<impl TPartialEq: PartialEq<T>>(mut self: Span<T>, value: T) -> bool {
        loop {
            match self.pop_front() {
                Option::Some(item) => { if *item == value {
                    break true;
                } },
                Option::None(()) => { break false; },
            };
        }
    }
}
