use starknet::ContractAddress;

#[starknet::interface]
trait IERC3525Mock<TContractState> {
    //src5 
    fn supports_interface(self: @TContractState, interface_id: felt252) -> bool;
    // 721 functions
    fn balance_of(self: @TContractState, owner: ContractAddress) -> u256;
    fn owner_of(self: @TContractState, token_id: u256) -> ContractAddress;
    fn set_approval_for_all(ref self: TContractState, operator: ContractAddress, approved: bool);
    // 721 enum functions
    fn token_of_owner_by_index(self: @TContractState, owner: ContractAddress, index: u256) -> u256;
    // has clear unit level approvals
    fn transfer_from(
        ref self: TContractState, from: ContractAddress, to: ContractAddress, token_id: u256
    );
    // erc3525 functions 
    fn value_decimals(self: @TContractState) -> u8;
    fn value_of(self: @TContractState, token_id: u256) -> u256;
    fn slot_of(self: @TContractState, token_id: u256) -> u256;
    fn approve_value(
        ref self: TContractState, token_id: u256, operator: ContractAddress, value: u256
    );
    fn allowance(self: @TContractState, token_id: u256, operator: ContractAddress) -> u256;
    fn transfer_value_from(
        ref self: TContractState, from_token_id: u256, to: ContractAddress, value: u256
    ) -> u256;
    fn mint(
        ref self: TContractState, to: ContractAddress, token_id: u256, slot_id: u256, value: u256
    );
}

#[starknet::contract]
mod ERC3525Mock {
    use seraphlabs::tokens::erc3525::erc3525::ERC3525Component::ERC3525InternalTrait;
    use super::ContractAddress;
    use seraphlabs::tokens::erc721::{ERC721Component, extensions::ERC721EnumComponent};
    use seraphlabs::tokens::src5::SRC5Component;
    use seraphlabs::tokens::erc3525::ERC3525Component;
    use ERC721Component::{IERC721Impl, ERC721InitializerImpl};
    use ERC721EnumComponent::{IERC721EnumImpl, ERC721EnumInitializerImpl, ERC721EnumInternalImpl};
    use ERC3525Component::{ERC3525InitializerImpl, ERC3525InternalImpl};

    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: ERC3525Component, storage: erc3525, event: ERC3525Event);
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: ERC721EnumComponent, storage: erc721_enum, event: ERC721EnumEvent);

    #[abi(embed_v0)]
    impl SRC5 = SRC5Component::SRC5Impl<ContractState>;

    #[abi(embed_v0)]
    impl ERC3525 = ERC3525Component::ERC3525Impl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        erc3525: ERC3525Component::Storage,
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        erc721_enum: ERC721EnumComponent::Storage,
    }

    #[event]
    #[derive(Drop, PartialEq, starknet::Event)]
    enum Event {
        SRC5Event: SRC5Component::Event,
        ERC3525Event: ERC3525Component::Event,
        ERC721Event: ERC721Component::Event,
        ERC721EnumEvent: ERC721EnumComponent::Event,
    }

    #[constructor]
    fn constructor(ref self: ContractState, value_decimals: u8) {
        self.erc721.initializer();
        self.erc721_enum.initializer();
        self.erc3525.initializer(value_decimals);
    }

    #[generate_trait]
    #[external(v0)]
    impl Base721Impl of Base721Trait {
        fn balance_of(self: @ContractState, owner: ContractAddress) -> u256 {
            self.erc721.balance_of(owner)
        }

        fn owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            self.erc721.owner_of(token_id)
        }

        fn set_approval_for_all(
            ref self: ContractState, operator: ContractAddress, approved: bool
        ) {
            self.erc721.set_approval_for_all(operator, approved);
        }
    }

    #[generate_trait]
    #[external(v0)]
    impl Base721EnumImpl of Base721EnumTrait {
        fn token_of_owner_by_index(
            self: @ContractState, owner: ContractAddress, index: u256
        ) -> u256 {
            self.erc721_enum.token_of_owner_by_index(owner, index)
        }

        fn transfer_from(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            self.erc3525._clear_value_approvals(token_id);
            self.erc721_enum.transfer_from(from, to, token_id);
        }
    }

    #[generate_trait]
    #[external(v0)]
    impl Base3525impl of Base3525Trait {
        fn mint(
            ref self: ContractState, to: ContractAddress, token_id: u256, slot_id: u256, value: u256
        ) {
            self.erc3525._mint(to, token_id, slot_id, value);
        }
    }
}
