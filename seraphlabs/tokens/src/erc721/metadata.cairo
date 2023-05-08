#[contract]
mod ERC721Metadata{
    use seraphlabs_libs::{ascii::IntergerToAsciiTrait, SeraphArrayTrait};
    use seraphlabs_tokens::erc721::interface;    
    // corelib imports
    use array::ArrayTrait;
    use option::OptionTrait;
    use traits::{Into, TryInto};
    use zeroable::Zeroable;

    // -------------------------------------------------------------------------- //
    //                                   Storage                                  //
    // -------------------------------------------------------------------------- //
    struct Storage{
        _name : felt252,
        _symbol : felt252,
        _base_uri : LegacyMap::<felt252, felt252>,
        _base_uri_len : felt252,
    }
    // -------------------------------------------------------------------------- //
    //                                    Trait                                   //
    // -------------------------------------------------------------------------- //
    impl ERC721Metadata of interface::IERC721MetaData{
        fn name() -> felt252{
            _name::read()
        }

        fn symbol() -> felt252{
            _symbol::read()
        }

        fn token_uri(token_id : u256) -> Array::<felt252>{
            // get_base_uri
            let mut base_uri = _get_base_uri();
            // get token_id low ascii value
            // TODO : covert entire u256 instead of just u128
            let mut ascii = token_id.low.to_ascii();
            // append it to base_uri array along with suffix
            base_uri.concat(ref ascii);
            base_uri.append('.json');
            base_uri
        }
    }

    // -------------------------------------------------------------------------- //
    //                               view functions                               //
    // -------------------------------------------------------------------------- //
    #[view]
    fn name() -> felt252{
        ERC721Metadata::name()
    }

    #[view]
    fn symbol() -> felt252{
        ERC721Metadata::symbol()
    }

    #[view]
    fn token_uri(token_id: u256) -> Array::<felt252>{
        ERC721Metadata::token_uri(token_id)
    }
    // -------------------------------------------------------------------------- //
    //                                  Externals                                 //
    // -------------------------------------------------------------------------- //
    fn initializer(name : felt252, symbol : felt252){
        _name::write(name);
        _symbol::write(symbol);
    }
    
    fn set_base_uri(mut base_uri : Array::<felt252>){
        let len = base_uri.len();
        let mut index = 0;
        loop{
            match base_uri.pop_front(){
                Option::Some(value) => {
                    _base_uri::write(index,value);
                    index += 1;
                },
                Option::None(()) => {break ();},
            };
        };
        // write length to storage
        _base_uri_len::write(len.into());
    }

    // -------------------------------------------------------------------------- //
    //                                  Internals                                 //
    // -------------------------------------------------------------------------- //
    fn _get_base_uri() -> Array::<felt252>{
        let len = _base_uri_len::read();
        let mut base_uri = ArrayTrait::<felt252>::new();
        let mut index = 0;
        loop{
            if index == len{
                break ();
            }
            base_uri.append(_base_uri::read(index));
            index += 1;
        };
        base_uri
    }
}