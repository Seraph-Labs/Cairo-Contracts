#[starknet::contract]
mod NonReceiver {
    #[storage]
    struct Storage {}
}

#[starknet::contract]
mod Mock721Receiver {
    use starknet::ContractAddress;
    use array::{SpanTrait, SpanSerde};

    use seraphlabs::tokens::src5::SRC5;
    use seraphlabs::tokens::constants;
    use seraphlabs::tokens::erc721::interface;

    #[storage]
    struct Storage {}

    #[constructor]
    fn constructor(ref self: ContractState) {
        let mut unsafe_state = SRC5::unsafe_new_contract_state();
        SRC5::InternalImpl::register_interface(ref unsafe_state, constants::IERC721_RECEIVER_ID);
    }

    #[external(v0)]
    fn supports_interface(self: @ContractState, interface_id: felt252) -> bool {
        let unsafe_state = SRC5::unsafe_new_contract_state();
        SRC5::ISRC5Impl::supports_interface(@unsafe_state, interface_id)
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


