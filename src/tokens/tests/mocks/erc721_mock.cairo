use starknet::ContractAddress;
#[starknet::interface]
trait IERC721Mock<TContractState> {
    //src5 
    fn supports_interface(self: @TContractState, interface_id: felt252) -> bool;
    // Metadata functions
    fn name(self: @TContractState) -> felt252;
    fn get_name(self: @TContractState) -> felt252;
    fn symbol(self: @TContractState) -> felt252;
    fn token_uri(self: @TContractState, token_id: u256) -> Array<felt252>;
    fn set_base_uri(ref self: TContractState, base_uri: Array<felt252>);
    // 721 functions
    fn balance_of(self: @TContractState, owner: ContractAddress) -> u256;
    fn owner_of(self: @TContractState, token_id: u256) -> ContractAddress;
    fn get_approved(self: @TContractState, token_id: u256) -> ContractAddress;
    fn is_approved_for_all(
        self: @TContractState, owner: ContractAddress, operator: ContractAddress
    ) -> bool;
    fn approve(ref self: TContractState, approved: ContractAddress, token_id: u256);
    fn set_approval_for_all(ref self: TContractState, operator: ContractAddress, approved: bool);
    fn safe_transfer_from(
        ref self: TContractState,
        from: ContractAddress,
        to: ContractAddress,
        token_id: u256,
        data: Span<felt252>
    );
    fn transfer_from(
        ref self: TContractState, from: ContractAddress, to: ContractAddress, token_id: u256
    );
    fn mint(ref self: TContractState, to: ContractAddress, token_id: u256);
    fn safe_mint(
        ref self: TContractState, to: ContractAddress, token_id: u256, data: Span<felt252>
    );
    fn burn(ref self: TContractState, token_id: u256);
}

#[starknet::contract]
mod ERC721Mock {
    use seraphlabs::tokens::erc721::{ERC721Component, extensions::ERC721MetadataComponent};
    use seraphlabs::tokens::src5::SRC5Component;
    use super::ContractAddress;
    use ERC721Component::{ERC721InternalImpl, ERC721InitializerImpl};
    use ERC721MetadataComponent::{
        IERC721MetadataImpl, ERC721MetadataInternalImpl, ERC721MetadataInitializerImpl
    };
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: ERC721MetadataComponent, storage: erc721_metadata, event: ERC721MetadataEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);

    #[abi(embed_v0)]
    impl SRC5 = SRC5Component::SRC5Impl<ContractState>;

    #[abi(embed_v0)]
    impl ERC721 = ERC721Component::ERC721Impl<ContractState>;

    #[abi(embed_v0)]
    impl ERC721Metadata =
        ERC721MetadataComponent::ERC721MetadataImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        erc721_metadata: ERC721MetadataComponent::Storage,
    }

    #[event]
    #[derive(Drop, PartialEq, starknet::Event)]
    enum Event {
        SRC5Event: SRC5Component::Event,
        ERC721Event: ERC721Component::Event,
        ERC721MetadataEvent: ERC721MetadataComponent::Event
    }

    #[constructor]
    fn constructor(ref self: ContractState, name: felt252, symbol: felt252) {
        self.erc721.initializer();
        self.erc721_metadata.initializer(name, symbol);
    }

    #[generate_trait]
    #[external(v0)]
    impl MetadataImpl of MetadataTrait {
        fn set_base_uri(ref self: ContractState, base_uri: Array<felt252>) {
            self.erc721_metadata._set_base_uri(base_uri);
        }
    }

    #[generate_trait]
    #[external(v0)]
    impl Base721Impl of Base721Trait {
        // fn name(self: @ContractState) -> felt252 {
        //     self.erc721_metadata.name()
        // }

        // fn symbol(self: @ContractState) -> felt252 {
        //     self.erc721_metadata.symbol()
        // }

        // fn token_uri(self: @ContractState, token_id: u256) -> Array<felt252> {
        //     self.erc721_metadata.token_uri(token_id)
        // }

        fn mint(ref self: ContractState, to: ContractAddress, token_id: u256) {
            self.erc721._mint(to, token_id);
        }

        fn safe_mint(
            ref self: ContractState, to: ContractAddress, token_id: u256, data: Span<felt252>
        ) {
            self.erc721._safe_mint(to, token_id, data);
        }

        fn burn(ref self: ContractState, token_id: u256) {
            self.erc721._burn(token_id);
        }
    }
}
