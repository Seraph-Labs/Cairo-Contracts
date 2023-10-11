use starknet::ContractAddress;
use seraphlabs::tokens::constants;
use seraphlabs::tokens::src5::SRC5Component;

#[starknet::contract]
mod NonReceiver {
    #[storage]
    struct Storage {}
}

#[starknet::contract]
mod Mock721Receiver {
    use seraphlabs::tokens::erc721::interface;
    use super::ContractAddress;
    use super::constants;
    use super::SRC5Component;
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
    impl ERC721ReceiverImpl of interface::IERC721Receiver<ContractState> {
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

#[starknet::contract]
mod Mock3525Receiver {
    use seraphlabs::tokens::erc3525::interface;
    use super::ContractAddress;
    use super::constants;
    use super::SRC5Component;
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
        self.src5.register_interface(constants::IERC3525_RECEIVER_ID);
    }

    #[external(v0)]
    impl ERC3525ReceiverImpl of interface::IERC3525Receiver<ContractState> {
        fn on_erc3525_received(
            self: @ContractState,
            operator: ContractAddress,
            from_token_id: u256,
            to_token_id: u256,
            value: u256,
            data: Span<felt252>
        ) -> felt252 {
            constants::IERC3525_RECEIVER_ID
        }
    }
}

#[starknet::contract]
mod Mock3525InvalidReceiver {
    use seraphlabs::tokens::erc3525::interface;
    use super::ContractAddress;
    use super::constants;
    use super::SRC5Component;
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
        self.src5.register_interface(constants::IERC3525_RECEIVER_ID);
    }

    #[external(v0)]
    impl ERC3525ReceiverImpl of interface::IERC3525Receiver<ContractState> {
        fn on_erc3525_received(
            self: @ContractState,
            operator: ContractAddress,
            from_token_id: u256,
            to_token_id: u256,
            value: u256,
            data: Span<felt252>
        ) -> felt252 {
            constants::IERC3525_ID
        }
    }
}
