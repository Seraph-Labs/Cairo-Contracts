#[contract]
mod NonReceiver {}

#[contract]
mod ERC3525Receiver {
    use starknet::ContractAddress;
    use array::SpanTrait;

    use seraphlabs_utils::serde::SpanSerde;
    use seraphlabs_tokens::erc3525::interface::IERC3525Receiver;
    use seraphlabs_tokens::utils::{constants, erc165::ERC165};

    impl ERC3525Receiver of IERC3525Receiver {
        fn on_erc3525_received(
            operator: ContractAddress,
            from_token_id: u256,
            to_token_id: u256,
            value: u256,
            data: Span<felt252>
        ) -> u32 {
            constants::IERC3525_RECEIVER_ID
        }
    }

    #[constructor]
    fn constructor() {
        ERC165::register_interface(constants::IERC3525_RECEIVER_ID);
    }

    #[view]
    fn supports_interface(interface_id: u32) -> bool {
        ERC165::supports_interface(interface_id)
    }

    #[external]
    fn on_erc3525_received(
        operator: ContractAddress,
        from_token_id: u256,
        to_token_id: u256,
        value: u256,
        data: Span<felt252>
    ) -> u32 {
        ERC3525Receiver::on_erc3525_received(operator, from_token_id, to_token_id, value, data)
    }
}

#[contract]
mod ERC721Receiver {
    use starknet::ContractAddress;
    use array::SpanTrait;

    use seraphlabs_utils::serde::SpanSerde;
    use seraphlabs_tokens::erc721::interface::IERC721Receiver;
    use seraphlabs_tokens::utils::{constants, erc165::ERC165};

    impl ERC721Receiver of IERC721Receiver {
        fn on_erc721_received(
            operator: ContractAddress, from: ContractAddress, token_id: u256, data: Span<felt252>
        ) -> u32 {
            if *data.at(0) == 'fail' {
                0
            } else {
                constants::IERC721_RECEIVER_ID
            }
        }
    }
    #[constructor]
    fn constructor() {
        ERC165::register_interface(constants::IERC721_RECEIVER_ID);
    }

    #[view]
    fn supports_interface(interface_id: u32) -> bool {
        ERC165::supports_interface(interface_id)
    }

    #[external]
    fn on_erc721_received(
        operator: ContractAddress, from: ContractAddress, token_id: u256, data: Span<felt252>
    ) -> u32 {
        ERC721Receiver::on_erc721_received(operator, from, token_id, data)
    }
}
