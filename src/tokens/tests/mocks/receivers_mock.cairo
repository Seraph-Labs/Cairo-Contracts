#[starknet::contract]
mod NonReceiver {
    #[storage]
    struct Storage {}
}

#[starknet::contract]
mod Mock721Receiver {
    use seraphlabs::tokens::src5::src5::SRC5Component::SRC5InternalTrait;
    use starknet::ContractAddress;
    use array::{SpanTrait, SpanSerde};

    use seraphlabs::tokens::constants;
    use seraphlabs::tokens::erc721::interface;
    use seraphlabs::tokens::src5::SRC5Component;
    use SRC5Component::SRC5InternalImpl;

    component!(path: SRC5Component, storage: src5, event: SRC5Event);

    #[abi(embed_v0)]
    impl SRC5 = SRC5Component::SRC5Impl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        src5: SRC5Component::Storage,
    }

    #[event]
    #[derive(Drop, PartialEq, starknet::Event)]
    enum Event {
        SRC5Event: SRC5Component::Event
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.src5.register_interface(constants::IERC721_RECEIVER_ID);
    }

    #[external(v0)]
    impl ReceiverImpl of interface::IERC721Receiver<ContractState> {
        fn on_erc721_received(
            self: @ContractState,
            operator: ContractAddress,
            from: ContractAddress,
            token_id: u256,
            data: Span<felt252>
        ) -> felt252 {
            if *data.at(0) == 'fail' {
                0
            } else {
                constants::IERC721_RECEIVER_ID
            }
        }
    }
}
// #[starknet::contract]
// mod Mock3525Receiver{
//     use starknet::ContractAddress;
//     use array::{ SpanTrait, SpanSerde};

//     use seraphlabs::tokens::src5::SRC5;
//     use seraphlabs::tokens::constants;
//     use seraphlabs::tokens::erc3525::interface;

//     #[storage]
//     struct Storage{}

//     #[generate_trait]
//     #[external(v0)]
//     fn supports_interface(self : @ContractState, interface_id : felt252) -> bool{
//         let unsafe_state = SRC5::unsafe_new_contract_state();
//         SRC5::ISRC5Impl::supports_interface(@unsafe_state, interface_id)
//     }

//     #[external(v0)]
//     impl ReceiverImpl of interface::IERC721Receiver<ContractState>{
//         fn on_erc721_received(self : @ContractState, operator : ContractAddress, from : ContractAddress, token_id : u256, data : Span<felt252>) -> felt252{
//             if *data.at(0) == 'fail' {
//                 0
//             } else {
//                 constants::IERC721_RECEIVER_ID
//             }
//         }
//     }

// }


